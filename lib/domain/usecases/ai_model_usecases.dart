import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/repositories/ai_model_repository.dart';

// ── GetAvailableAIModelsUseCase ───────────────────────────────────────────────

@lazySingleton
class GetAvailableAIModelsUseCase {
  final AIModelRepository _repository;
  const GetAvailableAIModelsUseCase(this._repository);

  List<AIModelEntity> call() => _repository.getAvailableModels();
}

// ── GetActiveAIModelUseCase ───────────────────────────────────────────────────

@lazySingleton
class GetActiveAIModelUseCase
    extends NoParamsUseCase<Either<Failure, AIModelEntity?>> {
  final AIModelRepository _repository;
  const GetActiveAIModelUseCase(this._repository);

  @override
  Future<Either<Failure, AIModelEntity?>> call() =>
      _repository.getActiveModel();
}

// ── DownloadAndActivateAIModelUseCase ─────────────────────────────────────────

@lazySingleton
class DownloadAndActivateAIModelUseCase
    extends StreamUseCase<AIModelDownloadEvent, AIModelId> {
  final AIModelRepository _repository;
  const DownloadAndActivateAIModelUseCase(this._repository);

  @override
  Stream<AIModelDownloadEvent> call(AIModelId modelId) =>
      _repository.downloadAndActivateModel(modelId);
}

// ── ClearActiveAIModelUseCase ─────────────────────────────────────────────────

@lazySingleton
class ClearActiveAIModelUseCase
    extends NoParamsUseCase<Either<Failure, Unit>> {
  final AIModelRepository _repository;
  const ClearActiveAIModelUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call() => _repository.clearActiveModel();
}
