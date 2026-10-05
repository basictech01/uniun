import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';

part 'llm_model_info.freezed.dart';

/// Backend-agnostic description of a single LLM model.
///
/// Local Gemma models map onto this via [AIModelRepository] (Phase 1: only
/// the active local model is exposed). Cloud models map onto this from
/// the UNIUN gateway catalog.
@freezed
abstract class LlmModelInfo with _$LlmModelInfo {
  const factory LlmModelInfo({
    /// Stable identifier. For local: `AIModelId.name` (e.g. `gemma4E2b`).
    /// For cloud: the gateway model id (e.g. `claude-sonnet-5`).
    required String id,
    required String displayName,
    required LlmBackendType backend,

    /// Context window in tokens. Drives the prompt budget. 0 = unknown.
    @Default(0) int contextWindow,

    /// USD per million input tokens. Null for local models.
    double? pricePerMillionInput,

    /// USD per million output tokens. Null for local models.
    double? pricePerMillionOutput,

    /// Whether the model accepts an image alongside the text of a chat turn.
    /// Drives whether Shiv's input offers to attach one.
    @Default(false) bool supportsImages,
  }) = _LlmModelInfo;
}
