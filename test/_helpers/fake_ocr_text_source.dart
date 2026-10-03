import 'package:uniun/data/datasources/ocr/ocr_text_source.dart';

/// Deterministic [OcrTextSource]: returns preset text per path, counts reads.
class FakeOcrTextSource implements OcrTextSource {
  /// path -> text. A missing key or a `null` value simulates an unreadable
  /// image; `''` is an image with no text in it.
  final Map<String, String?> texts = {};
  int calls = 0;

  /// Answers any path not in [texts] — for files whose name the caller
  /// cannot know in advance, such as a page rendered to a temp file.
  String? Function(String path)? reader;

  /// When set, [imageText] throws it instead of answering.
  Object? throwOnRead;

  @override
  Future<String?> imageText(String path) async {
    calls++;
    if (throwOnRead != null) throw throwOnRead!;
    return texts.containsKey(path) ? texts[path] : reader?.call(path);
  }
}
