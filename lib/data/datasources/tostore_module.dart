import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uniun/data/datasources/note_vector_store.dart';

export 'package:uniun/data/datasources/note_vector_store.dart'
    show
        embeddingsDimensions,
        embeddingsIdField,
        embeddingsTableName,
        embeddingsVectorField;

/// Bump when a `tostore` upgrade changes its on-disk format or its index. The
/// store opens at a new path, empty, instead of misreading the old one (a store
/// written by 3.1.2 opens under 3.5.1 with every vector present and an empty
/// index, so search finds nothing) and notes re-embed as they are saved.
const int kNoteVectorStoreFormat = 2;

/// Opens the note vector store in its own isolate and registers it as an
/// app-wide singleton.
@module
abstract class TostoreModule {
  @singleton
  @preResolve
  Future<NoteVectorStore> createNoteVectorStore() async {
    final docDir = await getApplicationDocumentsDirectory();
    // The path carries the embedding dimension (a dimension change must not
    // collide with old-size vectors) and the store format.
    const current = 'tostore_${embeddingsDimensions}d_v$kNoteVectorStoreFormat';
    // Every other `tostore_*` folder is an older store nothing reads any more.
    for (final entry in Directory(docDir.path).listSync()) {
      if (entry is Directory &&
          p.basename(entry.path).startsWith('tostore_') &&
          p.basename(entry.path) != current) {
        unawaited(entry.delete(recursive: true));
      }
    }
    return NoteVectorStore.open(p.join(docDir.path, current));
  }
}
