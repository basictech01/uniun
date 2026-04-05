import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/ai_model_selection_model.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/repositories/ai_model_repository.dart';
import 'package:path/path.dart' as p;

@Injectable(as: AIModelRepository)
class AIModelRepositoryImpl implements AIModelRepository {
  final Isar _isar;

  AIModelRepositoryImpl(this._isar);

  // ── Model catalog ────────────────────────────────────────────────────────────
  // All URLs are real HuggingFace releases compatible with flutter_gemma 0.13.x
  // on Android and iOS (no auth token required).
  //
  // Mobile file format rules:
  //  .task      → MediaPipe LiteRT engine (Android + iOS)
  //  .litertlm  → LiteRT-LM engine       (Android + iOS + Desktop)
  //
  // Gemma 4 E2B/E4B use .litertlm (LiteRT-LM). All others use .task.

  static const _catalog = [
    (
      modelId: AIModelId.qwen25_05b,
      sizeLabel: '0.5 GB',
      sizeBytes: 536870912,
      tier: AIModelTier.lite,
      isRecommended: false,
      optimization: AIModelOptimization.cpu,
      modelType: ModelType.qwen,
      fileType: ModelFileType.task,
      // No HuggingFace token required — public litert-community repo.
      downloadUrl:
          'https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280.task',
    ),
    (
      modelId: AIModelId.deepseekR1,
      sizeLabel: '1.7 GB',
      sizeBytes: 1825964032,
      tier: AIModelTier.balanced,
      isRecommended: true,
      optimization: AIModelOptimization.cpu,
      modelType: ModelType.deepSeek,
      fileType: ModelFileType.task,
      // No HuggingFace token required — public litert-community repo.
      downloadUrl:
          'https://huggingface.co/litert-community/DeepSeek-R1-Distill-Qwen-1.5B/resolve/main/deepseek_q8_ekv1280.task',
    ),
    (
      modelId: AIModelId.gemma4E2b,
      sizeLabel: '2.4 GB',
      sizeBytes: 2576980377,
      tier: AIModelTier.performance,
      isRecommended: false,
      optimization: AIModelOptimization.gpuCpu,
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.litertlm,
      // No HuggingFace token required — public litert-community repo.
      downloadUrl:
          'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
    ),
    (
      modelId: AIModelId.gemma4E4b,
      sizeLabel: '4.3 GB',
      sizeBytes: 4617089638,
      tier: AIModelTier.flagship,
      isRecommended: false,
      optimization: AIModelOptimization.gpu,
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.litertlm,
      // No HuggingFace token required — public litert-community repo.
      downloadUrl:
          'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm',
    ),
  ];

  @override
  List<AIModelEntity> getAvailableModels() {
    return _catalog
        .map((m) => AIModelEntity(
              modelId: m.modelId,
              sizeLabel: m.sizeLabel,
              sizeBytes: m.sizeBytes,
              tier: m.tier,
              isRecommended: m.isRecommended,
              optimization: m.optimization,
              downloadUrl: m.downloadUrl,
            ))
        .toList();
  }

  // ── Active model ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AIModelEntity?>> getActiveModel() async {
    try {
      final row = await _isar.aIModelSelectionModels
          .filter()
          .isActiveEqualTo(true)
          .findFirst();

      if (row == null) return const Right(null);

      final entry =
          _catalog.where((m) => m.modelId == row.modelId).firstOrNull;
      if (entry == null) return const Right(null);

      // Derive the filename flutter_gemma uses — basename of the download URL.
      final filename = p.basename(Uri.parse(entry.downloadUrl).path);
      final isInstalled = await FlutterGemma.isModelInstalled(filename);

      if (!isInstalled) {
        // Files cleared (app reinstall / storage wipe) — reset Isar record.
        await clearActiveModel();
        return const Right(null);
      }

      // Restore flutter_gemma's in-memory active model state.
      // install() is a no-op when already installed — just re-sets active.
      if (!FlutterGemma.hasActiveModel()) {
        await FlutterGemma.installModel(
          modelType: entry.modelType,
          fileType: entry.fileType,
        ).fromNetwork(entry.downloadUrl).install();
      }

      return Right(AIModelEntity(
        modelId: entry.modelId,
        sizeLabel: entry.sizeLabel,
        sizeBytes: entry.sizeBytes,
        tier: entry.tier,
        isRecommended: entry.isRecommended,
        optimization: entry.optimization,
        downloadUrl: entry.downloadUrl,
        isDownloaded: true,
      ));
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearActiveModel() async {
    try {
      await _isar.writeTxn(() async {
        final rows = await _isar.aIModelSelectionModels
            .filter()
            .isActiveEqualTo(true)
            .findAll();
        for (final row in rows) {
          row.isActive = false;
          await _isar.aIModelSelectionModels.put(row);
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  // ── Download ─────────────────────────────────────────────────────────────────

  @override
  Stream<AIModelDownloadEvent> downloadAndActivateModel(
      AIModelId modelId) async* {
    final entry =
        _catalog.where((m) => m.modelId == modelId).firstOrNull;
    if (entry == null) {
      yield AIModelDownloadEvent.failed('Unknown model: ${modelId.name}');
      return;
    }

    // Bridge flutter_gemma's progress callback to our stream.
    final progressController = StreamController<int>();

    FlutterGemma.installModel(
      modelType: entry.modelType,
      fileType: entry.fileType,
    )
        .fromNetwork(entry.downloadUrl)
        .withProgress((percent) {
          if (!progressController.isClosed) progressController.add(percent);
        })
        .install()
        .then((_) {
          if (!progressController.isClosed) progressController.close();
        })
        .catchError((Object e) {
          if (!progressController.isClosed) {
            progressController.addError(e);
            progressController.close();
          }
        });

    try {
      await for (final percent in progressController.stream) {
        yield AIModelDownloadEvent.progress(percent / 100.0);
      }
    } catch (e) {
      yield AIModelDownloadEvent.failed(e.toString());
      return;
    }

    // install() completed — persist selection to Isar.
    try {
      await _isar.writeTxn(() async {
        final existing = await _isar.aIModelSelectionModels
            .filter()
            .isActiveEqualTo(true)
            .findAll();
        for (final row in existing) {
          row.isActive = false;
          await _isar.aIModelSelectionModels.put(row);
        }

        final prev = await _isar.aIModelSelectionModels
            .filter()
            .modelIdEqualTo(modelId)
            .findFirst();

        final model = prev ?? AIModelSelectionModel();
        model.modelId = modelId;
        model.modelName = modelId.name;
        model.modelPath = modelId.name; // flutter_gemma manages file storage
        model.downloadedAt = DateTime.now();
        model.isActive = true;
        await _isar.aIModelSelectionModels.put(model);
      });

      yield AIModelDownloadEvent.complete(modelId);
    } catch (e) {
      yield AIModelDownloadEvent.failed(e.toString());
    }
  }
}
