import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/data/datasources/pdf/pdf_text_source.dart';
import 'package:uniun/domain/entities/shiv/document_citation.dart';
import 'package:uniun/features/shiv/document_viewer/pages/document_viewer_page.dart';
import 'package:uniun/features/shiv/document_viewer/widgets/cited_pdf_viewer.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../../../_helpers/fake_path_provider.dart';
import '../../../_helpers/pdf_fixtures.dart';
import '../../../_helpers/pdfium_test_lib.dart';

/// Covers: the real PDF viewer, over real PDFium and a committed 7-page PDF,
/// landing on the cited page rather than page 1 and highlighting the cited
/// passage (and nothing for text that is not in the file).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('pdf_landing');
    PathProviderPlatform.instance = FakePathProviderPlatform(
      docs: tmp.path,
      support: tmp.path,
    );
    await ensurePdfium();
    await pdfrxFlutterInitialize();
  });

  tearDownAll(() => tmp.delete(recursive: true));

  Future<int> landedOn(WidgetTester t, String label) async {
    final controller = PdfViewerController();
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DocumentViewerPage(
          citation: DocumentCitation(
            chunkId: 's:0',
            sha256: 's',
            kind: DocumentKind.pdf,
            label: label,
            snippet: 'x',
            localPath: pdfFixture('nist_sp800-145.pdf'),
          ),
          pdfBody: (path, page, snippet) =>
              buildPdfViewer(path, page, snippet, controller: controller),
        ),
      ),
    );
    // PDFium loads on real threads, outside the fake clock.
    for (var i = 0; i < 100 && !controller.isReady; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(
      controller.isReady,
      isTrue,
      reason: 'the PDF never finished loading',
    );
    // Let the viewer settle: it corrects an out-of-range start page itself.
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await t.pump(const Duration(milliseconds: 500));
    final landed = controller.pageNumber!;
    // pdfrx schedules work on timers and worker threads that outlive the
    // widget; drain both before the test ends.
    await t.pumpWidget(const SizedBox());
    for (var i = 0; i < 6; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await t.pump(const Duration(milliseconds: 500));
    }
    return landed;
  }

  testWidgets('opens on the cited page, not page 1', (t) async {
    expect(await landedOn(t, '5'), 5);
  });

  testWidgets(
    'a page beyond the document ends on a real page (pdfrx corrects it)',
    (t) async {
      final page = await landedOn(t, '99');

      expect(page, inInclusiveRange(1, 7));
      expect(t.takeException(), isNull);
    },
  );

  /// Opens the NIST PDF on [label] citing [snippet]; returns the highlighted
  /// ranges once the cited page has been searched.
  Future<List<PdfPageTextRange>> highlightsFor(
    WidgetTester t,
    String label,
    String snippet,
  ) async {
    final controller = PdfViewerController();
    List<PdfPageTextRange>? highlights;
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DocumentViewerPage(
          citation: DocumentCitation(
            chunkId: 's:0',
            sha256: 's',
            kind: DocumentKind.pdf,
            label: label,
            snippet: snippet,
            localPath: pdfFixture('nist_sp800-145.pdf'),
          ),
          pdfBody: (path, page, snip) => buildPdfViewer(
            path,
            page,
            snip,
            controller: controller,
            onHighlights: (h) => highlights = h,
          ),
        ),
      ),
    );
    for (var i = 0; i < 100 && highlights == null; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(highlights, isNotNull, reason: 'the cited page was never searched');
    return highlights!;
  }

  Future<void> drain(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    for (var i = 0; i < 6; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await t.pump(const Duration(milliseconds: 500));
    }
  }

  group('highlighting the cited passage', () {
    late String phrase;
    late int page;

    setUpAll(() async {
      // A passage taken from the file itself, as a chunk is.
      final pages = (await PdfrxTextSource().pagesText(
        pdfFixture('nist_sp800-145.pdf'),
      ))!;
      page = pages.indexWhere((p) => p.contains('Cloud computing is a model'));
      final text = pages[page];
      final at = text.indexOf('Cloud computing is a model');
      phrase = text.substring(at, at + 120);
    });

    testWidgets('the passage is found and marked on its own page', (t) async {
      final found = await highlightsFor(t, '${page + 1}', phrase);

      expect(found, hasLength(1));
      expect(found.single.pageNumber, page + 1);
      expect(found.single.bounds.width, greaterThan(0));
      await drain(t);
    });

    testWidgets('a passage that is not on the cited page marks nothing', (
      t,
    ) async {
      // The phrase exists on [page] only; citing another page must not
      // highlight a look-alike elsewhere.
      final other = page == 0 ? 2 : 1;

      final found = await highlightsFor(t, '${other + 1}', phrase);

      expect(found, isEmpty);
      expect(t.takeException(), isNull);
      await drain(t);
    });

    testWidgets('text that is not in the file marks nothing', (t) async {
      final found = await highlightsFor(
        t,
        '1',
        'a sentence that no page of this document contains',
      );

      expect(found, isEmpty);
      await drain(t);
    });

    testWidgets('highlighting does not move the reader off the cited page', (
      t,
    ) async {
      final controller = PdfViewerController();
      List<PdfPageTextRange>? done;
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DocumentViewerPage(
            citation: DocumentCitation(
              chunkId: 's:0',
              sha256: 's',
              kind: DocumentKind.pdf,
              label: '${page + 1}',
              snippet: phrase,
              localPath: pdfFixture('nist_sp800-145.pdf'),
            ),
            pdfBody: (path, pg, snip) => buildPdfViewer(
              path,
              pg,
              snip,
              controller: controller,
              onHighlights: (h) => done = h,
            ),
          ),
        ),
      );
      for (var i = 0; i < 100 && done == null; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await t.pump(const Duration(milliseconds: 200));
      }

      expect(controller.pageNumber, page + 1);
      await drain(t);
    });
  });

  group('painting the highlight', () {
    late PdfDocument doc;
    late List<PdfPageTextRange> ranges;

    setUpAll(() async {
      registerFallbackValue(Rect.zero);
      registerFallbackValue(Paint());
      doc = await PdfDocument.openFile(pdfFixture('nist_sp800-145.pdf'));
      final text = await doc.pages[5].loadStructuredText();
      ranges = await text.allMatches('Cloud computing is a model').toList();
    });

    tearDownAll(() => doc.dispose());

    test('a range is filled on its own page, inside the page rectangle', () {
      final canvas = _MockCanvas();
      const pageRect = Rect.fromLTWH(10, 20, 400, 560);

      paintHighlights(canvas, pageRect, doc.pages[5], ranges);

      final rect =
          verify(() => canvas.drawRect(captureAny(), any())).captured.single
              as Rect;
      expect(pageRect.contains(rect.topLeft), isTrue);
      expect(rect.width, greaterThan(0));
    });

    test('it is not painted on any other page', () {
      final canvas = _MockCanvas();

      paintHighlights(
        canvas,
        const Rect.fromLTWH(0, 0, 400, 560),
        doc.pages[2],
        ranges,
      );

      verifyNever(() => canvas.drawRect(any(), any()));
    });

    test('no ranges paint nothing', () {
      final canvas = _MockCanvas();

      paintHighlights(
        canvas,
        const Rect.fromLTWH(0, 0, 400, 560),
        doc.pages[5],
        const [],
      );

      verifyNever(() => canvas.drawRect(any(), any()));
    });
  });
}

class _MockCanvas extends Mock implements Canvas {}
