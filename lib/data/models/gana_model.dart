import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/gana_input_type.dart';
import 'package:uniun/core/enum/gana_output_type.dart';
import 'package:uniun/core/enum/gana_trigger_mode.dart';
import 'package:uniun/domain/entities/gana/gana_entity.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';

part 'gana_model.g.dart';

/// A user-defined AI worker. See `ganas.md` (repo root) for the full model.
///
/// Local-only config — never broadcast as a Nostr event. Two devices owned by
/// the same user have independent Gana sets until/unless a private-config
/// sync layer is added (out of scope for v1).
@Collection(ignore: {'copyWith'})
@Name('Gana')
class GanaModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String ganaId;

  late String name;

  /// The Manas backing the Gana's knowledge. Stored as a list (Isar has no
  /// set columns); the form selects exactly one, but the engine still treats
  /// it as a union so legacy multi-Manas rows keep working.
  List<String> manasIds = const [];

  /// User-authored instructions injected into every prompt.
  late String taskPrompt;

  // ── Input ────────────────────────────────────────────────────────────────

  /// Null ⇒ standalone (no input fetch — interval-only Gana).
  @Enumerated(EnumType.name)
  GanaInputType? inputType;

  /// Type-dependent reference id. See [GanaInputType] for what each holds.
  /// - group: hex group id (kind-40 event id)
  /// - privateGroup: privateGroupId
  /// - dm: stringified `DmConversationModel.id` (Isar Id)
  /// - user: pubkey hex
  /// - followedNote: event id of the followed note
  String? inputRefId;

  // ── Output ───────────────────────────────────────────────────────────────

  @Enumerated(EnumType.name)
  late GanaOutputType outputType;

  /// Public group id when [outputType] == group.
  @Name('outputChannelId') // stored name preserved across channel→group rename
  String? outputGroupId;

  /// Group id when [outputType] == privateGroup.
  @Name('outputGroupId') // stored name preserved (was GanaModel.outputGroupId)
  String? outputPrivateGroupId;

  /// `DmConversationModel.id` when [outputType] == dm. Plain `int?`, not
  /// `Id?` — `Id` is reserved for the primary key of THIS collection.
  int? outputDmConversationId;

  // ── Model preference ─────────────────────────────────────────────────────

  /// Per-Gana preferred model. `null` ⇒ "use whichever model is active."
  /// When set and the active model id doesn't match, the run is logged as
  /// `skipped: modelMismatch` and the cursor is NOT advanced.
  String? desiredModelId;

  /// Backend [desiredModelId] belongs to. Null on legacy rows (treated as
  /// local). `uniunCloud` routes the run through [LlmRepository]'s
  /// per-call override instead of the on-device gate.
  @Enumerated(EnumType.name)
  LlmBackendType? desiredBackend;

  // ── Triggers ─────────────────────────────────────────────────────────────

  bool triggerReactive = false;

  /// Null ⇒ no interval trigger. Form clamps to ≥5 minutes; background
  /// execution further clamps to ≥30 minutes regardless of this value.
  int? triggerIntervalMinutes;

  /// How the Gana fires. Recurring = cron-job behaviour (default).
  /// One-shot = auto-disable after the first successful run.
  /// Defaults to recurring on legacy rows.
  @Enumerated(EnumType.name)
  GanaTriggerMode triggerMode = GanaTriggerMode.recurring;

  /// Total successful publishes this Gana is allowed to produce before
  /// auto-disabling. Required when [triggerMode] is recurring (otherwise
  /// the user can forget about it and the Gana would publish forever);
  /// ignored for one-shot (which auto-disables after one publish anyway).
  ///
  /// Form clamps to 1..1000. Engine counts successful runs via
  /// `GanaRunModel where ganaId=X AND outputEventId != null` and, once
  /// the count meets or exceeds this value, skips with
  /// [GanaSkipReason.maxOutputsReached] and sets [enabled]=false.
  int? maxOutputs;

  // ── Master switch ────────────────────────────────────────────────────────

  /// Defaults to `false`. The user explicitly enables after reviewing the
  /// config — prevents accidental publishing on save.
  bool enabled = false;

  // ── Cursor ───────────────────────────────────────────────────────────────

  /// Last input event id the engine consumed — used as a same-second
  /// tiebreak in the input filter.
  String? lastProcessedEventId;

  /// Monotonic "new since" cursor — most input filters select rows with
  /// `created > lastProcessedCreated`.
  DateTime? lastProcessedCreated;

  /// Anchor for interval triggers — prevents double-fires on app relaunch.
  DateTime? lastRunAt;

  // ── Lifetime run counters ────────────────────────────────────────────────

  /// Per-device totals, bumped by `writeGanaRun` when a run finishes. The run
  /// log keeps only the last 10 per Gana, so these are the only lifetime
  /// figures. Local state like the cursor — never part of the mesh body.
  /// Nullable on purpose: Isar reads a field missing from an older row as the
  /// minimum integer, so a non-nullable counter would start hugely negative.
  int? runsSucceeded;
  int? runsFailed;
  int? runsSkipped;

  // ── Metadata ─────────────────────────────────────────────────────────────

  late DateTime createdAt;
  late DateTime updatedAt;

  // ── Mesh sync (§3) ───────────────────────────────────────────────────────

  /// Signed+encrypted Nostr Kind 30520 event for this row. Nullable during
  /// Phase 0a migration.
  String? signedNostrEvent;

  /// Tombstone marker (§5a). Null on active Ganas.
  @Index()
  DateTime? removedAt;
}

extension GanaModelExtension on GanaModel {
  GanaEntity toDomain() => GanaEntity(
        ganaId: ganaId,
        name: name,
        manasIds: manasIds,
        taskPrompt: taskPrompt,
        inputType: inputType,
        inputRefId: inputRefId,
        outputType: outputType,
        outputGroupId: outputGroupId,
        outputPrivateGroupId: outputPrivateGroupId,
        outputDmConversationId: outputDmConversationId,
        desiredModelId: desiredModelId,
        desiredBackend: desiredBackend,
        triggerReactive: triggerReactive,
        triggerIntervalMinutes: triggerIntervalMinutes,
        triggerMode: triggerMode,
        maxOutputs: maxOutputs,
        enabled: enabled,
        lastProcessedEventId: lastProcessedEventId,
        lastProcessedCreated: lastProcessedCreated,
        lastRunAt: lastRunAt,
        runsSucceeded: runsSucceeded ?? 0,
        runsFailed: runsFailed ?? 0,
        runsSkipped: runsSkipped ?? 0,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
