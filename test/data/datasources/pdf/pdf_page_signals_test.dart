import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uniun/data/datasources/pdf/pdf_page_signals.dart';
import 'package:uniun/data/datasources/pdf/pdf_text_source.dart';
import 'package:uniun/features/shiv/rag/extraction/page_ocr_plan.dart';

import '../../../_helpers/fake_path_provider.dart';
import '../../../_helpers/pdf_fixtures.dart';
import '../../../_helpers/pdfium_test_lib.dart';

/// Covers: PdfrxTextSource.pageSignals reading each page's structure through
/// PDFium — text, images, invisible layers, legacy fonts — over real PDFs, the
/// per-page plan those signals produce, and renderForOcr's page and region
/// renders.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  final source = PdfrxTextSource();

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('pdf_page_signals_test');
    PathProviderPlatform.instance =
        FakePathProviderPlatform(docs: tmp.path, support: tmp.path);
    await ensurePdfium();
    await pdfrxFlutterInitialize();
  });

  tearDownAll(() => tmp.delete(recursive: true));

  Future<String> write(String name, List<int> bytes) async {
    final f = File('${tmp.path}/$name');
    await f.writeAsBytes(bytes);
    return f.path;
  }

  Future<List<PdfPageSignals>> signals(String path) async =>
      (await source.pageSignals(path))!;

  const prose = 'The revised leave rules apply to every employee of the '
      'department from the first of October and replace the earlier order. ';

  group('real documents', () {
    test('a typed publication: text on every page, no images to read',
        () async {
      final pages = await signals(pdfFixture('nist_sp800-145.pdf'));

      expect(pages, hasLength(7));
      for (final p in pages.where((p) => p.chars > 0)) {
        expect(p.unmapped, 0);
        expect(p.invisible, 0);
        expect(p.legacyFont, isFalse);
        expect(p.letterRatio, greaterThan(0.5));
      }
      expect(pages.map(planPage).whereType<OcrWholePage>(), isEmpty,
          reason: 'no page of a typed publication needs OCR');
    });

    test('a scanned page: no text layer, one image covering the page',
        () async {
      final page = (await signals(pdfFixture('scanned_notice.pdf'))).single;

      expect(page.chars, 0);
      expect(page.imageCoverage, greaterThanOrEqualTo(0.85));
      expect(page.largestImage, isNotNull);
      expect(planPage(page), isA<OcrWholePage>());
    });

    test('a typed page with a pasted photo: read the text and the photo',
        () async {
      final page =
          (await signals(pdfFixture('typed_report_with_pasted_notice.pdf')))
              .single;

      expect(page.chars, greaterThan(500));
      expect(page.largestImageCoverage, inInclusiveRange(0.25, 0.5));
      expect(page.charsInLargestImage, lessThan(kBackgroundTextChars),
          reason: 'no text is drawn over the pasted photo');
      final plan = planPage(page);
      expect(plan, isA<OcrRegion>());
      final box = (plan as OcrRegion).region;
      expect(box.right, greaterThan(box.left));
      expect(box.top, greaterThan(box.bottom));
    });

    test('a mixed document is decided page by page', () async {
      final pages = await signals(
          pdfFixture('mixed_circular_with_scanned_annexure.pdf'));

      expect(pages.map(planPage).map((p) => p.runtimeType).toList(),
          [UseTextLayer, OcrWholePage]);
    });
  });

  group('image evidence', () {
    for (final inForm in [false, true]) {
      test('a picture ${inForm ? 'wrapped in a form' : 'drawn directly'} '
          'is measured where it is drawn', () async {
        final path = await write('image_$inForm.pdf', imagePdf(inForm: inForm));

        final page = (await signals(path)).single;

        expect(page.chars, 0);
        expect(page.largestImage, (
          left: 100.0,
          bottom: 200.0,
          right: 500.0,
          top: 600.0,
        ));
        expect(page.imageCoverage, closeTo(400 * 400 / (612 * 792), 0.001));
        expect(planPage(page), isA<OcrRegion>(),
            reason: 'a page holding only a photo is read, not skipped');
      });
    }
  });

  group('text-layer evidence', () {
    test('an invisible OCR layer is counted as invisible', () async {
      final path = await write(
          'invisible.pdf', minimalPdf([prose * 4], renderMode: 3));

      final page = (await signals(path)).single;

      expect(page.chars, greaterThan(200));
      expect(page.invisible, page.chars);
    });

    test('visible text is not', () async {
      final path = await write('visible.pdf', minimalPdf([prose * 4]));

      expect((await signals(path)).single.invisible, 0);
    });

    test('a legacy Hindi font is recognised by name', () async {
      final path = await write('kruti.pdf',
          minimalPdf([prose * 4], baseFont: 'KrutiDev010'));

      final page = (await signals(path)).single;

      expect(page.legacyFont, isTrue);
      expect(planPage(page), isA<OcrWholePage>(),
          reason: 'its letters are gibberish, however prose-like they look');
    });

    test('an ordinary font is not mistaken for a legacy one', () async {
      final path = await write('helvetica.pdf', minimalPdf([prose * 4]));

      expect((await signals(path)).single.legacyFont, isFalse);
    });

    test('a blank page reads as empty and is skipped', () async {
      final path = await write('blank.pdf', minimalPdf(['']));

      final page = (await signals(path)).single;

      expect(page.chars, 0);
      expect(page.imageCoverage, 0);
      expect(planPage(page), isA<SkipPage>());
    });
  });

  group('rendering for OCR', () {
    Future<img.Image> decode(String path) async =>
        img.decodePng(await File(path).readAsBytes())!;

    test('a whole page renders as a grayscale PNG at about 200 dpi', () async {
      final path =
          (await source.renderForOcr(pdfFixture('scanned_notice.pdf'), 0))!;

      final png = await decode(path);
      final page = (await signals(pdfFixture('scanned_notice.pdf'))).single;
      expect(png.width, closeTo(page.width * 200 / 72, 2));
      expect(png.numChannels, 1, reason: 'grayscale: a quarter of the memory');
      await File(path).delete();
    });

    test('a region renders just that rectangle', () async {
      final fixture = pdfFixture('typed_report_with_pasted_notice.pdf');
      final page = (await signals(fixture)).single;
      final box = page.largestImage!;

      final path = (await source.renderForOcr(fixture, 0, region: box))!;

      final png = await decode(path);
      const scale = 200 / 72;
      expect(png.width, closeTo((box.right - box.left) * scale, 2));
      expect(png.height, closeTo((box.top - box.bottom) * scale, 2));
      await File(path).delete();
    });

    test('a page number beyond the document renders nothing', () async {
      expect(await source.renderForOcr(pdfFixture('scanned_notice.pdf'), 5),
          isNull);
    });
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  group('unreadable input', () {
    test('a file that is not a PDF', () async {
      final path = await write('not.pdf', 'hello'.codeUnits);

      expect(await source.pageSignals(path), isNull);
      expect(await source.renderForOcr(path, 0), isNull);
    });

    test('a path that does not exist', () async {
      expect(await source.pageSignals('${tmp.path}/nope.pdf'), isNull);
    });
  });
}
