import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/utils/llm_backend.dart';
import 'package:uniun/data/datasources/llm/embedding_queue.dart';
import 'package:uniun/data/datasources/llm/flutter_edge_ai_gateway.dart';
import 'package:uniun/features/shiv/rag/extraction/chunk.dart';

/// On-device text embedding using Gecko 110M (768-dim), run through
/// flutter_edge_ai's LiteRT embedder.
///
/// ## Why flutter_edge_ai instead of tflite_flutter
/// flutter_edge_ai (MediaPipe) statically embeds its own copy of TensorFlow Lite.
/// `tflite_flutter` linked a *second* copy, so on the iOS arm64 device build
/// both ended up in one binary → duplicate `TFLBufferConvert` Objective-C class
/// → corrupted symbol table → `EXC_BAD_ACCESS` / Isar `isar_version` failures.
/// Running embeddings through flutter_edge_ai's own LiteRT runtime keeps a single
/// TensorFlow Lite in the binary and removes the conflict entirely.
///
/// ## Bundled, not downloaded
/// The models + tokenizer ship as app assets (see
/// [modelAsset], [tokenizerAsset]), so RAG works offline on first launch with
/// no network fetch. `installEmbedder` copies an asset into flutter_edge_ai's
/// managed storage once.
///
/// ## One file, long notes in pieces (#296)
/// Gecko comes as a 256-token and a 1024-token file with the same weights, and
/// every input is padded to the file's full length, so the 256 file is 5.4x
/// faster (2.2 s against 11.7 s an embed on a Snapdragon 710). Only the 256
/// file is bundled. It reads about 1,100 characters, so a longer note is cut
/// into pieces of at most [notePieceChars] and each piece is embedded on its
/// own ([embedNote]); search keeps the best piece per note.
///
/// Output: 768-dimensional L2-normalised float vector.
@lazySingleton
class EmbeddingService {
  EmbeddingService(this._gateway, this._queue);

  final FlutterEdgeAiGateway _gateway;
  final EmbeddingQueue _queue;

  static const int embeddingDim = 768;

  /// Bundled asset paths — also referenced by [EmbeddingModelDownloader] so the
  /// install can be pre-warmed during the LLM download UX.
  static const String modelAsset =
      'assets/models/embedding/gecko_256_quant.tflite';
  static const String tokenizerAsset = 'assets/models/embedding/sentencepiece.model';

  /// The longest piece of a note. 256 tokens is roughly 1,100 characters of
  /// English; 700 matched or beat a whole note on the 1024 file in the #296
  /// measurement and is also the cap for document chunks.
  static const int notePieceChars = kMaxChunkChars;

  /// A note beyond this many pieces (about 16,800 characters) is cut: embedding
  /// costs ~2.2 s a piece, and the head of a note says what it is about.
  static const int maxNotePieces = 24;

  EmbeddingModel? _model;

  bool get isReady => _model != null;

  // ── Init ───────────────────────────────────────────────────────────────────

  /// Installs the bundled embedder (idempotent) and opens it. Safe to call
  /// multiple times — no-op after a successful load. Degrades to no-context
  /// mode (returns no vectors) if the model fails to open.
  Future<void> init() async {
    if (isReady) return;
    try {
      await _load();
    } catch (e) {
      debugPrint('🧠 Embedding: model load failed — $e');
    }
  }

  /// Installs and opens the embedder.
  ///
  /// On failure nothing is left loaded, so [isReady] says false and the note
  /// worker keeps its queue instead of counting every note as failed.
  Future<void> _load() async {
    if (_model != null) return;
    await _gateway.installEmbedder(
      modelAsset: modelAsset,
      tokenizerAsset: tokenizerAsset,
    );
    // Prefer GPU, fall back to CPU on load failure so RAG still works
    // everywhere.
    final backend = preferredLlmBackend;
    try {
      _model = await _gateway.getActiveEmbedder(preferredBackend: backend);
    } on Object catch (e) {
      if (backend == PreferredBackend.cpu) rethrow;
      debugPrint('🧠 Embedding: GPU load failed ($e) — retrying on CPU');
      _model = await _gateway.getActiveEmbedder(
        preferredBackend: PreferredBackend.cpu,
      );
    }
  }

