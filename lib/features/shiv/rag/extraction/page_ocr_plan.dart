import 'package:uniun/data/datasources/pdf/pdf_page_signals.dart';
import 'package:uniun/features/shiv/rag/extraction/text_quality_gate.dart';

/// How one PDF page is read. Only pages that need it pay for OCR, and OCR text
/// never lands on top of a good text layer for the same area — each duplicate
/// chunk costs a full embedding.
sealed class PageReading {
  const PageReading();
}

/// The text layer is exact: use it.
final class UseTextLayer extends PageReading {
  const UseTextLayer();
}

/// Nothing to read — a blank page, or only a page number.
final class SkipPage extends PageReading {
  const SkipPage();
}

/// Render the page and read it with OCR. [keepLongerText]: a real text line
/// sits beside the image, so keep whichever of the two readings is longer
/// rather than joining them (they would repeat each other).
final class OcrWholePage extends PageReading {
  const OcrWholePage({this.keepLongerText = false});

  final bool keepLongerText;
}

/// Keep the text layer and also read the one large image in [region].
final class OcrRegion extends PageReading {
  const OcrRegion(this.region);

  final PdfBox region;
}

// Thresholds. Sourced ones say where from; the rest need measuring on real
// circulars (#242).

/// Below this a page is blank or holds only a page number (Apache Tika's
/// 10-character floor).
const int kBlankPageChars = 10;

/// More unmapped characters than this share means a broken font encoding
/// (Tika's "faster" preset).
const double kMaxUnmappedShare = 0.10;

/// A page this covered by images is a scan (bibr, measured on 630 PDFs with
/// no false positives).
const double kScannedPageCoverage = 0.85;

/// Below this many characters a scan's text layer is a stamp or header line,
/// not the page's content (the app's existing prose floor).
const int kScanTextFloor = kMinExtractedChars;

/// A page at least this covered by images but with little text is mostly a
/// picture. Unmeasured.
const double kMostlyImageCoverage = 0.5;

/// An image covering at least this share of a typed page is worth reading on
/// its own. Unmeasured.
const double kRegionImageCoverage = 0.25;

/// This many text-layer characters over an image mean it is a background —
/// letterhead or watermark — not content. Unmeasured.
const int kBackgroundTextChars = 20;

PageReading planPage(PdfPageSignals s) {
  // Blank only when there is neither text nor an image worth reading — a page
  // holding just a pasted photo must still reach the image rules below.
  if (s.chars < kBlankPageChars && s.imageCoverage < kRegionImageCoverage) {
    return const SkipPage();
  }
  final garbled =
      s.chars >= kBlankPageChars &&
      (s.letterRatio < kMinLetterRatio ||
          s.unmappedShare > kMaxUnmappedShare ||
          s.legacyFont);
  if (garbled) return const OcrWholePage();

  if (s.imageCoverage >= kScannedPageCoverage && s.chars < kScanTextFloor) {
    return const OcrWholePage();
  }
  if (s.imageCoverage >= kMostlyImageCoverage && s.chars < kScanTextFloor) {
    return const OcrWholePage(keepLongerText: true);
  }

  final image = s.largestImage;
  if (image != null &&
      s.largestImageCoverage >= kRegionImageCoverage &&
      s.charsInLargestImage < kBackgroundTextChars) {
    // A region is measured in unrotated page space; on a rotated page read
    // the whole page instead of mapping the rectangle.
    if (s.rotation != 0) return const OcrWholePage(keepLongerText: true);
    return OcrRegion(image);
  }
  return const UseTextLayer();
}
