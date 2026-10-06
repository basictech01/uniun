import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_model_entity.freezed.dart';

// ── Model ID ──────────────────────────────────────────────────────────────────
// Typed enum instead of raw strings — all layers use this.

enum AIModelId {
  qwen25_05b,
  deepseekR1,
  gemma4E2b,
  gemma4E4b,
}

/// What a catalog model can take as input, beyond text.
///
/// One place that says so, so the UI and the engine ask the same question
/// instead of each guessing from a model's name. Of the four models UNIUN
/// ships, only the Gemma 4 pair has a vision encoder (flutter_gemma 1.8.3);
/// Qwen3 and DeepSeek R1 are text-only.
extension AIModelIdCapabilities on AIModelId {
  bool get supportsImages => switch (this) {
    AIModelId.gemma4E2b || AIModelId.gemma4E4b => true,
    AIModelId.qwen25_05b || AIModelId.deepseekR1 => false,
  };
}

// ── Supporting enums ──────────────────────────────────────────────────────────

enum AIModelTier { lite, balanced, performance, flagship }

enum AIModelOptimization { cpu, gpuCpu, gpu }

// ── Entity ────────────────────────────────────────────────────────────────────
// displayName and description are intentionally absent — they are UI strings
// and must come from AppLocalizations in the presentation layer via AIModelId.

@freezed
abstract class AIModelEntity with _$AIModelEntity {
  const factory AIModelEntity({
    required AIModelId modelId,
    /// Human-readable size string e.g. "586 MB", "1.7 GB".
    required String sizeLabel,
    required int sizeBytes,
    required AIModelTier tier,
    required bool isRecommended,
    required AIModelOptimization optimization,
    /// Remote URL to download the model file.
    required String downloadUrl,
    @Default(false) bool isDownloaded,
  }) = _AIModelEntity;
}

// ── Download event ────────────────────────────────────────────────────────────

@freezed
abstract class AIModelDownloadEvent with _$AIModelDownloadEvent {
  /// Progress value from 0.0 to 1.0.
  const factory AIModelDownloadEvent.progress(double value) =
      AIModelDownloadProgress;

  /// Download finished — modelId identifies the installed model.
  const factory AIModelDownloadEvent.complete(AIModelId modelId) =
      AIModelDownloadComplete;

  const factory AIModelDownloadEvent.failed(String message) =
      AIModelDownloadFailed;
}
