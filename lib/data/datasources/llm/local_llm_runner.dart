import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart' hide CancelToken;
import 'package:injectable/injectable.dart';
import 'package:uniun/core/utils/llm_backend.dart';
import 'package:uniun/core/utils/llm_text_sanitizer.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/data/datasources/llm/flutter_gemma_gateway.dart';
import 'package:uniun/data/datasources/llm/inference_scheduler.dart';
import 'package:uniun/data/datasources/llm/local_model_params.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/entities/llm/llm_task_kind.dart';

/// Wraps flutter_gemma 1.x for token-streaming inference.
///
/// Serialization is delegated to [InferenceScheduler] (see
/// `docs/SHIVA/scheduling.md`) — the scheduler picks the next job based on
/// the 5-tier algorithm and signals cooperative cancellation via the
/// [CancelToken] handed to each work closure. The runner is the only place
/// that knows how to translate "cancel" into [InferenceChat.stopGeneration].
///
/// ## Strategy
///
/// - **Chat** opens a throwaway [InferenceChat] per turn via [openChat]. RAG
///   context can change every turn so we don't want stale RAG dumps living in
///   a long-lived chat's history. Re-opening per turn is cheap on 1.x because
///   each `openChat` just spawns a fresh session against the loaded weights.
/// - **One-shot** (extraction / Nataraj / Gana) uses the same `openChat`
///   pattern. The scheduler's [CancelToken] is polled between streamed
///   tokens — on cancel the work calls `stopGeneration()` on its private
///   session and returns null. The caller treats null as "cancelled / no
///   active model"; for `extract`, [ExtractKnowledgeUseCase] retries; for
///   `nataraj` / `gana`, the scheduler itself re-queues the cancelled job.
@lazySingleton
class AIModelRunner {
  final InferenceScheduler _scheduler;
  final AppSettingsStore _settings;
  final FlutterGemmaGateway _gateway;

  /// The model instance last handed out by [_openActiveModel]. Held so a failed
  /// invoke can [_resetModel] it — closing the native model frees its
  /// accumulated sessions/cache so the next open rebuilds a fresh one.
  InferenceModel? _activeModel;

  AIModelRunner(this._scheduler, this._settings, this._gateway);

  /// Stable string id for the currently-active model — handed to the
  /// scheduler so it can apply model-affinity batching across jobs. Falls
  /// back to a sentinel when no model is selected yet (the runner short-
  /// circuits before dispatch in that case, so the value is unused).
  String get _activeModelIdName => _settings.activeModelId?.name ?? '_none_';

  LocalModelParams? get _activeParams =>
      LocalModelParams.forId(_settings.activeModelId);

  /// Backend that actually worked for the current model. We prefer GPU, but
  /// the Metal GPU delegate cannot be applied to every model on every
  /// device — large LiteRT graphs trip Metal's 31-texture-binding limit
  /// ("texture binding ... index 31 that is greater than 30") and the iOS
  /// simulator has no usable GPU delegate at all. On the first GPU failure we
  /// retry on CPU and remember it so later turns skip the doomed GPU attempt.
  /// Reset whenever the active model changes, to re-probe the preferred backend.
  PreferredBackend _backend = preferredLlmBackend;
  AIModelId? _backendForModel;

  /// Whether the cached [_activeModel] was opened with its vision encoder.
  /// Vision is fixed when the engine is created, so a turn carrying an image
  /// needs a model opened for it; text turns work on either kind.
  bool _modelHasVision = false;

  /// Open the active model, falling back GPU → CPU on engine-creation failure.
  ///
  /// With [vision] the model is opened to accept images; flutter_gemma
  /// rebuilds a cached text-only engine itself when `supportImage` differs
  /// (seconds, once). A vision model is then kept for later turns until the
  /// model changes.
  Future<InferenceModel> _openActiveModel(
    int maxTokens, {
    bool vision = false,
  }) async {
    final activeId = _settings.activeModelId;
    if (activeId != _backendForModel) {
      _backendForModel = activeId;
      _backend = preferredLlmBackend;
      _modelHasVision = false;
    }
    final wantVision = vision || _modelHasVision;
    try {
      final model = await _gateway.getActiveModel(
        maxTokens: maxTokens,
        preferredBackend: _backend,
        supportImage: wantVision,
        maxNumImages: wantVision ? 1 : null,
      );
      _modelHasVision = wantVision;
      return _activeModel = model;
    } catch (e) {
      if (_backend == PreferredBackend.cpu) rethrow;
      debugPrint('⚠️ GPU backend failed to open model ($e) — retrying on CPU');
      // Explicit and remembered: a null backend is GPU-then-CPU on LiteRT-LM,
      // so it would repeat the GPU attempt that just failed — on this open and
      // every later one for the same model.
      _backend = PreferredBackend.cpu;
      final model = await _gateway.getActiveModel(
        maxTokens: maxTokens,
        preferredBackend: PreferredBackend.cpu,
        supportImage: wantVision,
        maxNumImages: wantVision ? 1 : null,
      );
      _modelHasVision = wantVision;
      return _activeModel = model;
    }
  }

