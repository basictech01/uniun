import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/datasources/llm/inference_scheduler.dart';
import 'package:uniun/data/datasources/llm/llm_data_source.dart';
import 'package:uniun/data/datasources/llm/local_llm_runner.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/domain/entities/llm/llm_model_info.dart';
import 'package:uniun/domain/entities/llm/llm_task_kind.dart';
import 'package:uniun/domain/repositories/ai_model_repository.dart';

/// On-device flutter_gemma backend.
///
/// Wraps [AIModelRunner] (token streaming + one-shot) and the
/// [InferenceScheduler] (5-tier priority + CFS fair pool + EDF deadlines —
/// see `docs/SHIVA/scheduling.md`). The runner submits each job to the
/// scheduler; this data source's role is the foreground hint coordination
/// for the chat lifecycle.
///
/// Registered as a concrete type rather than `as: LlmDataSource` so the
/// repository can hold both [LocalLlmDataSource] and [RemoteLlmDataSource]
/// without needing `@Named` qualifiers.
@lazySingleton
class LocalLlmDataSource implements LlmDataSource {
  final AIModelRunner _runner;
  final InferenceScheduler _scheduler;
  final AIModelRepository _modelCatalog;

  LocalLlmDataSource(this._runner, this._scheduler, this._modelCatalog);

  @override
  Future<bool> hasActiveModel() async => _runner.hasActiveModel;

  // ── Conversation session ────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> openConversation() async {
    try {
      // Validate a model is active. The system instruction is no longer stored
      // here — it rides on each [sendChat] turn (see [LlmDataSource.sendChat]).
      await _runner.initChat();
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> closeConversation() async {
    try {
      await _runner.close();
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  // ── Per-turn streaming ──────────────────────────────────────────────────

  @override
  Stream<String> sendChat({
    required String message,
    String? systemInstruction,
    List<(String, String)> cleanHistory = const [],
    List<Uint8List> images = const [],
  }) {
    return _runner.sendAndStream(
      message,
      systemInstruction: systemInstruction ?? '',
      cleanHistory: cleanHistory,
      images: images,
    );
  }

  // ── Background one-shot ─────────────────────────────────────────────────

  @override
  Future<Either<Failure, String?>> generateOneShot({
    required String prompt,
    int maxTokens = 1024,
    LlmTaskKind kind = LlmTaskKind.extract,
    String? modelIdOverride,
  }) async {
    try {
      final result = await _runner.generateOneShot(
        prompt,
        maxTokens: maxTokens,
        kind: kind,
      );
      return Right(result);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  // ── Foreground coordination ─────────────────────────────────────────────
  //
  // The historical `preemptBackgroundWork` / `resumeBackgroundWork` pair is
  // routed through the scheduler's `setForeground` knob: entering Shiv chat
  // means "user is here, chat is foreground" (T0 already preempts), leaving
  // clears the foreground hint. For non-chat foreground surfaces (Nataraj
  // deck, Gana form), callers go through SchedulerCoordinator directly.

  @override
  Future<Either<Failure, Unit>> preemptBackgroundWork() async {
    _scheduler.setForeground(LlmTaskKind.chat);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> resumeBackgroundWork() async {
    _scheduler.setForeground(null);
    return const Right(unit);
  }

  // ── Model listing ───────────────────────────────────────────────────────

  /// For local, the "available models" are the downloaded ones. UI uses
  /// [AIModelRepository] directly for the catalog/download flow; this is
  /// here so the cross-backend picker can list a unified view.
  @override
  Future<Either<Failure, List<LlmModelInfo>>> listAvailableModels() async {
    try {
      final catalog = await _modelCatalog.getAvailableModels();
      final downloaded = await _modelCatalog.getDownloadedModelIds();
      final infos = catalog
          .where((m) => downloaded.contains(m.modelId))
          .map((m) => LlmModelInfo(
                id: m.modelId.name,
                displayName: _displayNameForLocal(m.modelId),
                backend: LlmBackendType.localGemma,
                supportsImages: m.modelId.supportsImages,
              ))
          .toList();
      return Right(infos);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  /// Fallback display name. UI layers should still prefer
  /// `AppLocalizations` keyed off [AIModelId].
  String _displayNameForLocal(AIModelId id) {
    switch (id) {
      case AIModelId.qwen25_05b:
        return 'Qwen3 0.6B';
      case AIModelId.deepseekR1:
        return 'DeepSeek R1 1.5B';
      case AIModelId.gemma4E2b:
        return 'Gemma 4 E2B';
      case AIModelId.gemma4E4b:
        return 'Gemma 4 E4B';
    }
  }
}
