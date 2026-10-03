/// Shortest extraction worth indexing. A scan whose text layer holds only a
/// registrar's e-signature clears "non-empty" but not this.
const int kMinExtractedChars = 200;

/// The minimum for text read from an image. A sign, a receipt or a caption is
/// short and genuine — the 200-character floor exists for PDF scans and broken
/// font encodings, and would permanently bury them. The letter ratio still
/// rejects OCR noise.
const int kMinImageTextChars = 16;

/// Share of characters that must be letters for the text to read as prose.
///
/// Borrowed from a comparable document-RAG system that measured it over legal
/// judgments: real text clustered at 0.6–0.8, while PDFs with a broken font
/// encoding extracted as mojibake (`!" #$%$ &'()`) at 0.03–0.06.
///
/// NOT yet measured on this app's documents. The committed fixture clears it
/// comfortably, which is a sanity check rather than a calibration — revisit
/// with real user documents.
const double kMinLetterRatio = 0.15;

/// Unicode-aware, so Devanagari, Arabic and CJK all count as letters. A
/// non-Unicode `[a-zA-Z]` test would reject a perfectly good Hindi circular.
final RegExp _letter = RegExp(r'\p{L}', unicode: true);

/// Whether [text] is real prose rather than empty, too short, or mojibake.
bool looksLikeProse(String text, {int minChars = kMinExtractedChars}) {
  final t = text.trim();
  if (t.length < minChars) return false;
  return _letter.allMatches(t).length / t.length >= kMinLetterRatio;
}
