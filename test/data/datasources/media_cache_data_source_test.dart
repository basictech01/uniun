import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:uniun/data/datasources/media_cache_data_source.dart';

/// Covers: MediaCacheDataSource file I/O — write / read / exists / delete /
/// totalBytes / fileFor / directory creation / extension-mismatch fallback /
/// idempotent overwrite / concurrent writes.
///
/// `path_provider` is stubbed at the platform channel level so
/// `getApplicationSupportDirectory()` returns a per-test tmp dir.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;
  late MediaCacheDataSource ds;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('uniun_media_cache_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async {
            // MediaCacheDataSource only calls getApplicationSupportDirectory.
            if (call.method == 'getApplicationSupportDirectory') {
              return support.path;
            }
            return null;
          },
        );
    ds = MediaCacheDataSource();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    if (await support.exists()) {
      await support.delete(recursive: true);
    }
  });

  Uint8List bytesOf(String s) => Uint8List.fromList(s.codeUnits);

  group('fileFor / directory creation', () {
    test('creates media/ subdirectory on first call', () async {
      final f = await ds.fileFor('abc', 'jpg');
      expect(p.dirname(f.path), p.join(support.path, 'media'));
      expect(await Directory(p.join(support.path, 'media')).exists(), isTrue);
    });

    test('filename is <sha>.<ext> when ext supplied', () async {
      final f = await ds.fileFor('abc', 'jpg');
      expect(p.basename(f.path), 'abc.jpg');
    });

    test('filename is bare <sha> when ext is null', () async {
      final f = await ds.fileFor('abc', null);
      expect(p.basename(f.path), 'abc');
    });

    test('filename is bare <sha> when ext is empty string', () async {
      final f = await ds.fileFor('abc', '');
      expect(p.basename(f.path), 'abc');
    });

    test('strips a leading dot on the ext', () async {
      final f = await ds.fileFor('abc', '.png');
      expect(p.basename(f.path), 'abc.png');
    });
  });

  group('write + read + exists (happy path)', () {
    test('write persists bytes readable byte-for-byte', () async {
      final data = bytesOf('hello');
      await ds.write('sha', 'txt', data);
      final f = await ds.read('sha', 'txt');
      expect(f, isNotNull);
      expect(await f!.readAsBytes(), data);
    });

    test('exists returns true after write', () async {
      await ds.write('sha', 'txt', bytesOf('x'));
      expect(await ds.exists('sha', 'txt'), isTrue);
    });

    test('exists returns false for absent sha', () async {
      expect(await ds.exists('nope', 'txt'), isFalse);
    });

    test('read returns null for absent sha', () async {
      expect(await ds.read('nope', 'txt'), isNull);
    });
  });

  group('extension-mismatch fallback', () {
    test('exists finds a blob written under a different ext', () async {
      await ds.write('sha', 'jpg', bytesOf('img'));
      // Caller queries with a wrong ext (mime was guessed differently)
      expect(await ds.exists('sha', 'png'), isTrue);
    });

    test('read finds a blob written under a different ext', () async {
      await ds.write('sha', 'jpg', bytesOf('img'));
      final f = await ds.read('sha', 'png');
      expect(f, isNotNull);
      expect(await f!.readAsBytes(), bytesOf('img'));
    });

    test('exists finds a blob written with no ext', () async {
      await ds.write('sha', null, bytesOf('data'));
      expect(await ds.exists('sha', 'jpg'), isTrue);
    });
  });

  group('delete', () {
    test('removes the file', () async {
      await ds.write('sha', 'jpg', bytesOf('x'));
      await ds.delete('sha', 'jpg');
      expect(await ds.exists('sha', 'jpg'), isFalse);
      expect(await ds.read('sha', 'jpg'), isNull);
    });

    test('is idempotent — deleting an absent sha is a no-op', () async {
      // No throw expected.
      await ds.delete('nope', 'jpg');
      expect(await ds.exists('nope', 'jpg'), isFalse);
    });

    test('removes the blob regardless of stored ext', () async {
      await ds.write('sha', 'jpg', bytesOf('x'));
      // Caller passes the wrong ext — delete should still nuke it.
      await ds.delete('sha', 'png');
      expect(await ds.exists('sha', null), isFalse);
    });
  });

  test(
    'logout clear removes every cached attachment, including nested files',
    () async {
      await ds.write('first', 'jpg', bytesOf('one'));
      await ds.write('second', 'png', bytesOf('two'));
      final nested = Directory(p.join(support.path, 'media', 'nested'));
      await nested.create();
      await File(p.join(nested.path, 'partial.tmp')).writeAsString('partial');

      await ds.clear();

      expect(await ds.read('first', 'jpg'), isNull);
      expect(await ds.read('second', 'png'), isNull);
      expect(await nested.exists(), isFalse);
      expect(await ds.totalBytes(), 0);
    },
  );

  group('idempotency / overwrite', () {
    test('re-writing the same sha overwrites with new bytes', () async {
      await ds.write('sha', 'txt', bytesOf('v1'));
      await ds.write('sha', 'txt', bytesOf('v2'));
      final f = await ds.read('sha', 'txt');
      expect(await f!.readAsBytes(), bytesOf('v2'));
    });
  });

  group('totalBytes', () {
    test('empty cache returns 0', () async {
      expect(await ds.totalBytes(), 0);
    });

    test('single blob returns its length', () async {
      await ds.write('sha', 'txt', bytesOf('hello')); // 5 bytes
      expect(await ds.totalBytes(), 5);
    });

    test('sums across many blobs', () async {
      await ds.write('a', 'txt', bytesOf('x')); // 1
      await ds.write('b', 'txt', bytesOf('yz')); // 2
      await ds.write('c', 'txt', bytesOf('abcd')); // 4
      expect(await ds.totalBytes(), 7);
    });
  });

  // ── Edge cases ────────────────────────────────────────────────────────────

  group('empty & zero-byte inputs', () {
    test('zero-byte write persists an empty file', () async {
      await ds.write('sha', 'jpg', Uint8List(0));
      final f = await ds.read('sha', 'jpg');
      expect(await f!.length(), 0);
    });

    test('empty sha (unusual but not blocked) round-trips', () async {
      await ds.write('', 'jpg', bytesOf('x'));
      final f = await ds.fileFor('', 'jpg');
      expect(p.basename(f.path), '.jpg');
    });
  });

  group('scale', () {
    test('handles 100 concurrent writes without collision', () async {
      await Future.wait(
        List.generate(100, (i) => ds.write('sha$i', 'txt', bytesOf('v$i'))),
      );
      for (var i = 0; i < 100; i++) {
        final f = await ds.read('sha$i', 'txt');
        expect(await f!.readAsBytes(), bytesOf('v$i'));
      }
      expect(await ds.totalBytes(), greaterThan(0));
    });
  });

  group('directory memoization', () {
    test('second call reuses the cached directory reference', () async {
      final a = await ds.fileFor('a', 'txt');
      // Force-remove the media dir underneath — a memoized field should still
      // point at it and re-create-on-write.
      final mediaDir = Directory(p.dirname(a.path));
      if (await mediaDir.exists()) await mediaDir.delete(recursive: true);
      // Re-writing should still succeed (directory recreated by write path).
      // NOTE: the impl memoizes _cachedDir and calls create only on first hit;
      // if the dir is deleted mid-session, the next write will fail because
      // Flutter's `File.writeAsBytes` requires the parent to exist. That's a
      // known limitation — pinned here so we notice if it changes.
      await expectLater(
        ds.write('b', 'txt', bytesOf('x')),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
