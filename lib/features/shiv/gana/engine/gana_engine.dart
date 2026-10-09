import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/gana_output_type.dart';
import 'package:uniun/core/enum/gana_run_status.dart';
import 'package:uniun/core/enum/gana_trigger_mode.dart';
import 'package:uniun/core/utils/llm_text_sanitizer.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/data/datasources/llm/flutter_gemma_gateway.dart';
import 'package:uniun/data/datasources/llm/local_llm_runner.dart';
import 'package:uniun/data/models/dm/dm_conversation_model.dart';
import 'package:uniun/data/models/gana_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/domain/entities/gana/gana_entity.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/domain/entities/llm/llm_task_kind.dart';
import 'package:uniun/domain/repositories/user_repository.dart';
import 'package:uniun/domain/usecases/create_group_message_usecase.dart';
import 'package:uniun/domain/usecases/dm_usecases.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/domain/usecases/note_usecases.dart';
import 'package:uniun/domain/usecases/private_group_usecases.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/features/brahma/utils/nostr_event_utils.dart';
import 'package:uniun/features/mesh/sync/bodies/gana_body.dart';
import 'package:uniun/features/mesh/sync/mesh_event_codec.dart';
import 'package:uniun/features/mesh/sync/mesh_event_signer.dart';
import 'package:uniun/features/shiv/gana/engine/gana_prompt_builder.dart';
import 'package:uniun/features/shiv/generation/context/manas_context_loader.dart';
import 'package:uniun/features/shiv/generation/gana_run.dart';
import 'package:uuid/uuid.dart';

/// Scheduler + runner for enabled Ganas, running in the main isolate.
///
/// Architecture decision (2026-06-20): the engine no longer runs in its own
/// isolate. Its hot path is event-driven (`Isar.watchLazy`, `Timer.periodic`)
/// + FFI inference (native-threaded) — no pure-Dart CPU work that would
/// justify the cost of cross-isolate plumbing. Living in the main isolate
/// gives us:
///
///   • Direct calls to `AIModelRunner.generateOneShot` (which routes through
///     [InferenceScheduler] with `kind: gana` — T4 fair pool by default,
///     T1 while the GanaForm preview is open, T3 once the cron deadline has
///     passed; Shiv chat (T0) preempts via `InferenceChat.stopGeneration`).
///     A Gana pinned to a cloud model (`desiredBackend == uniunCloud`)
///     bypasses the scheduler entirely via [GenerateOneShotUseCase]'s
///     backend override. A Gana with no pin at all follows whatever
///     backend/model is globally active (via [GetActiveLlmModelUseCase])
///     instead of assuming local.
///   • Direct calls to publish use cases (NIP-17 DM gift-wrap, NIP-29 MLS
///     private groups) without going through a pending-table dispatcher.
///   • Direct access to `EmbeddingService` for Manas vector retrieval.
///
/// Trade-off: prompt building + Isar reads + result handling run on the main
/// isolate. Total Dart-thread work per Gana run: ~30-50ms spread across the
/// generation's wall-clock window (200+ seconds). Negligible at 60 Hz.
///
/// Single-flight FIFO globally: only one Gana run executes at a time across
/// all reactive + interval triggers. Guarded by [_runMutex].
///
/// **Background path:** the WorkManager dispatcher (`gana_workmanager.dart`)
/// stays as-is. It runs in its OS-dispatched isolate when the app is
/// killed/backgrounded; the engine here is foreground only.
@lazySingleton
class GanaEngine {
  GanaEngine(
    this._isar,
    this._runner,
    this._settings,
    this._userRepo,
    this._publishNote,
    this._groupMessage,
    this._dm,
    this._privateGroup,
    this._embedAndStore,
    this._manasLoader,
    this._signer,
    this._generateOneShot,
    this._isCloudConnected,
    this._getActiveLlmModel,
    this._gateway,
  );

