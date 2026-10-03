import 'package:uniun/data/datasources/docx/docx_text_source.dart';

/// Deterministic [DocxTextSource]: returns preset sections per path, counts
/// reads.
class FakeDocxTextSource implements DocxTextSource {
  /// path -> sections. A missing key or a `null` value simulates an unreadable
  /// file. Put a [docxImageMarker] in a section's text for a picture.
  final Map<String, List<DocxSection>?> sections = {};
  int calls = 0;

  /// The picture directory the last read was given.
  String? imageDir;

  /// When set, [sectionsText] throws it instead of answering.
  Object? throwOnRead;

  @override
  Future<List<DocxSection>?> sectionsText(
    String path, {
    String? imageDir,
  }) async {
    calls++;
    this.imageDir = imageDir;
    if (throwOnRead != null) throw throwOnRead!;
    return sections[path];
  }
}
