import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/data/models/documents/document_index_model.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/features/shiv/rag/extraction/document_extraction_service.dart';

/// Keeps the document index (every [DocumentKind]) in step with the media
/// cache.
///
/// Reconciles by SHA-256 rather than reacting to a "blob arrived" event:
///   * a cached document Shiv may cite, with no index row → index it;
///   * an index row whose document is no longer cached, or no longer one Shiv
///     may cite → purge its chunks and index row.
///
/// Shiv may cite a document attached to one of the user's own feed notes or
/// to any saved note — the same notes Shiv's note search covers. A document
/// merely opened from someone else's note, a DM or a group is not indexed:
/// opening a file is not asking Shiv to learn it, and saving is.
///
/// Reconciling state covers every way a blob reaches `MediaCacheModel` (upload,
/// download cache-hit, fresh download, staged draft — four call sites, all
/// inside a write transaction where embedding work cannot be awaited), retries
/// a crash mid-index because the index row is written last, and cleans up after
/// both deletion paths (`MediaRepository.removeLocal` and `CleanupManager`,
/// which deletes cache rows directly from the Gateway isolate).
///
/// Main isolate only: embedding runs through flutter_gemma, which is not
/// available in the Gateway isolate.
@lazySingleton
class DocumentIndexer {
  DocumentIndexer(
    this._isar,
    this._extraction,
    this._embedAndStore,
    this._activeUser,
  );

  final Isar _isar;
  final DocumentExtractionService _extraction;

  /// Embedding and vector storage both live behind this use case, which also
  /// bounds concurrency — the indexer never touches `EmbeddingService` or the
  /// vector repository itself.
  final EmbedAndStoreChunkUseCase _embedAndStore;

  /// Whose notes count as "own". Read per pass: the user can sign out.
  final GetActiveUserUseCase _activeUser;

  final List<StreamSubscription<void>> _subs = [];
  Timer? _settle;
  bool _running = false;
  bool _dirty = false;

  /// Collapses bursts — inbound feed sync writes many notes at once, and one
  /// pass after they land does the work of all of them.
  static const Duration _settleDelay = Duration(milliseconds: 500);

  /// Begin watching everything that decides what is indexed: the cached files,
  /// the saved notes, and the notes themselves (an own note is written after
  /// its attachment was cached). Reconciles once straight away.
  void start() {
    if (_subs.isNotEmpty) return;
    _subs.addAll([
      _isar.mediaCacheModels.watchLazy(fireImmediately: true).listen(_schedule),
      _isar.savedNoteModels.watchLazy().listen(_schedule),
      _isar.noteModels.watchLazy().listen(_schedule),
    ]);
  }

  void _schedule(void _) {
    _settle?.cancel();
    _settle = Timer(_settleDelay, () => unawaited(reconcile()));
  }