  final Isar _isar;
  final AIModelRunner _runner;
  final AppSettingsStore _settings;
  final UserRepository _userRepo;
  final PublishNoteUseCase _publishNote;
  final CreateGroupMessageUseCase _groupMessage;
  final SendDmUseCase _dm;
  final SendPrivateGroupMessageUsecase _privateGroup;
  final EmbedAndStoreNoteUseCase _embedAndStore;
  final ManasContextLoader _manasLoader;
  final MeshEventSigner _signer;
  final GenerateOneShotUseCase _generateOneShot;
  final IsUniunCloudConnectedUseCase _isCloudConnected;
  final GetActiveLlmModelUseCase _getActiveLlmModel;
  final FlutterGemmaGateway _gateway;

  // ── Schedule state ─────────────────────────────────────────────────────

  /// ganaId → debounce timer for reactive runs. Cancelled and replaced on
  /// every `noteModels.watchLazy()` tick.
  final Map<String, Timer> _reactiveDebounce = {};

  /// ganaId → interval timer.
  final Map<String, Timer> _intervalTimers = {};

  /// Current schedule (loaded on each rebuild).
  List<GanaEntity> _enabledGanas = const [];

  /// Single-flight guard. One Gana run at a time, app-wide.
  Completer<void>? _runMutex;

  /// Subscriptions to keep alive for the engine's lifetime.
  final List<StreamSubscription<void>> _subs = [];

  /// ganaIds we've already auto-fired this engine lifetime under the
  /// "standalone + one-shot fires on enable" rule. Prevents re-firing on
  /// every schedule rebuild (the Isar watcher emits on any Gana row write,
  /// including run-status updates).
  final Set<String> _firedOnEnable = <String>{};

  bool _started = false;
  bool _stopping = false;
  Timer? _rebuildDebounce;
  final Set<Future<void>> _rebuilds = {};

  static const Duration _reactiveDebounceDelay = Duration(seconds: 3);
  static const Duration _scheduleRebuildDebounce = Duration(milliseconds: 500);

  Future<void> start() async {
    if (_started) return;
    _stopping = false;
    _started = true;
    await _trackRebuild();
    if (_stopping) return;

    // Schedule reload on any Gana config change.
    _subs.add(_isar.ganaModels.watchLazy().listen((_) {
      _rebuildDebounce?.cancel();
      _rebuildDebounce =
          Timer(_scheduleRebuildDebounce, () => unawaited(_trackRebuild()));
    }));

    // Reactive trigger source. Single watcher; each enabled Gana picks up
    // its own filtered input on tick.
    _subs.add(_isar.noteModels.watchLazy().listen((_) {
      for (final g in _enabledGanas) {
        if (g.triggerReactive && g.inputType != null) {
          _scheduleReactive(g);
        }
      }
    }));

    debugPrint('GanaEngine started (main isolate)');
  }

  Future<void> stop() async {
    _stopping = true;
    _rebuildDebounce?.cancel();
    _rebuildDebounce = null;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    for (final t in _reactiveDebounce.values) {
      t.cancel();
    }
    _reactiveDebounce.clear();
    for (final t in _intervalTimers.values) {
      t.cancel();
    }
    _intervalTimers.clear();
    await Future.wait(_rebuilds.toList());
    await _runMutex?.future;
    _enabledGanas = const [];
    _firedOnEnable.clear();
    _started = false;
  }

  // ── Schedule rebuild ───────────────────────────────────────────────────

  Future<void> _trackRebuild() async {
    final rebuild = _rebuildSchedule();
    _rebuilds.add(rebuild);
    try {
      await rebuild;
    } finally {
      _rebuilds.remove(rebuild);
    }
  }