  /// Close the cached native model so the next [_openActiveModel] rebuilds a
  /// fresh one. Used to recover when an invoke fails after the native runtime
  /// has degraded over many open/close session cycles (common on the
  /// resource-limited iOS simulator). flutter_gemma's close-listener resets its
  /// singleton, so a later getActiveModel re-creates the model.
  Future<void> _resetModel() async {
    final m = _activeModel;
    _activeModel = null;
    _modelHasVision = false;
    if (m == null) return;
    try {
      await m.close();
    } catch (_) {
      // Already closing / closed — fine.
    }
  }

  bool get hasActiveModel => _gateway.hasActiveModel();

  /// Runs [action] (activating or deleting the local model) through the
  /// scheduler so it never races whatever generation is currently in
  /// flight against the native engine.
  ///
  /// [forcePreempt] false (a plain model switch): waits for the current
  /// job to finish naturally, then runs ahead of anything else queued.
  /// [forcePreempt] true (deleting the active model — can't wait for the
  /// file to be safe to remove): cancels whatever's running immediately.
  /// Nataraj/Gana recover for free via the scheduler's existing re-queue
  /// policy; a cancelled chat turn finalizes with its partial content,
  /// same as the Stop button.
  Future<T> runExclusiveModelOperation<T>({
    required bool forcePreempt,
    required Future<T> Function() action,
  }) {
    return _scheduler.run<T>(
      kind: LlmTaskKind.modelSwitch,
      modelId: '_modelSwitch_',
      forcePreempt: forcePreempt,
      work: (_) async {
        await _resetModel();
        return action();
      },
    );
  }

  /// Validate that a model is active before a conversation opens. The runner
  /// holds NO per-conversation state — the system instruction is passed into
  /// [sendAndStream] per turn so independent chat surfaces (e.g. the Shiv tab
  /// and an inline composer chat) can't clobber each other.
  Future<void> initChat() async {
    if (!_gateway.hasActiveModel()) {
      throw StateError('No AI model is active. Please select a model first.');
    }
  }

  /// Send the current user [message] (question + RAG context if any) and
  /// stream text tokens back.
  ///
  /// [cleanHistory] is the previous turns of this conversation as bare
  /// (user, assistant) text pairs — no RAG, no system prompt. They are
  /// replayed into the freshly-opened chat so the model has continuity
  /// without the bloat.
  Stream<String> sendAndStream(
    String message, {
    required String systemInstruction,
    List<(String, String)> cleanHistory = const [],
    List<Uint8List> images = const [],
  }) async* {
    if (!_gateway.hasActiveModel()) {
      throw StateError('No AI model is active. Please select a model first.');
    }

    final tokens = StreamController<String>();

    // Submit via the scheduler at T0 (chat). The scheduler is responsible
    // for preempting any in-flight lower-tier job (extract / nataraj /
    // gana) at the next token boundary — see docs/SHIVA/scheduling.md.
    final running = _scheduler.run<void>(
      kind: LlmTaskKind.chat,
      modelId: _activeModelIdName,
      work: (cancel) async {
        InferenceChat? chat;
        try {
          final params = _activeParams;
          final model = await _openActiveModel(
            params?.maxTokens ?? 4096,
            vision: images.isNotEmpty,
          );
          _scheduler.notifyLoadedModel(_activeModelIdName);
          chat = await model.openChat(
            temperature: 0.8,
            topK: 40,
            tokenBuffer: 512,
            modelType: params?.modelType,
            isThinking: params?.isThinking ?? false,
            // Unset for a text turn, exactly as before images existed.
            supportImage: images.isEmpty ? null : true,
          );

          final prompt = _composePrompt(
            systemInstruction: systemInstruction,
            cleanHistory: cleanHistory,
            currentMessage: message,
            historyBudget: _historyBudgetTokens(params),
          );

          // isUser stays false: we hand the plugin a complete prompt. With
          // true it appends ` /no_think` for Qwen3, landing after our `Shiv:`
          // cue, and the model copies that pattern into its reply (#220).
          await chat.addQueryChunk(
            images.isEmpty
                ? Message.text(text: prompt)
                : Message.withImage(text: prompt, imageBytes: images.first),
          );
          final scrubber = _StopTokenScrubber();
          await for (final response in chat.generateChatResponseAsync()) {
            if (cancel.isCancelled) {
              await chat.stopGeneration();
              break;
            }
            if (response is TextResponse && response.token.isNotEmpty) {
              final safe = scrubber.feed(response.token);
              if (safe != null) tokens.add(safe);
              if (scrubber.isDone) break;
            }
          }
          final tail = scrubber.flush();
          if (tail != null) tokens.add(tail);
        } catch (e, st) {
          tokens.addError(e, st);
        } finally {
          await chat?.close();
          await tokens.close();
        }
      },
    );

    unawaited(running.catchError((_) {}));
    yield* tokens.stream;
  }

