import 'dart:typed_data';
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/datasources/llm/llm_data_source.dart';
import 'package:uniun/data/datasources/llm/llm_preferences_data_source.dart';
import 'package:uniun/domain/entities/llm/llm_model_info.dart';
import 'package:uniun/domain/entities/llm/llm_task_kind.dart';
import 'package:uniun/domain/repositories/uniun_repository.dart';

/// Cloud LLM backend backed by the UNIUN inference gateway.
///
/// [UniunRepository] is the only gateway-facing dependency — it owns the
/// raw HTTP client, the account's key, catalog filtering, and 401 recovery.
/// This class never sees a `uk_` key: it just asks for a model catalog or a
/// token stream and picks which model / builds the OpenAI-shaped message
/// list, which is the actual "cloud LLM chat" concern.
///
/// Cancellation: callers cancel the `StreamSubscription` they get back from
/// [sendChat]; exiting the `await for` tears down the underlying request.
@lazySingleton
class RemoteLlmDataSource implements LlmDataSource {
  final UniunRepository _uniun;
  final LlmPreferencesDataSource _prefs;

  /// Every in-flight [generateOneShot] call, tracked independently so
  /// concurrent calls (e.g. Nataraj's background buffer top-up overlapping
  /// a foreground fill) never stomp each other. [preemptBackgroundWork] and
  /// [sendChat] can cancel ALL of them when the user wants the network for
  /// a chat — cancelling now actually resolves each waiting caller
  /// (`Right(null)`) instead of leaving it hanging forever.
  final Set<_InFlightExtraction> _extractions = {};

  RemoteLlmDataSource(this._uniun, this._prefs);

  Future<void> _cancelAllExtractions() async {
    final pending = _extractions.toList();
    _extractions.clear();
    for (final e in pending) {
      await e.cancel();
    }
  }

  @override
  Future<bool> hasActiveModel() async {
    if (!await _uniun.isConnected()) return false;
    return _prefs.activeCloudModelId != null;
  }

  // ── Conversation session ────────────────────────────────────────────────
  // The gateway is stateless — we always send the full prompt.

  @override
  Future<Either<Failure, Unit>> openConversation() async => const Right(unit);

  @override
  Future<Either<Failure, Unit>> closeConversation() async => const Right(unit);

  // ── Streaming chat ──────────────────────────────────────────────────────

  @override
  Stream<String> sendChat({
    required String message,
    String? systemInstruction,
    List<(String, String)> cleanHistory = const [],
    // The gateway takes no images yet; the UI never offers one for a cloud
    // model, so anything passed here is ignored rather than half-sent.
    List<Uint8List> images = const [],
  }) async* {
    // Preempt any in-flight extraction so it doesn't race chat for the
    // user's plan quota.
    await _cancelAllExtractions();

    final modelId = _prefs.activeCloudModelId;
    if (modelId == null) {
      throw const _RemoteLlmException(
        'No cloud model selected. Pick one from the chat input picker.',
      );
    }

    final messages = <Map<String, String>>[
      if (systemInstruction != null && systemInstruction.isNotEmpty)
        {'role': 'system', 'content': systemInstruction},
      for (final (q, a) in cleanHistory) ...[
        {'role': 'user', 'content': q},
        {'role': 'assistant', 'content': a},
      ],
      {'role': 'user', 'content': message},
    ];

    try {
      // `await for` + `yield`, NOT `yield* stream`: an exception thrown by a
      // delegated async* stream is not caught by a `try` wrapping `yield*`.
      await for (final token
          in _uniun.streamChat(modelId: modelId, messages: messages)) {
        yield token;
      }
    } catch (e, st) {
      debugPrint('❌ RemoteLlmDataSource.sendChat failed: $e\n$st');
      rethrow;
    }
  }

  // ── One-shot ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, String?>> generateOneShot({
    required String prompt,
    int maxTokens = 1024,
    LlmTaskKind kind = LlmTaskKind.extract, // no local queue — kind is ignored for remote
    String? modelIdOverride,
  }) async {
    final modelId = modelIdOverride ?? _prefs.activeCloudModelId;
    if (modelId == null) return const Right(null);

    final completer = Completer<String?>();
    final buffer = StringBuffer();
    late final _InFlightExtraction entry;

    // Deliberately does NOT cancel any other in-flight extraction here —
    // this call is itself extraction-tier, not chat, so it must not stomp
    // a sibling Nataraj/Gana call. Only sendChat/preemptBackgroundWork are
    // allowed to cancel extraction-tier work.
    final sub = _uniun
        .streamChat(
          modelId: modelId,
          maxTokens: maxTokens,
          messages: [
            {'role': 'user', 'content': prompt},
          ],
        )
        .listen(
          buffer.write,
          onDone: () {
            if (!completer.isCompleted) completer.complete(buffer.toString());
            _extractions.remove(entry);
          },
          onError: (Object e, StackTrace st) {
            debugPrint('⏭️ RemoteLlmDataSource.generateOneShot error: $e');
            // A genuine stream error, NOT a cooperative cancel — propagate
            // as a real failure (see _InFlightExtraction.cancel for the
            // cancel path) so callers like GanaEngine can tell "failed"
            // apart from "preempted" instead of both reading as null.
            if (!completer.isCompleted) completer.completeError(e, st);
            _extractions.remove(entry);
          },
          cancelOnError: true,
        );
    entry = _InFlightExtraction(sub, completer);
    _extractions.add(entry);

    try {
      final result = await completer.future;
      return Right(result);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  // ── Priority coordination ───────────────────────────────────────────────
  // No queue for cloud — concurrent HTTP is fine. But we DO preempt
  // extraction so we don't burn the user's quota for results they likely
  // won't see while they're chatting.

  @override
  Future<Either<Failure, Unit>> preemptBackgroundWork() async {
    await _cancelAllExtractions();
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> resumeBackgroundWork() async =>
      const Right(unit);

  // ── Model listing ───────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<LlmModelInfo>>> listAvailableModels() =>
      _uniun.listAvailableModels();
}

class _RemoteLlmException implements Exception {
  final String message;
  const _RemoteLlmException(this.message);
  @override
  String toString() => message;
}

/// One [generateOneShot] call's independent subscription + completer.
class _InFlightExtraction {
  _InFlightExtraction(this.sub, this.completer);
  final StreamSubscription<String> sub;
  final Completer<String?> completer;

  /// Cooperative cancel (by us — chat/preempt taking priority). Resolves
  /// as `Right(null)`, same meaning as "preempted, no result yet" today —
  /// distinct from a genuine stream error, which completes with an error
  /// instead (see the `onError` callback in [RemoteLlmDataSource.
  /// generateOneShot]).
  Future<void> cancel() async {
    await sub.cancel();
    if (!completer.isCompleted) completer.complete(null);
  }
}