  Future<void> _rebuildSchedule() async {
    final rows = await _isar.ganaModels
        .filter()
        .removedAtIsNull()
        .and()
        .enabledEqualTo(true)
        .findAll();
    if (_stopping) return;
    _enabledGanas = rows.map((m) => m.toDomain()).toList();

    final liveIds = {for (final g in _enabledGanas) g.ganaId};
    final stale =
        _intervalTimers.keys.where((id) => !liveIds.contains(id)).toList();
    for (final id in stale) {
      _intervalTimers.remove(id)?.cancel();
    }

    // (Re)install interval timers — cancel-and-replace is fine because
    // interval minutes are anchored on `lastRunAt`, so we don't lose the
    // schedule across a reload.
    for (final g in _enabledGanas) {
      final mins = g.triggerIntervalMinutes;
      if (mins == null || mins <= 0) {
        _intervalTimers.remove(g.ganaId)?.cancel();
        continue;
      }
      _intervalTimers.remove(g.ganaId)?.cancel();
      _intervalTimers[g.ganaId] = Timer.periodic(
        Duration(minutes: mins),
        (_) => _maybeRunInterval(g.ganaId),
      );
    }

    debugPrint('GanaEngine: schedule rebuilt with '
        '${_enabledGanas.length} enabled Gana(s)');

    // Standalone + one-shot fires immediately on enable. Reactive watcher
    // skips it (inputType is null) and there's no interval timer either.
    // `_firedOnEnable` guards against re-firing on every rebuild.
    for (final g in _enabledGanas) {
      if (g.inputType == null &&
          g.triggerMode == GanaTriggerMode.oneShot &&
          !_firedOnEnable.contains(g.ganaId)) {
        _firedOnEnable.add(g.ganaId);
        debugPrint('[gana] fire-on-enable standalone one-shot '
            'name="${g.name}"');
        unawaited(_runIfPossible(g.ganaId));
      }
    }
    _firedOnEnable.removeWhere((id) => !liveIds.contains(id));
  }

  // ── Triggers ───────────────────────────────────────────────────────────

  void _scheduleReactive(GanaEntity g) {
    if (_stopping) return;
    _reactiveDebounce[g.ganaId]?.cancel();
    _reactiveDebounce[g.ganaId] =
        Timer(_reactiveDebounceDelay, () => _runIfPossible(g.ganaId));
  }

  /// Test-only direct entry into the interval gate, bypassing the need to
  /// wait for a real `Timer.periodic` tick — `Timer.periodic` only accepts
  /// whole-minute durations, so driving the "too soon since lastRunAt"
  /// branch through a real tick would need multiple real minutes and a
  /// timing race with no slack. The real-timer *dispatch* path itself is
  /// covered separately by waiting out one real tick.
  @visibleForTesting
  Future<void> debugMaybeRunInterval(String ganaId) =>
      _maybeRunInterval(ganaId);

  Future<void> _maybeRunInterval(String ganaId) async {
    final row = await _isar.ganaModels
        .filter()
        .ganaIdEqualTo(ganaId)
        .and()
        .removedAtIsNull()
        .findFirst();
    if (row == null || !row.enabled) return;
    final mins = row.triggerIntervalMinutes;
    if (mins == null || mins <= 0) return;
    final last = row.lastRunAt;
    if (last != null &&
        DateTime.now().difference(last) < Duration(minutes: mins)) {
      return;
    }
    await _runIfPossible(ganaId);
  }

  Future<void> _runIfPossible(String ganaId) async {
    if (_stopping) return;
    if (_runMutex != null) return; // single-flight
    final mutex = _runMutex = Completer<void>();
    try {
      final row = await _isar.ganaModels
          .filter()
          .ganaIdEqualTo(ganaId)
          .and()
          .removedAtIsNull()
          .findFirst();
      if (_stopping || row == null || !row.enabled) return;
      await _runOnce(row.toDomain());
    } catch (e, st) {
      debugPrint('GanaEngine: unexpected error in _runOnce: $e\n$st');
    } finally {
      _runMutex = null;
      mutex.complete();
    }
  }

  // ── One run ────────────────────────────────────────────────────────────