  /// No-op: chat opens a throwaway session per turn, so there is no long-lived
  /// per-conversation state to tear down. Kept for the datasource lifecycle.
  Future<void> close() async {}

  /// Stateless one-shot completion routed through [InferenceScheduler].
  ///
  /// [kind] picks the tier (see `docs/SHIVA/scheduling.md` §3).
  /// Returns `null` if preempted at a token boundary or if no model is
  /// active — callers must tolerate null.
  Future<String?> generateOneShot(
    String prompt, {
    int maxTokens = 1024,
    LlmTaskKind kind = LlmTaskKind.extract,
  }) async {
    if (!_gateway.hasActiveModel()) {
      debugPrint('⏭️ generateOneShot: no active model');
      return null;
    }
    try {
      return await _scheduler.run<String?>(
        kind: kind,
        modelId: _activeModelIdName,
        work: (cancel) => _doGenerateOneShot(prompt, maxTokens, cancel),
      );
    } catch (e, st) {
      debugPrint('⏭️ generateOneShot failed: $e\n$st');
      return null;
    }
  }

  Future<String?> _doGenerateOneShot(
    String prompt,
    int maxTokens,
    CancelToken cancel,
  ) async {
    final (result, ok) = await _attemptOneShot(prompt, maxTokens, cancel);
    if (ok || cancel.isCancelled) return result;
    // The invoke failed (not a cancel). After many open/close session cycles
    // the native runtime can degrade — invoke starts failing even though it
    // worked moments ago (seen heavily on the resource-limited iOS simulator).
    // Drop the cached model so a fresh one is rebuilt, then retry once.
    debugPrint('⚠️ generateOneShot: invoke failed — resetting model + retry');
    await _resetModel();
    final (retryResult, _) = await _attemptOneShot(prompt, maxTokens, cancel);
    return retryResult;
  }

  /// One open → generate → close attempt. Returns `(text, true)` on success
  /// or `(null, false)` when the native invoke threw / was cancelled, so the
  /// caller can decide whether to reset the model and retry.
  Future<(String?, bool)> _attemptOneShot(
    String prompt,
    int maxTokens,
    CancelToken cancel,
  ) async {
    InferenceChat? oneShot;
    try {
      debugPrint('🧪 generateOneShot: opening throwaway chat…');
      final params = _activeParams;
      // Open at the model's baked-in KV-cache size (see [LocalModelParams.
      // maxTokens]) — exactly like chat does. It is NOT a free choice: opening
      // SMALLER than the baked size (e.g. a caller's 512) makes the compiled
      // graph fail at invoke ("Failed to invoke the compiled model"), which
      // strands the Nataraj deck. The requested [maxTokens] is only a fallback
      // for an unknown model with no params.
      final cacheSize = params?.maxTokens ?? maxTokens;
      final model = await _openActiveModel(cacheSize);
      _scheduler.notifyLoadedModel(_activeModelIdName);
      oneShot = await model.openChat(
        temperature: 0.2,
        topK: 20,
        tokenBuffer: 256,
        modelType: params?.modelType,
        isThinking: params?.isThinking ?? false,
      );

      // isUser stays false — see the note in sendAndStream.
      await oneShot.addQueryChunk(Message.text(text: prompt));
      final buffer = StringBuffer();
      final scrubber = _StopTokenScrubber();
      await for (final response in oneShot.generateChatResponseAsync()) {
        if (cancel.isCancelled) {
          await oneShot.stopGeneration();
          break;
        }
        if (response is TextResponse) {
          final safe = scrubber.feed(response.token);
          if (safe != null) buffer.write(safe);
          if (scrubber.isDone) break;
        }
      }
      final tail = scrubber.flush();
      if (tail != null) buffer.write(tail);
      // Sanitize once on the full buffer — strips tool-call envelopes,
      // BPE `Ġ` markers, and repairs Latin-1-encoded UTF-8 mojibake
      // (e.g. emojis arriving as `ðŁĮ±`). Mojibake repair MUST run on the
      // whole string, not per-chunk, or we'd split UTF-8 byte sequences.
      final cleaned = LlmTextSanitizer.clean(buffer.toString());
      debugPrint('🧪 generateOneShot: done (${cleaned.length} chars)');
      return (cleaned, !cancel.isCancelled);
    } catch (e, st) {
      debugPrint('⏭️ generateOneShot attempt failed: $e\n$st');
      return (null, false);
    } finally {
      try {
        await oneShot?.close();
      } catch (_) {
        // Safe to ignore — session may already be in a closing state.
      }
    }
  }

