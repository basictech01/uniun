import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/gana_run_status.dart';
import 'package:uniun/core/enum/gana_trigger_mode.dart';
import 'package:uniun/data/models/gana_model.dart';
import 'package:uniun/data/models/gana_run_model.dart';
import 'package:uniun/data/models/manas_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/domain/entities/gana/gana_entity.dart';
import 'package:uniun/features/mesh/sync/bodies/gana_body.dart';
import 'package:uniun/features/mesh/sync/mesh_event_codec.dart';
import 'package:uniun/features/shiv/gana/engine/gana_input_filter.dart';
import 'package:uniun/features/shiv/gana/engine/gana_prompt_builder.dart';
import 'package:uniun/features/shiv/generation/context/manas_context_loader.dart';

/// Isolate-agnostic Gana run logic shared by the foreground [GanaEngine] and
/// the background WorkManager dispatcher (`gana_workmanager.dart`).
///
/// Only the parts that are IDENTICAL between the two live here — the
/// input→ancestry→prompt preamble, the self-loop guard, the NOOP check, the
/// run log, and the cursor advance — so they can't drift between foreground and
/// background. The three steps that genuinely differ stay in each caller:
///   • knowledge ranking — relevance (fg) vs newest-first (bg);
///   • inference — [AIModelRunner.generateOneShot] (fg) vs raw flutter_gemma
///     with a wall-clock budget (bg);
///   • publishing — publish use cases (fg) vs in-isolate signing (bg).

/// Prompt + the inputs/ancestry it was built from, for one run.
class GanaPreparedRun {
  const GanaPreparedRun({
    required this.inputs,
    required this.ancestry,
    required this.manasNames,
    required this.prompt,
  });

  final List<NoteModel> inputs;
  final Map<String, List<NoteModel>> ancestry;
  final List<String> manasNames;
  final String prompt;
}

/// Set of eventIds this Gana has already published — the self-loop guard.
Future<Set<String>> ganaSelfOutputs(Isar isar, String ganaId) async {
  final ids = await isar.ganaRunModels
      .filter()
      .ganaIdEqualTo(ganaId)
      .outputEventIdIsNotNull()
      .outputEventIdProperty()
      .findAll();
  return ids.cast<String>().toSet();
}

/// Resolve manas display names, skipping manases that no longer exist
/// (including tombstoned rows — a deleted Manas should not surface its name
/// in Gana context).
Future<List<String>> resolveManasNames(Isar isar, List<String> manasIds) async {
  if (manasIds.isEmpty) return const [];
  final names = <String>[];
  for (final id in manasIds) {
    final row = await isar.manasModels
        .filter()
        .manasIdEqualTo(id)
        .and()
        .removedAtIsNull()
        .findFirst();
    if (row != null) names.add(row.name);
  }
  return names;
}

/// Assemble inputs → reply ancestry → knowledge → prompt for [gana].
///
/// Returns `null` when the Gana requires new input but none arrived past its
/// cursor (the caller logs a [GanaSkipReason.noNewInput] skip). [loadKnowledge]
/// is the one divergent step injected by the caller: foreground passes the
/// relevance-ranked merge (it receives the joined input text as the query),
/// background passes newest-first (and ignores the query).
Future<GanaPreparedRun?> prepareGanaRun({
  required Isar isar,
  required GanaEntity gana,
  required String selfPubkeyHex,
  required Set<String> selfOutputs,
  required Future<List<PackedNote>> Function(String? relevanceQuery)
      loadKnowledge,
}) async {
  final inputs = await GanaInputFilter.fetch(
    isar: isar,
    gana: gana,
    selfPubkeyHex: selfPubkeyHex,
    selfOutputEventIds: selfOutputs,
  );
  if (gana.inputType != null && inputs.isEmpty) return null;

  final ancestry = <String, List<NoteModel>>{};
  for (final n in inputs) {
    if (n.replyToEventId != null) {
      ancestry[n.eventId] = await GanaInputFilter.ancestry(isar: isar, note: n);
    }
  }

  final manasNames = await resolveManasNames(isar, gana.manasIds);
  final queryText =
      inputs.isEmpty ? null : inputs.map((n) => n.content).join('\n').trim();
  final knowledge = await loadKnowledge(queryText);

  final prompt = GanaPromptBuilder.build(
    taskPrompt: gana.taskPrompt,
    manasNames: manasNames,
    knowledge: knowledge,
    inputMessagesByOldestFirst: inputs,
    replyAncestry: ancestry,
  );

  return GanaPreparedRun(
    inputs: inputs,
    ancestry: ancestry,
    manasNames: manasNames,
    prompt: prompt,
  );
}