  Future<void> _runOnce(GanaEntity g) async {
    final startedAt = DateTime.now();
    final runId = const Uuid().v4();
    debugPrint('[gana] ────────────────────────────────────────────');
    debugPrint('[gana] runOnce START name="${g.name}" '
        'runId=${runId.substring(0, 8)} '
        'inputType=${g.inputType?.name ?? "standalone"} '
        'outputType=${g.outputType.name} '
        'mode=${g.triggerMode.name}');

    // Model gates — done inline now that we're in the main isolate.
    //
    // Three cases:
    //   1. desiredBackend == uniunCloud  → explicit per-agent cloud pin.
    //   2. desiredBackend == null AND
    //      desiredModelId != null        → legacy explicit LOCAL pin
    //                                       (skip-on-mismatch, unchanged).
    //   3. both null                     → fully unset ("use whichever is
    //      active"). Follow the GLOBAL active backend/model instead of
    //      assuming local — a Gana with no pin at all should track the same
    //      switch Shiv chat uses, not silently require local.
    var isCloud = g.desiredBackend == LlmBackendType.uniunCloud;
    var cloudModelId = g.desiredModelId;
    if (!isCloud && g.desiredBackend == null && g.desiredModelId == null) {
      final activeModel = (await _getActiveLlmModel.call()).fold(
        (_) => null,
        (m) => m,
      );
      if (activeModel?.backend == LlmBackendType.uniunCloud) {
        isCloud = true;
        cloudModelId = activeModel!.id;
      }
    }

    if (isCloud) {
      final connected = await _isCloudConnected.call();
      if (!connected || cloudModelId == null) {
        debugPrint('[gana]   SKIPPED: cloudUnavailable '
            '(connected=$connected desiredModelId=$cloudModelId)');
        await _logRun(
          runId: runId,
          ganaId: g.ganaId,
          startedAt: startedAt,
          status: GanaRunStatus.skipped,
          skipReason: GanaSkipReason.cloudUnavailable,
        );
        return;
      }
    } else {
      if (!_gateway.hasActiveModel()) {
        debugPrint('[gana]   SKIPPED: noActiveModel');
        await _logRun(
          runId: runId,
          ganaId: g.ganaId,
          startedAt: startedAt,
          status: GanaRunStatus.skipped,
          skipReason: GanaSkipReason.noActiveModel,
        );
        return;
      }
      final activeIdName = _settings.activeModelId?.name;
      if (g.desiredModelId != null &&
          activeIdName != null &&
          g.desiredModelId != activeIdName) {
        debugPrint('[gana]   SKIPPED: modelMismatch '
            '(desired=${g.desiredModelId} active=$activeIdName)');
        await _logRun(
          runId: runId,
          ganaId: g.ganaId,
          startedAt: startedAt,
          status: GanaRunStatus.skipped,
          skipReason: GanaSkipReason.modelMismatch,
        );
        return;
      }
    }

    // Fetch input + self-output history.
    final selfOutputs = await ganaSelfOutputs(_isar, g.ganaId);
    debugPrint('[gana]   self-outputs guard set: ${selfOutputs.length}');

    // Recurring cap — count this run BEFORE doing inference work so we
    // bail early. One-shot Ganas auto-disable on first publish anyway,
    // so the cap is recurring-only.
    if (g.triggerMode == GanaTriggerMode.recurring &&
        g.maxOutputs != null &&
        selfOutputs.length >= g.maxOutputs!) {
      debugPrint('[gana]   SKIPPED: maxOutputsReached '
          '(${selfOutputs.length}/${g.maxOutputs}) — auto-disabling');
      await _logRun(
        runId: runId,
        ganaId: g.ganaId,
        startedAt: startedAt,
        status: GanaRunStatus.skipped,
        skipReason: GanaSkipReason.maxOutputsReached,
      );
      await _disable(g.ganaId);
      return;
    }

    final keys = await _userRepo.getActiveKeysHex();
    if (keys == null) {
      debugPrint('[gana]   SKIPPED: no active user');
      await _logRun(
        runId: runId,
        ganaId: g.ganaId,
        startedAt: startedAt,
        status: GanaRunStatus.skipped,
        skipReason: GanaSkipReason.noActiveModel,
        error: 'no active user',
      );
      return;
    }

    // Input → ancestry → knowledge (relevance-ranked) → prompt. Shared with the
    // background dispatcher via [prepareGanaRun]; foreground injects the
    // relevance-ranked Manas merge (query = the joined input text).
    final prepared = await prepareGanaRun(
      isar: _isar,
      gana: g,
      selfPubkeyHex: keys.pubkeyHex,
      selfOutputs: selfOutputs,
      loadKnowledge: (query) => _manasLoader.merge(
        manasIds: g.manasIds,
        budget: GanaPromptBuilder.defaultMaxTokens ~/ 2,
        relevanceQuery: query,
      ),
    );
    if (prepared == null) {
      debugPrint('[gana]   SKIPPED: noNewInput');
      await _logRun(
        runId: runId,
        ganaId: g.ganaId,
        startedAt: startedAt,
        status: GanaRunStatus.skipped,
        skipReason: GanaSkipReason.noNewInput,
      );
      return;
    }
    final inputs = prepared.inputs;
    final prompt = prepared.prompt;
    debugPrint('[gana]   input filter: ${inputs.length} note(s); '
        'Manas: ${prepared.manasNames.join(", ")}; '
        'prompt: ${prompt.length} chars (~${prompt.length ~/ 4} tokens)');

    // Inference — direct call, no SendPort.
    final modelBefore = _settings.activeModelId?.name;
    debugPrint('[gana]   inference REQUEST (active=$modelBefore)');
    final infStart = DateTime.now();
    String? text;
    String? error;
    if (isCloud) {
      final result = await _generateOneShot.call(GenerateOneShotInput(
        prompt: prompt,
        kind: LlmTaskKind.gana,
        backendOverride: LlmBackendType.uniunCloud,
        modelIdOverride: cloudModelId,
      ));
      // Stage-tagged so the run log says where it failed (see GanaRunError).
      result.fold((f) => error = 'cloud: $f', (t) => text = t);
    } else {
      try {
        text = await _runner.generateOneShot(prompt, kind: LlmTaskKind.gana);
      } catch (e) {
        error = 'inference: $e';
      }
    }
    final infMs = DateTime.now().difference(infStart).inMilliseconds;

    if (error != null) {
      debugPrint('[gana]   inference FAILED in ${infMs}ms: $error');
      await _logRun(
        runId: runId,
        ganaId: g.ganaId,
        startedAt: startedAt,
        status: GanaRunStatus.failed,
        error: error,
      );
      return;
    }
    if (text == null) {
      // Runner returned null → preempted (chat cut in) or model swapped.
      final modelAfter = _settings.activeModelId?.name;
      final swapped = modelAfter != modelBefore;
      debugPrint('[gana]   inference CANCELLED in ${infMs}ms '
          '(${swapped ? "modelSwapped" : "preempted"})');
      await _logRun(
        runId: runId,
        ganaId: g.ganaId,
        startedAt: startedAt,
        status: GanaRunStatus.skipped,
        skipReason: GanaSkipReason.modelSwapped,
      );
      return;
    }

    // Local text is already sanitized inside AIModelRunner.generateOneShot;
    // cloud text isn't, so clean unconditionally (idempotent on local text).
    final body = LlmTextSanitizer.clean(text!).trim();
    debugPrint('[gana]   inference OK in ${infMs}ms (${body.length} chars)');
    if (isGanaNoop(body)) {
      debugPrint('[gana]   SKIPPED: noopReturned');
      await _logRun(
        runId: runId,
        ganaId: g.ganaId,
        startedAt: startedAt,
        status: GanaRunStatus.skipped,
        skipReason: GanaSkipReason.noopReturned,
      );
      await _advanceCursor(g, inputs, lastRunAt: DateTime.now());
      return;
    }
    final preview = body.replaceAll('\n', ' \\n ');
    debugPrint('[gana]   body: "'
        '${preview.length > 80 ? '${preview.substring(0, 80)}…' : preview}"');

    // Publish — engine calls the use case directly. No pending table.
    String? outputEventId;
    try {
      outputEventId = await _publish(
        g,
        body,
        privkeyHex: keys.privkeyHex,
        pubkeyHex: keys.pubkeyHex,
      );
    } catch (e, st) {
      debugPrint('[gana]   PUBLISH FAILED: $e\n$st');
      await _logRun(
        runId: runId,
        ganaId: g.ganaId,
        startedAt: startedAt,
        status: GanaRunStatus.failed,
        error: 'publish: $e',
      );
      return;
    }

    debugPrint('[gana]   PUBLISHED outputEventId='
        '${outputEventId.length > 12 ? outputEventId.substring(0, 12) : outputEventId}');
    await _logRun(
      runId: runId,
      ganaId: g.ganaId,
      startedAt: startedAt,
      status: GanaRunStatus.succeeded,
      inputEventIds: inputs.map((n) => n.eventId).toList(),
      outputEventId: outputEventId,
    );
    await _advanceCursor(g, inputs,
        lastRunAt: DateTime.now(), publishedOutput: true);
    debugPrint('[gana] runOnce END status=succeeded '
        'totalMs=${DateTime.now().difference(startedAt).inMilliseconds}');
  }

