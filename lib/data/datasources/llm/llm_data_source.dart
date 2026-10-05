import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/llm/llm_model_info.dart';
import 'package:uniun/domain/entities/llm/llm_task_kind.dart';

/// Per-backend inference contract. One impl per backend
/// ([LocalLlmDataSource], [RemoteLlmDataSource]). The Repository owns
/// backend selection and dispatches to one of these.
abstract class LlmDataSource {
  /// True if this backend is ready to serve inference.
  /// Local: a Gemma model is installed.
  /// Remote: an API key is configured.
  Future<bool> hasActiveModel();

  /// Validate / open a conversation session (local: model-active check;
  /// remote: no-op). Holds NO per-conversation state — the system instruction
  /// rides on each [sendChat] turn so independent chat surfaces don't clobber.
  Future<Either<Failure, Unit>> openConversation();

  /// Tear down the conversation context.
  Future<Either<Failure, Unit>> closeConversation();

  /// Stream tokens for a chat turn. [systemInstruction] is passed per turn
  /// (persona + any branch/seed context) rather than stored on the backend.
  Stream<String> sendChat({
    required String message,
    String? systemInstruction,
    List<(String, String)> cleanHistory = const [],
    List<Uint8List> images = const [],
  });

  /// One-shot completion. [kind] drives scheduler tier on the local backend
  /// (see `docs/SHIVA/scheduling.md`); ignored by the cloud backend which
  /// is network-concurrent. [modelIdOverride] picks a specific model for
  /// just this call; the local data source ignores it (no per-call swap).
  Future<Either<Failure, String?>> generateOneShot({
    required String prompt,
    int maxTokens = 1024,
    LlmTaskKind kind = LlmTaskKind.extract,
    String? modelIdOverride,
  });

  /// Backend-specific coordination — local pauses its low-priority queue;
  /// remote is naturally parallel so this is a no-op.
  Future<Either<Failure, Unit>> preemptBackgroundWork();

  Future<Either<Failure, Unit>> resumeBackgroundWork();

  Future<Either<Failure, List<LlmModelInfo>>> listAvailableModels();
}
