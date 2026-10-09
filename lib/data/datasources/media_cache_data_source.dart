import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Content-addressed local blob cache. One file per sha256, named
/// `<sha256>.<ext>` under `getApplicationSupportDirectory()/media/`. The
/// extension is preserved purely for OS file-manager affordance; lookups
/// never depend on it (we always fall back to the prefix match if needed).
///
/// Pure file I/O — no DB, no http. The repository layer owns the manifest.
@lazySingleton
class MediaCacheDataSource {
  Directory? _cachedDir;

  Future<Directory> _mediaDir() async {
    if (_cachedDir != null) return _cachedDir!;
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'media'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cachedDir = dir;
    return dir;
  }

  String _filename(String sha256, String? ext) {
    if (ext == null || ext.isEmpty) return sha256;
    final clean = ext.startsWith('.') ? ext.substring(1) : ext;
    return '$sha256.$clean';
  }

  Future<File> fileFor(String sha256, String? ext) async {
    final dir = await _mediaDir();
    return File(p.join(dir.path, _filename(sha256, ext)));
  }

  Future<bool> exists(String sha256, String? ext) async {
    final f = await fileFor(sha256, ext);
    if (await f.exists()) return true;
    // Extension may have been guessed wrong on inbound — fall back to a
    // prefix scan so we never re-download a blob we already have under a
    // different ext.
    final dir = await _mediaDir();
    final hits = dir.listSync().whereType<File>().where(
          (f) => p.basenameWithoutExtension(f.path) == sha256,
        );
    return hits.isNotEmpty;
  }

  Future<File> write(String sha256, String? ext, Uint8List bytes) async {
    final f = await fileFor(sha256, ext);
    return f.writeAsBytes(bytes, flush: true);
  }

  Future<File?> read(String sha256, String? ext) async {
    final f = await fileFor(sha256, ext);
    if (await f.exists()) return f;
    final dir = await _mediaDir();
    for (final entry in dir.listSync()) {
      if (entry is File &&
          p.basenameWithoutExtension(entry.path) == sha256) {
        return entry;
      }
    }
    return null;
  }

  Future<void> delete(String sha256, String? ext) async {
    final dir = await _mediaDir();
    for (final entry in dir.listSync()) {
      if (entry is File &&
          p.basenameWithoutExtension(entry.path) == sha256) {
        await entry.delete();
      }
    }
  }

  /// Clear attachments cached for the logged-out account.
  Future<void> clear() async {
    final dir = await _mediaDir();
    await for (final entry in dir.list()) {
      await entry.delete(recursive: true);
    }
  }

  /// Total bytes the cache currently occupies. Used by the Storage page.
  Future<int> totalBytes() async {
    final dir = await _mediaDir();
    var sum = 0;
    for (final entry in dir.listSync()) {
      if (entry is File) sum += await entry.length();
    }
    return sum;
  }
}