  // ── Publish — direct calls, no pending table ───────────────────────────

  Future<String> _publish(
    GanaEntity g,
    String body, {
    required String privkeyHex,
    required String pubkeyHex,
  }) async {
    switch (g.outputType) {
      case GanaOutputType.feed:
        return await _publishFeed(body, privkeyHex, pubkeyHex);
      case GanaOutputType.group:
        return await _publishGroup(g.outputGroupId, body, privkeyHex);
      case GanaOutputType.privateGroup:
        return await _publishPrivateGroup(
            g.outputPrivateGroupId, body, privkeyHex, pubkeyHex);
      case GanaOutputType.dm:
        return await _publishDm(
            g.outputDmConversationId, body, pubkeyHex);
    }
  }

  Future<String> _publishFeed(
    String body,
    String privkeyHex,
    String pubkeyHex,
  ) async {
    final event = signNostrEvent(
      content: body,
      tags: const <List<String>>[],
      privkeyHex: privkeyHex,
    );
    final entity = noteEntityFromEvent(
      event: event,
      pubkeyHex: pubkeyHex,
      eTagRefs: const [],
      tTags: const [],
    );
    final res = await _publishNote.call(entity);
    return res.fold(
      (f) => throw Exception(f.toString()),
      (note) {
        // Feed the Gana's own note into the RAG pipeline the same way
        // Brahma feeds user-typed notes. Without this, the note shows up
        // in Vishnu but is invisible to vector search — so future Ganas
        // (and Shiv chat) can't surface it as context.
        unawaited(_embedAndStore.call((note.id, note.content)));
        return note.id;
      },
    );
  }

