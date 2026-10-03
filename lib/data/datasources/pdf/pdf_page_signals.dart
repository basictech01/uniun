/// A rectangle in PDF page space: points, origin at the bottom-left.
typedef PdfBox = ({double left, double bottom, double right, double top});

/// What one PDF page is made of, read straight from PDFium — the evidence for
/// deciding whether its text layer can be trusted or the page needs OCR.
///
/// Character counts exclude characters PDFium generated itself (inserted
/// spaces and line breaks) and whitespace.
class PdfPageSignals {
  const PdfPageSignals({
    required this.width,
    required this.height,
    required this.rotation,
    required this.chars,
    required this.letters,
    required this.unmapped,
    required this.invisible,
    required this.legacyFont,
    required this.imageCoverage,
    this.largestImage,
    this.largestImageCoverage = 0,
    this.charsInLargestImage = 0,
  });

  final double width;
  final double height;

  /// 0–3 quarter turns, as PDFium reports it.
  final int rotation;

  final int chars;
  final int letters;

  /// Characters PDFium could not map to Unicode — a broken font encoding.
  final int unmapped;

  /// Characters drawn with text render mode 3 or 7: the invisible layer a
  /// scanner's OCR lays over the page image.
  final int invisible;

  /// Text set in a legacy non-Unicode Hindi font (Kruti Dev and similar),
  /// which extracts as letter-rich Latin gibberish.
  final bool legacyFont;

  /// Share of the page (0–1) covered by image objects.
  final double imageCoverage;

  final PdfBox? largestImage;

  /// Share of the page (0–1) covered by [largestImage] alone.
  final double largestImageCoverage;

  /// Text-layer characters whose centre falls inside [largestImage] — text
  /// drawn over an image means the image is a background, not content.
  final int charsInLargestImage;

  double get letterRatio => chars == 0 ? 0 : letters / chars;
  double get unmappedShare => chars == 0 ? 0 : unmapped / chars;
  double get invisibleShare => chars == 0 ? 0 : invisible / chars;
}