  /// Build the per-turn prompt: persona/system + clean history + new turn.
  ///
  /// Format keeps it explicit so the model knows turn boundaries:
  ///   <system>
  ///   User: <q1>
  ///   Assistant: <a1>
  ///   User: <q2>
  ///   Assistant: <a2>
  ///   <current message, which already contains RAG + question>
  String _composePrompt({
    required String systemInstruction,
    required List<(String, String)> cleanHistory,
    required String currentMessage,
    required int historyBudget,
  }) {
    final buf = StringBuffer();
    buf.write(systemInstruction);
    if (!systemInstruction.endsWith('\n')) buf.writeln();

    final kept = _trimHistory(cleanHistory, historyBudget);
    for (final (q, a) in kept) {
      buf.writeln();
      buf.writeln('User: $q');
      buf.writeln('Assistant: $a');
    }
    buf.writeln();
    buf.write(currentMessage);
    return buf.toString();
  }

  int _historyBudgetTokens(LocalModelParams? params) {
    final max = params?.maxTokens ?? 1024;
    return (max * 0.20).round();
  }

  List<(String, String)> _trimHistory(
    List<(String, String)> history,
    int budgetTokens,
  ) {
    if (history.isEmpty || budgetTokens <= 0) return const [];
    final kept = <(String, String)>[];
    int used = 0;
    for (final pair in history.reversed) {
      final line = 'User: ${pair.$1}\nAssistant: ${pair.$2}\n';
      final cost = (line.length / 4).ceil();
      if (used + cost > budgetTokens) break;
      kept.insert(0, pair);
      used += cost;
    }
    return kept;
  }
}

/// Strips per-model stop tokens from a streaming token feed.
///
/// flutter_gemma 0.16.5's [StopTokenFilter] only matches `<end_of_turn>` (Gemma).
/// On iOS the MediaPipe `.litertlm` backend does not honour stop tokens itself,
/// so non-Gemma models (Qwen, DeepSeek, Llama) leak their terminator plus BPE
/// byte-level junk after it. We catch the rest here. Safe on Android too —
/// these tokens simply never appear there.
class _StopTokenScrubber {
  static const _stopTokens = <String>[
    '<|im_end|>', // Qwen
    '<|endoftext|>', // Qwen / GPT-style alt
    '<end_of_turn>', // Gemma (already filtered upstream; harmless)
    '<｜end▁of▁sentence｜>', // DeepSeek (full-width pipes + underscores)
    '<|eot_id|>', // Llama 3
  ];

  String _buffer = '';
  bool _done = false;

  bool get isDone => _done;

  String? feed(String chunk) {
    if (_done) return null;
    _buffer += chunk;

    int earliest = -1;
    for (final s in _stopTokens) {
      final i = _buffer.indexOf(s);
      if (i >= 0 && (earliest < 0 || i < earliest)) earliest = i;
    }
    if (earliest >= 0) {
      final out = _buffer.substring(0, earliest);
      _buffer = '';
      _done = true;
      return out.isEmpty ? null : out;
    }

    // Hold back any tail that could be the start of a stop token spanning
    // the next chunk.
    int hold = 0;
    for (final s in _stopTokens) {
      final maxI = s.length - 1 < _buffer.length
          ? s.length - 1
          : _buffer.length;
      for (int i = 1; i <= maxI; i++) {
        if (_buffer.endsWith(s.substring(0, i)) && i > hold) hold = i;
      }
    }

    if (hold == 0) {
      final out = _buffer;
      _buffer = '';
      return out.isEmpty ? null : out;
    }
    final out = _buffer.substring(0, _buffer.length - hold);
    _buffer = _buffer.substring(_buffer.length - hold);
    return out.isEmpty ? null : out;
  }

  String? flush() {
    if (_done || _buffer.isEmpty) return null;
    final out = _buffer;
    _buffer = '';
    return out;
  }
}
