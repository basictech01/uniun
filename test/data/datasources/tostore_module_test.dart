import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:uniun/data/datasources/note_vector_store.dart';
import 'package:uniun/data/datasources/tostore_module.dart';

import '../../_helpers/fake_path_provider.dart';

class _Module extends TostoreModule {}

/// Covers: TostoreModule opening the note vector store at a version-stamped
/// path and removing every older tostore_* folder.
void main() {
  late Directory docs;
  NoteVectorStore? store;

  const versioned = 'tostore_${embeddingsDimensions}d_v$kNoteVectorStoreFormat';
  const legacy = 'tostore_${embeddingsDimensions}d';

  setUp(() async {
    docs = await Directory.systemTemp.createTemp('tostore_module_');
    PathProviderPlatform.instance = FakePathProviderPlatform(
      docs: docs.path,
      support: docs.path,
    );
    store = null;
  });

  tearDown(() async {
    await store?.close();
    await docs.delete(recursive: true);
  });

  Future<NoteVectorStore> open() async =>
      store = await _Module().createNoteVectorStore();

  test(
    'the store opens in a folder named for the dimension and format',
    () async {
      await open();

      expect(Directory(p.join(docs.path, versioned)).existsSync(), isTrue);
    },
  );

  test(
    'the format number is part of the path, so a bump opens a new store',
    () {
      expect(versioned, endsWith('_v$kNoteVectorStoreFormat'));
      expect(kNoteVectorStoreFormat, greaterThanOrEqualTo(2));
    },
  );

  test(
    'every older tostore_* folder is deleted and the current one is kept',
    () async {
      final olds = [
        legacy,
        'tostore_1024d',
        'tostore_1024d_v2',
        'tostore_${embeddingsDimensions}d_v${kNoteVectorStoreFormat - 1}',
        'tostore_docs_1024d',
      ];
      for (final name in olds) {
        final d = Directory(p.join(docs.path, name))..createSync();
        File(p.join(d.path, 'data')).writeAsStringSync('old store');
      }

      await open();
      for (var i = 0; i < 50; i++) {
        if (olds.every((n) => !Directory(p.join(docs.path, n)).existsSync())) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      for (final name in olds) {
        expect(
          Directory(p.join(docs.path, name)).existsSync(),
          isFalse,
          reason: name,
        );
      }
      expect(Directory(p.join(docs.path, versioned)).existsSync(), isTrue);
    },
  );

  test('a folder that only looks similar is left alone', () async {
    final other = Directory(p.join(docs.path, 'my_tostore_backup'))
      ..createSync();

    await open();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(other.existsSync(), isTrue);
  });

  test('a plain file named tostore_x is not touched', () async {
    final file = File(p.join(docs.path, 'tostore_notes.txt'))
      ..writeAsStringSync('keep');

    await open();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(file.existsSync(), isTrue);
  });

  test(
    'a store with no old folder opens without touching anything else',
    () async {
      final other = Directory(p.join(docs.path, 'keep_me'))..createSync();

      await open();

      expect(other.existsSync(), isTrue);
    },
  );

  test('the opened store works', () async {
    final s = await open();

    await s.upsert('a', List<double>.filled(embeddingsDimensions, 0.1));

    expect(await s.contains('a'), isTrue);
  });

  test('reopening finds what an earlier run saved', () async {
    var s = await open();
    await s.upsert('a', List<double>.filled(embeddingsDimensions, 0.1));
    await s.close();

    s = store = await _Module().createNoteVectorStore();

    expect(await s.contains('a'), isTrue);
  });
}
