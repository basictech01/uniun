import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/domain/entities/llm/llm_model_info.dart';
import 'package:uniun/domain/entities/llm/llm_task_kind.dart';
import 'package:uniun/domain/repositories/llm_repository.dart';
import 'package:uniun/domain/repositories/uniun_repository.dart';
import 'package:uniun/core/i18n/translation_language.dart';
import 'package:uniun/core/utils/llm_text_sanitizer.dart';
import 'package:uniun/features/shiv/generation/prompt/translation_prompt.dart';

// ── Capability ────────────────────────────────────────────────────────────────

@lazySingleton
class HasActiveLlmModelUseCase extends NoParamsUseCase<bool> {
  final LlmRepository _repo;
  const HasActiveLlmModelUseCase(this._repo);

  @override
  Future<bool> call() => _repo.hasActiveModel();
}

// ── Session lifecycle ─────────────────────────────────────────────────────────

@lazySingleton
class OpenLlmConversationUseCase
    extends NoParamsUseCase<Either<Failure, Unit>> {
  final LlmRepository _repo;
  const OpenLlmConversationUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call() => _repo.openConversation();
}

@lazySingleton
class CloseLlmConversationUseCase
    extends NoParamsUseCase<Either<Failure, Unit>> {
  final LlmRepository _repo;
  const CloseLlmConversationUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call() => _repo.closeConversation();
}

// ── Streaming chat ────────────────────────────────────────────────────────────

class SendChatStreamInput {
  const SendChatStreamInput({
    required this.message,
    this.systemInstruction,
    this.cleanHistory = const [],
    this.images = const [],
  });
  final String message;

  /// Photos sent with this turn (at most one for now). Only offered, and only
  /// read, when the active model supports images.
  final List<Uint8List> images;

  /// Persona + any branch/seed context, passed per turn (not stored on the
  /// backend) so independent chat surfaces don't clobber each other.
  final String? systemInstruction;
  final List<(String, String)> cleanHistory;
}

@lazySingleton
class SendChatStreamUseCase extends StreamUseCase<String, SendChatStreamInput> {
  final LlmRepository _repo;
  const SendChatStreamUseCase(this._repo);

  @override
  Stream<String> call(SendChatStreamInput input) => _repo.sendChat(
        message: input.message,
        systemInstruction: input.systemInstruction,
        cleanHistory: input.cleanHistory,
        images: input.images,
      );
}

// ── One-shot extraction ───────────────────────────────────────────────────────

class GenerateOneShotInput {
  const GenerateOneShotInput({
    required this.prompt,
    this.maxTokens = 1024,
    this.kind = LlmTaskKind.extract,
    this.backendOverride,
    this.modelIdOverride,
  });
  final String prompt;
  final int maxTokens;

  /// Scheduler tier hint — see `docs/SHIVA/scheduling.md` §3 for the table.
  final LlmTaskKind kind;

  /// Run this call against a specific backend/model instead of whatever's
  /// globally active — see [LlmRepository.generateOneShot].
  final LlmBackendType? backendOverride;
  final String? modelIdOverride;
}

@lazySingleton
class GenerateOneShotUseCase
    extends UseCase<Either<Failure, String?>, GenerateOneShotInput> {
  final LlmRepository _repo;
  const GenerateOneShotUseCase(this._repo);

  @override
  Future<Either<Failure, String?>> call(
    GenerateOneShotInput input, {
    bool cached = false,
  }) =>
      _repo.generateOneShot(
        prompt: input.prompt,
        maxTokens: input.maxTokens,
        kind: input.kind,
        backendOverride: input.backendOverride,
        modelIdOverride: input.modelIdOverride,
      );
}

// ── Priority coordination ─────────────────────────────────────────────────────

@lazySingleton
class PreemptBackgroundWorkUseCase
    extends NoParamsUseCase<Either<Failure, Unit>> {
  final LlmRepository _repo;
  const PreemptBackgroundWorkUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call() => _repo.preemptBackgroundWork();
}

@lazySingleton
class ResumeBackgroundWorkUseCase
    extends NoParamsUseCase<Either<Failure, Unit>> {
  final LlmRepository _repo;
  const ResumeBackgroundWorkUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call() => _repo.resumeBackgroundWork();
}

// ── Backend / model selection ─────────────────────────────────────────────────

@lazySingleton
class GetActiveLlmBackendUseCase
    extends NoParamsUseCase<Either<Failure, LlmBackendType>> {
  final LlmRepository _repo;
  const GetActiveLlmBackendUseCase(this._repo);

  @override
  Future<Either<Failure, LlmBackendType>> call() => _repo.getActiveBackend();
}

@lazySingleton
class SetActiveLlmBackendUseCase
    extends UseCase<Either<Failure, Unit>, LlmBackendType> {
  final LlmRepository _repo;
  const SetActiveLlmBackendUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call(
    LlmBackendType backend, {
    bool cached = false,
  }) =>
      _repo.setActiveBackend(backend);
}

