import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/data/datasources/llm/llm_data_source.dart';
import 'package:uniun/data/datasources/llm/llm_preferences_data_source.dart';
import 'package:uniun/data/datasources/llm/local_llm_data_source.dart';
import 'package:uniun/data/datasources/llm/remote_llm_data_source.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/domain/entities/llm/llm_model_info.dart';
import 'package:uniun/domain/entities/llm/llm_task_kind.dart';
import 'package:uniun/domain/repositories/ai_model_repository.dart';
import 'package:uniun/domain/repositories/llm_repository.dart';
import 'package:uniun/domain/repositories/uniun_repository.dart';

/// Dispatches calls to the data source matching the user's active backend.
@Injectable(as: LlmRepository)
class LlmRepositoryImpl implements LlmRepository {
  final LocalLlmDataSource _local;
  final RemoteLlmDataSource _remote;
  final LlmPreferencesDataSource _prefs;
  final UniunRepository _cloudAuth;
  final AppSettingsStore _localSettings;
  final AIModelRepository _localCatalog;

  LlmRepositoryImpl(
    this._local,
    this._remote,
    this._prefs,
    this._cloudAuth,
    this._localSettings,
    this._localCatalog,
  );

  LlmDataSource get _active {
    switch (_prefs.activeBackend) {
      case LlmBackendType.localGemma:
        return _local;
      case LlmBackendType.uniunCloud:
        return _remote;
    }
  }

  @override
  Future<bool> hasActiveModel() => _active.hasActiveModel();

  @override
  Future<Either<Failure, Unit>> openConversation() =>
      _active.openConversation();

  @override
  Future<Either<Failure, Unit>> closeConversation() =>
      _active.closeConversation();

  @override
  Stream<String> sendChat({
    required String message,
    String? systemInstruction,
    List<(String, String)> cleanHistory = const [],
    List<Uint8List> images = const [],
  }) =>
      _active.sendChat(
        message: message,
        systemInstruction: systemInstruction,
        cleanHistory: cleanHistory,
        images: images,
      );

  @override
  Future<Either<Failure, String?>> generateOneShot({
    required String prompt,
    int maxTokens = 1024,
    LlmTaskKind kind = LlmTaskKind.extract,
    LlmBackendType? backendOverride,
    String? modelIdOverride,
  }) {
    final target = switch (backendOverride) {
      null => _active,
      LlmBackendType.localGemma => _local,
      LlmBackendType.uniunCloud => _remote,
    };
    return target.generateOneShot(
      prompt: prompt,
      maxTokens: maxTokens,
      kind: kind,
      modelIdOverride: modelIdOverride,
    );
  }

  @override
  Future<Either<Failure, Unit>> preemptBackgroundWork() =>
      _active.preemptBackgroundWork();

  @override
  Future<Either<Failure, Unit>> resumeBackgroundWork() =>
      _active.resumeBackgroundWork();

  @override
  Future<Either<Failure, LlmBackendType>> getActiveBackend() async =>
      Right(_prefs.activeBackend);

  @override
  Future<Either<Failure, Unit>> setActiveBackend(LlmBackendType backend) async {
    if (backend == LlmBackendType.uniunCloud) {
      // Silent keypair login: first switch auto-creates the gateway account.
      final result = await _cloudAuth.connect();
      if (result.isLeft()) return result;
    }
    await _prefs.setActiveBackend(backend);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<LlmModelInfo>>> listAvailableModels() =>
      _active.listAvailableModels();

  @override
  Future<Either<Failure, List<LlmModelInfo>>> listCloudModels() =>
      _remote.listAvailableModels();

  @override
  Future<Either<Failure, Unit>> setActiveModel(String modelId) async {
    try {
      switch (_prefs.activeBackend) {
        case LlmBackendType.localGemma:
          // Map the string id back to AIModelId. If unknown, surface a clear
          // error rather than silently writing junk.
          final id = AIModelId.values
              .where((v) => v.name == modelId)
              .firstOrNull;
          if (id == null) {
            return Left(Failure.errorFailure('Unknown local model: $modelId'));
          }
          await _localSettings.setActiveModelId(id);
          // Re-link flutter_gemma to the newly picked model right away.
          // Without this, switching between two ALREADY-downloaded local
          // models leaves flutter_gemma's native engine pointed at the old
          // one — hasActiveModel() stays true (so model gates don't catch
          // it), but the next generation runs against the wrong weights/
          // KV-cache size, which is what surfaced as "model error" (#160).
          return _localCatalog.activateModel(id);
        case LlmBackendType.uniunCloud:
          await _prefs.setActiveCloudModelId(modelId);
          return const Right(unit);
      }
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LlmModelInfo?>> getActiveModel() async {
    try {
      switch (_prefs.activeBackend) {
        case LlmBackendType.localGemma:
          final result = await _localCatalog.getActiveModel();
          return result.fold(Left.new, (entity) {
            if (entity == null) return const Right(null);
            return Right(LlmModelInfo(
              id: entity.modelId.name,
              displayName: entity.modelId.name,
              backend: LlmBackendType.localGemma,
              supportsImages: entity.modelId.supportsImages,
            ));
          });
        case LlmBackendType.uniunCloud:
          final id = _prefs.activeCloudModelId;
          if (id == null) return const Right(null);
          // We don't have a cached catalog entry; surface a minimal info
          // (id == displayName). UI calls listAvailableModels for full info.
          return Right(LlmModelInfo(
            id: id,
            displayName: id,
            backend: LlmBackendType.uniunCloud,
          ));
      }
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
