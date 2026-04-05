import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';

abstract class AIModelRepository {
  /// Returns the hardcoded catalog of models available for download.
  List<AIModelEntity> getAvailableModels();

  /// Returns the model the user has downloaded and activated, or null if none.
  Future<Either<Failure, AIModelEntity?>> getActiveModel();

  /// Downloads the model identified by [modelId] and marks it as active.
  /// Emits [AIModelDownloadEvent]s until complete or failed.
  Stream<AIModelDownloadEvent> downloadAndActivateModel(AIModelId modelId);

  /// Removes the active model selection (does not delete the file).
  Future<Either<Failure, Unit>> clearActiveModel();
}