  /// Copies the bundled Gecko file into flutter_edge_ai's storage. Returns fast
  /// once an embedder is installed.
  Future<void> ensureInstalled() async {
    if (_gateway.hasActiveEmbedder()) return;
    await _gateway.installEmbedder(
      modelAsset: modelAsset,
      tokenizerAsset: tokenizerAsset,
    );
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Embed [text] → 768-dim L2-normalised vector.
  ///
  /// [isDocument] selects the task prefix: documents being indexed (note
  /// content) use the document prefix, search queries use the query prefix.
  /// Getting this right is what makes asymmetric retrieval accurate.
  ///
  /// Returns [] if the model is not loaded (no crash, just no RAG context).
  ///
  /// Every call goes through [EmbeddingQueue]: a query is interactive (someone
  /// is waiting) and a document is background, so a Shiv question is never
  /// stuck behind a backlog of notes and PDF chunks.
  Future<List<double>> embed(String text, {bool isDocument = false}) {
    return _queue.run(
      () => _embed(text, isDocument: isDocument),
      priority:
          isDocument ? EmbedPriority.background : EmbedPriority.interactive,
    );
  }

  /// flutter_edge_ai 2.3 refuses an input longer than the model's window
  /// ([EmbeddingInputTooLongException]) instead of truncating it as 1.x did.
  /// A note can be arbitrarily long, so shrink it by the reported ratio and
  /// retry, a few times at most: the head of a note carries what it is about.
  static const int _maxFitAttempts = 4;

  Future<List<double>> _embed(String text, {required bool isDocument}) async {
    if (!isReady) await init();
    if (!isReady) return [];
    final taskType =
        isDocument ? TaskType.retrievalDocument : TaskType.retrievalQuery;
    var input = text;
    for (var attempt = 0; attempt < _maxFitAttempts; attempt++) {
      try {
        return _l2Normalize(
          await _model!.embed(EmbeddingInput.text(input), taskType: taskType),
        );
      } on EmbeddingInputTooLongException catch (e) {
        final ratio = e.actualTokens != null && e.actualTokens! > 0
            ? e.maxInputTokens / e.actualTokens!
            : 0.5;
        final next = (input.length * ratio * 0.9).floor();
        if (next <= 0 || next >= input.length) break;
        debugPrint(
          '🧠 Embedding: input too long '
          '(${e.actualTokens ?? '?'}/${e.maxInputTokens} tokens) — '
          'shortening ${input.length} → $next chars',
        );
        input = input.substring(0, next);
      } catch (e) {
        debugPrint('🧠 Embedding: generate failed — $e');
        return [];
      }
    }
    debugPrint('🧠 Embedding: could not fit input into the model window');
    return [];
  }

  /// Embeds a note as documents: one vector per piece, first piece first, so a
  /// long note is searchable all the way to its end. `[]` when the model is not
  /// loaded or any piece fails (nothing is stored for a half-embedded note).
  ///
  /// Each piece is its own queue entry, so a question waits for at most one
  /// piece. A piece that is still too long for the model (dense scripts take
  /// more tokens per character) is split in two, never cut.
  Future<List<List<double>>> embedNote(String text) async {
    final pieces = chunkSections(
      [(label: '', text: text)],
      maxChars: notePieceChars,
    ).map((c) => c.text).take(maxNotePieces).toList();
    final out = <List<double>>[];
    for (final piece in pieces) {
      final vectors = await _embedPiece(piece);
      if (vectors.isEmpty) return const [];
      out.addAll(vectors);
    }
    return out;
  }

  Future<List<List<double>>> _embedPiece(String piece, {int depth = 0}) async {
    final taskType = TaskType.retrievalDocument;
    final result = await _queue.run<Object>(() async {
      if (!isReady) await init();
      if (!isReady) return const <double>[];
      try {
        return _l2Normalize(
          await _model!.embed(EmbeddingInput.text(piece), taskType: taskType),
        );
      } on EmbeddingInputTooLongException {
        return _TooLong();
      } catch (e) {
        debugPrint('🧠 Embedding: generate failed — $e');
        return const <double>[];
      }
    }, priority: EmbedPriority.background);
    if (result is List<double>) return result.isEmpty ? const [] : [result];
    // Too long: split at the whitespace nearest the middle and embed both.
    if (depth >= _maxSplitDepth || piece.length < 2) return const [];
    final mid = piece.length ~/ 2;
    var cut = piece.lastIndexOf(RegExp(r'\s'), mid);
    if (cut <= 0) cut = mid;
    final left = await _embedPiece(piece.substring(0, cut), depth: depth + 1);
    if (left.isEmpty) return const [];
    final right = await _embedPiece(piece.substring(cut), depth: depth + 1);
    return right.isEmpty ? const [] : [...left, ...right];
  }

  static const int _maxSplitDepth = 4;

  Future<void> dispose() async {
    await _model?.close();
    _model = null;
  }

  // ── L2 normalisation ──────────────────────────────────────────────────────

  /// Gecko already returns unit-norm vectors; normalising again is a no-op
  /// there but keeps cosine search correct regardless of the model.
  List<double> _l2Normalize(List<double> vec) {
    final norm = sqrt(vec.fold(0.0, (acc, v) => acc + v * v));
    if (norm == 0) return vec;
    return vec.map((v) => v / norm).toList();
  }
}

/// Marker returned from a queued embed whose input did not fit the model.
class _TooLong {}