  Future<void> dispose() async {
    _settle?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  /// One full pass. Overlapping calls coalesce: a call made while a pass is
  /// running marks it dirty, and the running pass repeats before returning.
  Future<void> reconcile() async {
    if (_running) {
      _dirty = true;
      return;
    }
    _running = true;
    try {
      do {
        _dirty = false;
        final citable = await _citableShas();
        await _purgeOrphans(citable);
        await _indexPending(citable);
      } while (_dirty);
    } catch (e) {
      // Indexing runs off the chat path; a failure here must never surface
      // there. The next reconcile retries whatever did not finish.
      debugPrint('📄 DocumentIndexer: reconcile failed — $e');
    } finally {
      _running = false;
    }
  }

  /// SHA-256s of attachments on the user's own feed notes and on saved notes.
  Future<Set<String>> _citableShas() async {
    final shas = <String>{};
    final own = (await _activeUser.call()).fold(
      (_) => null,
      (u) => u.pubkeyHex,
    );
    if (own != null) {
      final notes = await _isar.noteModels
          .filter()
          .authorPubkeyEqualTo(own)
          .kindEqualTo(kNoteKind)
          .hasMediaEqualTo(true)
          .findAll();
      for (final n in notes) {
        shas.addAll(n.attachments.map((a) => a.sha256));
      }
    }
    final saved = await _isar.savedNoteModels
        .filter()
        .attachmentsIsNotEmpty()
        .findAll();
    for (final n in saved) {
      shas.addAll(n.attachments.map((a) => a.sha256));
    }
    return shas;
  }

  Future<void> _purgeOrphans(Set<String> citable) async {
    final indexed = await _isar.documentIndexModels.where().findAll();
    for (final row in indexed) {
      final cached = await _isar.mediaCacheModels.getBySha256(row.sha256);
      if (cached == null || !citable.contains(row.sha256)) {
        await _purge(row.sha256);
      }
    }
  }

  /// Looks up only the citable files, through the cache's unique index — never
  /// a scan of every cached blob: images made that thousands of feed photos,
  /// on a pass that runs after every note write.
  Future<void> _indexPending(Set<String> citable) async {
    for (final sha in citable) {
      final row = await _isar.mediaCacheModels.getBySha256(sha);
      if (row == null) continue; // attached but never downloaded
      final kind = DocumentKind.fromMime(row.mime);
      if (kind == null) continue; // a video or other non-document attachment
      if (await _isar.documentIndexModels.getBySha256(sha) != null) continue;
      await _index(sha, row.localPath, kind);
    }
  }

  Future<void> _index(String sha, String path, DocumentKind kind) async {
    // Indexing is silent otherwise, and can take minutes while the LLM holds
    // the device — without these a question asked mid-index looks like a
    // retrieval bug.
    final id = '${sha.length > 8 ? sha.substring(0, 8) : sha} (${kind.name})';
    final clock = Stopwatch()..start();
    debugPrint('📄 DocumentIndexer: indexing $id…');
    final result = await _extraction.extract(path, kind);
    switch (result) {
      case NotSearchable(:final pageCount, :final reason):
        await _writeIndexRow(
          sha,
          kind,
          DocumentIndexStatus.notSearchable,
          pageCount,
          0,
        );
        debugPrint(
          '📄 DocumentIndexer: $id not searchable (${reason.name}) '
          'in ${clock.elapsed.inSeconds}s',
        );
      case Extracted(:final chunks, :final pageCount):
        // Clear whatever an interrupted earlier attempt left behind, so a retry
        // cannot leave a half-indexed document with stale chunks.
        await _purgeChunks(sha);
        for (final c in chunks) {
          // The row first, the vector second: embedding attaches the vector to
          // this row. A row with no vector is never returned by search.
          await _isar.writeTxn(
            () => _isar.documentChunkModels.put(
              DocumentChunkModel()
                ..sha256 = sha
                ..ordinal = c.ordinal
                ..label = c.label
                ..text = c.text,
            ),
          );
          debugPrint(
            '📄 DocumentIndexer: $id chunk ${c.ordinal + 1}/${chunks.length}',
          );
          final stored = await _embedAndStore.call((
            chunkIdOf(sha, c.ordinal),
            c.text,
          ));
          if (!stored) {
            // The embedder is not ready. That is NOT "not searchable" — leave
            // no index row so a later reconcile retries the whole document.
            debugPrint(
              '📄 DocumentIndexer: embedder not ready, will retry $id',
            );
            return;
          }
        }
        // Written last: chunks and vectors first, so a crash part-way leaves a
        // retriable state rather than a document recorded as done but empty.
        await _writeIndexRow(
          sha,
          kind,
          DocumentIndexStatus.indexed,
          pageCount,
          chunks.length,
        );
        debugPrint(
          '📄 DocumentIndexer: indexed $id — ${chunks.length} chunks '
          'in ${clock.elapsed.inSeconds}s',
        );
    }
  }

  Future<void> _writeIndexRow(
    String sha,
    DocumentKind kind,
    DocumentIndexStatus status,
    int pageCount,
    int chunkCount,
  ) => _isar.writeTxn(
    () => _isar.documentIndexModels.put(
      DocumentIndexModel()
        ..sha256 = sha
        ..kind = kind
        ..status = status
        ..pageCount = pageCount
        ..chunkCount = chunkCount
        ..indexedAt = DateTime.now(),
    ),
  );

  Future<void> _purge(String sha) async {
    await _purgeChunks(sha);
    await _isar.writeTxn(() => _isar.documentIndexModels.deleteBySha256(sha));
  }

  /// Drops a document's chunk rows — and with them their vectors.
  Future<void> _purgeChunks(String sha) => _isar.writeTxn(
    () => _isar.documentChunkModels
        .where()
        .sha256EqualToAnyOrdinal(sha)
        .deleteAll(),
  );
}
