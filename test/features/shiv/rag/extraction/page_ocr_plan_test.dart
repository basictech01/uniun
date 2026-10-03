import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/data/datasources/pdf/pdf_page_signals.dart';
import 'package:uniun/features/shiv/rag/extraction/page_ocr_plan.dart';

/// Covers: planPage's per-page choice between the text layer, OCR of the whole
/// page, OCR of one embedded image, or skipping — every rule and its
/// boundaries.
void main() {
  /// An A4 page (595 × 842 pt) with [chars] clean letters and nothing else.
  PdfPageSignals page({
    int chars = 2000,
    int? letters,
    int unmapped = 0,
    int invisible = 0,
    bool legacyFont = false,
    double imageCoverage = 0,
    PdfBox? largestImage,
    double largestImageCoverage = 0,
    int charsInLargestImage = 0,
    int rotation = 0,
  }) =>
      PdfPageSignals(
        width: 595,
        height: 842,
        rotation: rotation,
        chars: chars,
        letters: letters ?? (chars * 0.8).round(),
        unmapped: unmapped,
        invisible: invisible,
        legacyFont: legacyFont,
        imageCoverage: imageCoverage,
        largestImage: largestImage,
        largestImageCoverage: largestImageCoverage,
        charsInLargestImage: charsInLargestImage,
      );

  const halfPage = (left: 50.0, bottom: 100.0, right: 545.0, top: 500.0);

  group('the text layer is used', () {
    test('a typed page with plenty of text', () {
      expect(planPage(page()), isA<UseTextLayer>());
    });

    test('a typed page with a small logo or signature', () {
      expect(
        planPage(page(
          imageCoverage: 0.04,
          largestImage: (left: 40, bottom: 760, right: 120, top: 820),
          largestImageCoverage: 0.04,
        )),
        isA<UseTextLayer>(),
      );
    });

    test('a scan whose invisible OCR layer reads as good prose is trusted',
        () {
      expect(
        planPage(page(chars: 1500, invisible: 1500, imageCoverage: 0.98)),
        isA<UseTextLayer>(),
      );
    });

    test('a large image with text drawn over it is a background', () {
      expect(
        planPage(page(
          imageCoverage: 0.4,
          largestImage: halfPage,
          largestImageCoverage: 0.4,
          charsInLargestImage: 600,
        )),
        isA<UseTextLayer>(),
      );
    });
  });

  group('the page is skipped', () {
    test('a blank page', () {
      expect(planPage(page(chars: 0)), isA<SkipPage>());
    });

    test('a page with only a page number', () {
      expect(planPage(page(chars: 3)), isA<SkipPage>());
    });

    test('a page holding only a tiny logo is still blank', () {
      expect(
        planPage(page(
          chars: 0,
          imageCoverage: 0.03,
          largestImage: (left: 40, bottom: 760, right: 120, top: 820),
          largestImageCoverage: 0.03,
        )),
        isA<SkipPage>(),
      );
    });
  });

  group('a page holding only a photo', () {
    test('a medium photo with no text is read, not skipped', () {
      expect(
        planPage(page(
          chars: 0,
          imageCoverage: 0.3,
          largestImage: halfPage,
          largestImageCoverage: 0.3,
        )),
        isA<OcrRegion>(),
      );
    });
  });

  group('the whole page is read with OCR', () {
    test('a scanned page with no text layer', () {
      final plan = planPage(page(chars: 0, imageCoverage: 1));

      expect(plan, isA<OcrWholePage>());
      expect((plan as OcrWholePage).keepLongerText, isFalse);
    });

    test('a scan with a short stamp line still gets read', () {
      expect(planPage(page(chars: 40, imageCoverage: 0.95)),
          isA<OcrWholePage>());
    });

    test('a garbled text layer (few letters) is replaced', () {
      final plan = planPage(page(chars: 800, letters: 60));

      expect((plan as OcrWholePage).keepLongerText, isFalse);
    });

    test('a broken font encoding (many unmapped characters) is replaced', () {
      expect(planPage(page(chars: 800, unmapped: 120)), isA<OcrWholePage>());
    });

    test('a legacy Hindi font is replaced even though it looks like letters',
        () {
      expect(planPage(page(chars: 900, legacyFont: true)), isA<OcrWholePage>());
    });

    test('a mostly-image page with only a header line keeps the better text',
        () {
      final plan = planPage(page(chars: 60, imageCoverage: 0.6));

      expect((plan as OcrWholePage).keepLongerText, isTrue);
    });
  });

  group('one embedded image is read with OCR', () {
    test('a typed page with a large pasted image and no text over it', () {
      final plan = planPage(page(
        imageCoverage: 0.4,
        largestImage: halfPage,
        largestImageCoverage: 0.4,
      ));

      expect(plan, isA<OcrRegion>());
      expect((plan as OcrRegion).region, halfPage);
    });

    test('a rotated page is read whole instead — regions assume no rotation',
        () {
      expect(
        planPage(page(
          rotation: 1,
          imageCoverage: 0.4,
          largestImage: halfPage,
          largestImageCoverage: 0.4,
        )),
        isA<OcrWholePage>(),
      );
    });
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  group('boundaries', () {
    test('9 characters is blank; 10 is not', () {
      expect(planPage(page(chars: 9)), isA<SkipPage>());
      expect(planPage(page(chars: 10)), isNot(isA<SkipPage>()));
    });

    test('image coverage 0.85 is a scan; just below is not', () {
      expect(planPage(page(chars: 250, imageCoverage: 0.85)),
          isA<UseTextLayer>(),
          reason: 'a scan with 250 real characters keeps its layer');
      expect(planPage(page(chars: 150, imageCoverage: 0.85)),
          isA<OcrWholePage>());
      expect(
        (planPage(page(chars: 150, imageCoverage: 0.84)) as OcrWholePage)
            .keepLongerText,
        isTrue,
        reason: 'below 0.85 it is a mostly-image page, not a pure scan',
      );
    });

    test('an image covering exactly a quarter of the page is read', () {
      expect(
        planPage(page(
          imageCoverage: 0.25,
          largestImage: halfPage,
          largestImageCoverage: 0.25,
        )),
        isA<OcrRegion>(),
      );
      expect(
        planPage(page(
          imageCoverage: 0.24,
          largestImage: halfPage,
          largestImageCoverage: 0.24,
        )),
        isA<UseTextLayer>(),
      );
    });

    test('19 characters over an image still counts as content; 20 does not',
        () {
      PdfPageSignals over(int n) => page(
            imageCoverage: 0.4,
            largestImage: halfPage,
            largestImageCoverage: 0.4,
            charsInLargestImage: n,
          );
      expect(planPage(over(19)), isA<OcrRegion>());
      expect(planPage(over(20)), isA<UseTextLayer>());
    });

    test('exactly 10 % unmapped is tolerated; more is not', () {
      expect(planPage(page(chars: 1000, unmapped: 100)), isA<UseTextLayer>());
      expect(planPage(page(chars: 1000, unmapped: 101)), isA<OcrWholePage>());
    });

    test('a garbled page wins over the region rule', () {
      expect(
        planPage(page(
          chars: 800,
          letters: 40,
          imageCoverage: 0.4,
          largestImage: halfPage,
          largestImageCoverage: 0.4,
        )),
        isA<OcrWholePage>(),
      );
    });
  });
}
