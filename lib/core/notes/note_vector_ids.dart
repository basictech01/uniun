/// A note's vectors in the note vector store: one for a short note, several
/// "pieces" for a long one (#296).
///
/// The first piece is stored under the note's own id, so a note embedded before
/// pieces existed is already valid; piece `k` (k >= 1) is `<noteId>#<k>`. A
/// Nostr event id is hex, so `#` never occurs in a note id.
const String kPieceSeparator = '#';

String pieceId(String noteId, int index) =>
    index == 0 ? noteId : '$noteId$kPieceSeparator$index';

/// The note a stored vector id belongs to.
String noteIdOfVector(String vectorId) {
  final i = vectorId.indexOf(kPieceSeparator);
  return i < 0 ? vectorId : vectorId.substring(0, i);
}
