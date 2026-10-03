import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/enum/document_kind.dart';

/// Covers: mime → DocumentKind mapping, case and parameter tolerance, and the
/// formats deliberately left out.
void main() {
  const docxMime =
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

  test('the PDF and DOCX mimes map to their kinds', () {
    expect(DocumentKind.fromMime('application/pdf'), DocumentKind.pdf);
    expect(DocumentKind.fromMime(docxMime), DocumentKind.docx);
  });

  test('every image mime is an image', () {
    for (final mime in ['image/jpeg', 'image/png', 'image/webp', 'image/heic',
        'Image/GIF']) {
      expect(DocumentKind.fromMime(mime), DocumentKind.image, reason: mime);
    }
  });

  test('pdf stays the first value — the default Isar reads for older rows', () {
    expect(DocumentKind.values.first, DocumentKind.pdf);
  });

  test('each kind round-trips through its own mime prefix', () {
    for (final k in DocumentKind.values) {
      expect(DocumentKind.fromMime(k.mime), k);
    }
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  test('case and mime parameters are ignored', () {
    expect(DocumentKind.fromMime('Application/PDF; charset=binary'),
        DocumentKind.pdf);
    expect(DocumentKind.fromMime(docxMime.toUpperCase()), DocumentKind.docx);
  });

  test('legacy Word, OpenDocument and non-documents are not documents', () {
    for (final mime in [
      'application/msword',
      'application/vnd.oasis.opendocument.text',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'video/mp4',
      'audio/ogg',
      'application/octet-stream',
      'imagex/fake',
      '',
    ]) {
      expect(DocumentKind.fromMime(mime), isNull, reason: mime);
    }
  });
}