@lazySingleton
class ListAvailableLlmModelsUseCase
    extends NoParamsUseCase<Either<Failure, List<LlmModelInfo>>> {
  final LlmRepository _repo;
  const ListAvailableLlmModelsUseCase(this._repo);

  @override
  Future<Either<Failure, List<LlmModelInfo>>> call() =>
      _repo.listAvailableModels();
}

@lazySingleton
class ListCloudLlmModelsUseCase
    extends NoParamsUseCase<Either<Failure, List<LlmModelInfo>>> {
  final LlmRepository _repo;
  const ListCloudLlmModelsUseCase(this._repo);

  @override
  Future<Either<Failure, List<LlmModelInfo>>> call() =>
      _repo.listCloudModels();
}

@lazySingleton
class SetActiveLlmModelUseCase
    extends UseCase<Either<Failure, Unit>, String> {
  final LlmRepository _repo;
  const SetActiveLlmModelUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call(String modelId, {bool cached = false}) =>
      _repo.setActiveModel(modelId);
}

@lazySingleton
class GetActiveLlmModelUseCase
    extends NoParamsUseCase<Either<Failure, LlmModelInfo?>> {
  final LlmRepository _repo;
  const GetActiveLlmModelUseCase(this._repo);

  @override
  Future<Either<Failure, LlmModelInfo?>> call() => _repo.getActiveModel();
}

// ── UNIUN cloud connection ────────────────────────────────────────────────────

@lazySingleton
class ConnectUniunCloudUseCase
    extends NoParamsUseCase<Either<Failure, Unit>> {
  final UniunRepository _repo;
  const ConnectUniunCloudUseCase(this._repo);

  @override
  Future<Either<Failure, Unit>> call() => _repo.connect();
}

@lazySingleton
class DisconnectUniunCloudUseCase extends UseCase<Either<Failure, Unit>, bool> {
  final UniunRepository _repo;
  const DisconnectUniunCloudUseCase(this._repo);

  /// [confirm] must be true to go through when this is the account's last
  /// active key — the repo surfaces that as a `Failure` the caller can
  /// pattern-match on (see [UniunRepository.disconnect]).
  @override
  Future<Either<Failure, Unit>> call(bool confirm, {bool cached = false}) =>
      _repo.disconnect(confirm: confirm);
}

@lazySingleton
class IsUniunCloudConnectedUseCase extends NoParamsUseCase<bool> {
  final UniunRepository _repo;
  const IsUniunCloudConnectedUseCase(this._repo);

  @override
  Future<bool> call() => _repo.isConnected();
}

@lazySingleton
class GetUniunCloudStatusUseCase
    extends NoParamsUseCase<Either<Failure, ({String plan, num balance})>> {
  final UniunRepository _repo;
  const GetUniunCloudStatusUseCase(this._repo);

  @override
  Future<Either<Failure, ({String plan, num balance})>> call() =>
      _repo.accountStatus();
}

// ── Note translation ──────────────────────────────────────────────────────────

class TranslateNoteInput {
  const TranslateNoteInput({required this.content, required this.target});
  final String content;
  final TranslationLanguage target;
}

/// Translates one note into [TranslateNoteInput.target].
///
/// Wraps [LlmRepository.generateOneShot], which already dispatches
/// local-vs-cloud off the active [LlmBackendType] — no backend branching here.
///
/// `Right(null)` means no usable translation: NOOP sentinel, echoed source,
/// corrupt bytes, or a repetition loop. These are indistinguishable from "the
/// note was already in that language", so callers must not report it as such.
@lazySingleton
class TranslateNoteUseCase
    extends UseCase<Either<Failure, String?>, TranslateNoteInput> {
  final LlmRepository _repo;
  const TranslateNoteUseCase(this._repo);

  @override
  Future<Either<Failure, String?>> call(
    TranslateNoteInput input, {
    bool cached = false,
  }) async {
    final prompt = TranslationPrompt.build(
      content: input.content,
      target: input.target,
    );
    // Devanagari/Japanese tokenise less densely than Latin, so the output
    // needs more room than the source.
    final result = await _repo.generateOneShot(
      prompt: prompt,
      maxTokens: 2048,
      kind: LlmTaskKind.translate,
    );
    return result.map((raw) {
      final text = raw?.trim();
      if (text == null || text.isEmpty) return null;
      if (text.toUpperCase() == TranslationPrompt.noopSentinel) return null;
      // Small models echo the source for languages they can't write.
      if (text == input.content.trim()) return null;
      // Broken bytes / repetition loop — same failure, different shape.
      if (LlmTextSanitizer.looksCorrupted(text)) return null;
      if (LlmTextSanitizer.looksDegenerate(text)) return null;
      return text;
    });
  }
}