/// True when the (already-sanitized) model output is empty or the NOOP
/// sentinel — i.e. the model chose to stay silent on this input.
bool isGanaNoop(String body) =>
    body.isEmpty || body.toUpperCase() == GanaPromptBuilder.noopSentinel;

/// Persist a [GanaRunModel] log row and, once the run has finished, count it
/// on the Gana's lifetime counters (same transaction, so the two never drift).
/// A row re-written under the same [runId] is counted once.
Future<void> writeGanaRun({
  required Isar isar,
  required String runId,
  required String ganaId,
  required DateTime startedAt,
  required GanaRunStatus status,
  GanaSkipReason? skipReason,
  List<String> inputEventIds = const [],
  String? outputEventId,
  String? error,
}) async {
  await isar.writeTxn(() async {
    final previous =
        await isar.ganaRunModels.filter().runIdEqualTo(runId).findFirst();
    await isar.ganaRunModels.put(
      GanaRunModel()
        ..id = previous?.id ?? Isar.autoIncrement
        ..runId = runId
        ..ganaId = ganaId
        ..startedAt = startedAt
        ..status = status
        ..skipReason = skipReason
        ..inputEventIds = inputEventIds
        ..outputEventId = outputEventId
        ..error = error,
    );

    final alreadyCounted =
        previous != null && previous.status != GanaRunStatus.running;
    if (status == GanaRunStatus.running || alreadyCounted) return;
    final gana =
        await isar.ganaModels.filter().ganaIdEqualTo(ganaId).findFirst();
    if (gana == null) return;
    switch (status) {
      case GanaRunStatus.succeeded:
        gana.runsSucceeded = (gana.runsSucceeded ?? 0) + 1;
      case GanaRunStatus.failed:
        gana.runsFailed = (gana.runsFailed ?? 0) + 1;
      case GanaRunStatus.skipped:
        gana.runsSkipped = (gana.runsSkipped ?? 0) + 1;
      case GanaRunStatus.running:
        return;
    }
    await isar.ganaModels.put(gana);
  });
}

/// Advance a Gana's input cursor + `lastRunAt`, auto-disabling one-shot Ganas
/// after a real publish ([publishedOutput] = true). Re-fetches by ganaId so a
/// concurrent write from the other isolate isn't trampled.
///
/// Cursor state (`lastProcessedEventId`, `lastProcessedCreated`, `lastRunAt`)
/// is per-device — it never round-trips through mesh sync. But when an
/// auto-disable fires (`publishedOutput && oneShot`), the `enabled=false`
/// flip is a definition-level change that MUST sync — pass [codec] so we can
/// re-sign the row. When [codec] is null (no active identity or a caller
/// that hasn't wired one up), the flip still happens locally but peers will
/// re-enable us from their older event on next sync; the Phase-0a migration
/// pass will re-sign on the next launch that has keys.
Future<void> advanceGanaCursor({
  required Isar isar,
  required String ganaId,
  required List<NoteModel> inputs,
  bool publishedOutput = false,
  MeshEventCodec? codec,
}) async {
  final fresh = await isar.ganaModels
      .filter()
      .ganaIdEqualTo(ganaId)
      .and()
      .removedAtIsNull()
      .findFirst();
  if (fresh == null) return;
  if (inputs.isNotEmpty) {
    final last = inputs.last; // oldest-first → last is newest
    fresh
      ..lastProcessedEventId = last.eventId
      ..lastProcessedCreated = last.created;
  }
  fresh.lastRunAt = DateTime.now();

  var flippedEnabled = false;
  if (publishedOutput && fresh.triggerMode == GanaTriggerMode.oneShot) {
    fresh.enabled = false;
    fresh.updatedAt = DateTime.now();
    flippedEnabled = true;
  }

  if (flippedEnabled && codec != null) {
    fresh.signedNostrEvent = await codec.signRecord(
      kind: MeshEventKinds.gana,
      dTag: ganaId,
      content: GanaBody.forActive(fresh),
    );
  }

  await isar.writeTxn(() async {
    await isar.ganaModels.put(fresh);
  });
}
