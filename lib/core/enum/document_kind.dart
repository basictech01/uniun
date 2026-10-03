/// The attachment formats Shiv can read, keyed by mime.
///
/// The single answer to "is this cached blob a document" — the indexer's
/// filter, the vector search and the citation resolver all ask here.
enum DocumentKind {
  pdf('application/pdf'),
  docx(
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ),

  /// Any `image/*` — read by OCR for the text inside it.
  image('image/');

  const DocumentKind(this.mime);

  /// The mime, or for [image] the mime prefix, this kind matches.
  final String mime;

  /// Prefix match, case-insensitive, so `; charset=` parameters still match.
  /// `null` for every other format — legacy `.doc` and `.odt` included.
  static DocumentKind? fromMime(String mime) {
    final m = mime.toLowerCase();
    for (final k in values) {
      if (m.startsWith(k.mime)) return k;
    }
    return null;
  }
}