  Future<String> _publishGroup(
    String? groupId,
    String body,
    String privkeyHex,
  ) async {
    if (groupId == null) {
      throw StateError('group outputType requires outputGroupId');
    }
    final res = await _groupMessage.call(CreateGroupMessageInput(
      groupId: groupId,
      content: body,
      privateKey: privkeyHex,
    ));
    return res.fold(
      (f) => throw Exception(f.toString()),
      (note) => note.id,
    );
  }

  Future<String> _publishPrivateGroup(
    String? groupId,
    String body,
    String privkeyHex,
    String pubkeyHex,
  ) async {
    if (groupId == null) {
      throw StateError('privateGroup outputType requires outputPrivateGroupId');
    }
    // `execute` returns void; the transport writes a NoteModel synchronously.
    // Snapshot before/after to recover the eventId.
    final before = await _latestSelfEventIdInPrivateGroup(groupId, pubkeyHex);
    await _privateGroup.execute(
      groupId: groupId,
      content: body,
      authorPubkey: pubkeyHex,
      privkeyHex: privkeyHex,
    );
    final after = await _latestSelfEventIdInPrivateGroup(groupId, pubkeyHex);
    if (after != null && after != before) return after;
    return 'pc:$groupId:${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String> _publishDm(
    int? conversationId,
    String body,
    String pubkeyHex,
  ) async {
    if (conversationId == null) {
      throw StateError('dm outputType requires outputDmConversationId');
    }
    final conv = await _isar.dmConversationModels
        .filter()
        .idEqualTo(conversationId)
        .removedAtIsNull()
        .findFirst();
    if (conv == null) {
      throw StateError(
          'DM conversation $conversationId not found (or tombstoned)');
    }
    final before = await _latestSelfEventIdInDm(conv.id, pubkeyHex);
    final res = await _dm.call(SendDmParams(
      otherPubkey: conv.otherPubkey,
      content: body,
    ));
    return res.fold<Future<String>>(
      (f) async => throw Exception(f.toString()),
      (_) async {
        final after = await _latestSelfEventIdInDm(conv.id, pubkeyHex);
        if (after != null && after != before) return after;
        return 'dm:${conv.otherPubkey}:${DateTime.now().millisecondsSinceEpoch}';
      },
    );
  }

