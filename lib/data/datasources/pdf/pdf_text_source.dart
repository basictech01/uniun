import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:injectable/injectable.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uniun/data/datasources/pdf/pdf_page_signals.dart';
import 'package:uniun/data/datasources/pdf/pdfium_page_analysis.dart';

/// Resolution a page is rendered at for OCR. ML Kit wants characters of at
/// least 16 px; at 200 dpi a 10 pt letter is ~28 px and an 8 pt footnote ~22.
const int kOcrDpi = 200;

/// Longest side of an OCR render. Keeps a large-format page from allocating
/// hundreds of MB of pixels.
const int kMaxOcrPixels = 3000;

/// Reads a PDF: its text layer, one string per page; what each page is made
/// of; and page renders for OCR.
///
/// PDFium is touched only here and in `pdfium_page_analysis.dart`, so the
/// package stays replaceable and every other extraction unit is testable
/// without it.
///
/// Lives in `datasources/` for the same reason `AIModelRunner` does: it is an
/// adapter over an external package, not feature logic.
abstract class PdfTextSource {
  /// Page texts in page order, or `null` when [path] cannot be opened as a PDF.
  ///
  /// A page with no text layer yields an empty string rather than `null` — a
  /// scanned page is a readable PDF that happens to hold no text, which the
  /// quality gate decides about later. `null` is reserved for "this is not a
  /// PDF we can open at all".
  Future<List<String>?> pagesText(String path);

  /// What each page is made of, in page order — the evidence for deciding
  /// which pages need OCR — or `null` when [path] cannot be opened.
  Future<List<PdfPageSignals>?> pageSignals(String path);

  /// Renders page [pageIndex] — or just [region] of it — to a grayscale PNG
  /// for OCR and returns its path; the caller deletes the file. `null` when
  /// the page cannot be rendered.
  Future<String?> renderForOcr(String path, int pageIndex, {PdfBox? region});
}

@LazySingleton(as: PdfTextSource)
class PdfrxTextSource implements PdfTextSource {
  @override
  Future<List<String>?> pagesText(String path) async {
    PdfDocument? doc;
    try {
      doc = await PdfDocument.openFile(path);
      final pages = <String>[];
      for (final page in doc.pages) {
        final raw = await page.loadText();
        pages.add(raw?.fullText ?? '');
      }
      return pages;
    } catch (_) {
      // A corrupt, truncated, password-protected or non-PDF file is an expected
      // outcome for user-supplied content, not an error worth propagating.
      return null;
    } finally {
      await doc?.dispose();
    }
  }

  @override
  Future<List<PdfPageSignals>?> pageSignals(String path) async {
    PdfDocument? doc;
    try {
      doc = await PdfDocument.openFile(path);
      final handle = await doc.useNativeDocumentHandle((h) => h);
      // On pdfrx's own PDFium worker, never alongside another PDFium call.
      return await PdfrxEntryFunctions.instance.compute(analysePdfPages, (
        document: handle,
        pageCount: doc.pages.length,
      ));
    } catch (_) {
      return null;
    } finally {
      await doc?.dispose();
    }
  }

  @override
  Future<String?> renderForOcr(
    String path,
    int pageIndex, {
    PdfBox? region,
  }) async {
    PdfDocument? doc;
    PdfImage? image;
    try {
      doc = await PdfDocument.openFile(path);
      if (pageIndex < 0 || pageIndex >= doc.pages.length) return null;
      final page = doc.pages[pageIndex];
      var scale = kOcrDpi / 72;
      final longSide = math.max(page.width, page.height) * scale;
      if (longSide > kMaxOcrPixels) scale *= kMaxOcrPixels / longSide;

      // PDF space has its origin bottom-left; render space top-left.
      final x = region == null ? 0 : (region.left * scale).round();
      final y = region == null
          ? 0
          : ((page.height - region.top) * scale).round();
      final width = region == null
          ? (page.width * scale).round()
          : ((region.right - region.left) * scale).round();
      final height = region == null
          ? (page.height * scale).round()
          : ((region.top - region.bottom) * scale).round();
      if (width <= 0 || height <= 0) return null;

      image = await page.render(
        x: x,
        y: y,
        width: width,
        height: height,
        fullWidth: page.width * scale,
        fullHeight: page.height * scale,
        backgroundColor: 0xFFFFFFFF,
        annotationRenderingMode: PdfAnnotationRenderingMode.none,
        flags: PdfPageRenderFlags.grayscale,
      );
      if (image == null) return null;

      final pixels = Uint8List.fromList(image.pixels);
      final (w, h) = (image.width, image.height);
      final out =
          '${Directory.systemTemp.path}/uniun_ocr_'
          '${DateTime.now().microsecondsSinceEpoch}_$pageIndex.png';
      // Encoding a ~1650 × 2340 PNG takes long enough to drop frames.
      await Isolate.run(() {
        final gray = img.Image.fromBytes(
          width: w,
          height: h,
          bytes: pixels.buffer,
          numChannels: 4,
          order: img.ChannelOrder.bgra,
        ).convert(numChannels: 1);
        File(out).writeAsBytesSync(img.encodePng(gray));
      });
      return out;
    } catch (_) {
      return null;
    } finally {
      image?.dispose();
      await doc?.dispose();
    }
  }
}