  Future<String?> _latestSelfEventIdInPrivateGroup(
    String groupId,
    String selfPubkey,
  ) async {
    final row = await _isar.noteModels
        .filter()
        .privateGroupIdEqualTo(groupId)
        .authorPubkeyEqualTo(selfPubkey)
        .sortByCreatedDesc()
        .findFirst();
    return row?.eventId;
  }

  Future<String?> _latestSelfEventIdInDm(
    int conversationId,
    String selfPubkey,
  ) async {
    final row = await _isar.noteModels
        .filter()
        .conversationIdEqualTo(conversationId)
        .authorPubkeyEqualTo(selfPubkey)
        .sortByCreatedDesc()
        .findFirst();
    return row?.eventId;
  }

  // ── Run log + cursor advance ───────────────────────────────────────────

  // Run log + cursor advance delegate to the shared, isolate-agnostic
  // [gana_run.dart] helpers so foreground and background can't drift.

  Future<void> _logRun({
    required String runId,
    required String ganaId,
    required DateTime startedAt,
    required GanaRunStatus status,
    GanaSkipReason? skipReason,
    List<String> inputEventIds = const [],
    String? outputEventId,
    String? error,
  }) =>
      writeGanaRun(
        isar: _isar,
        runId: runId,
        ganaId: ganaId,
        startedAt: startedAt,
        status: status,
        skipReason: skipReason,
        inputEventIds: inputEventIds,
        outputEventId: outputEventId,
        error: error,
      );

  Future<void> _advanceCursor(
    GanaEntity g,
    List<NoteModel> inputs, {
    required DateTime lastRunAt,
    bool publishedOutput = false,
  }) async {
    // Auto-disable (published one-shot) is a definition-level flip that must
    // sync — sign it. Pure cursor advances stay unsigned.
    final codec = await _signer.currentCodec();
    return advanceGanaCursor(
      isar: _isar,
      ganaId: g.ganaId,
      inputs: inputs,
      publishedOutput: publishedOutput,
      codec: codec,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Future<void> _disable(String ganaId) async {
    final row = await _isar.ganaModels
        .filter()
        .ganaIdEqualTo(ganaId)
        .and()
        .removedAtIsNull()
        .findFirst();
    if (row == null) return;
    row
      ..enabled = false
      ..updatedAt = DateTime.now();
    row.signedNostrEvent = await _signer.sign(
      kind: MeshEventKinds.gana,
      dTag: ganaId,
      content: GanaBody.forActive(row),
    );
    await _isar.writeTxn(() async {
      await _isar.ganaModels.put(row);
    });
  }
}
