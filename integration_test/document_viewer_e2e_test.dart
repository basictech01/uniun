// Device test for the in-app citation viewer (#237): real PDFium on a phone
// renders a generated 8-page PDF and must land on the cited page; a generated
// Word file must show its cited section tinted and in view.
//
//   flutter test integration_test/document_viewer_e2e_test.dart -d <device-id>
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/data/datasources/docx/docx_text_source.dart';
import 'package:uniun/domain/entities/shiv/document_citation.dart';
import 'package:uniun/features/shiv/chat/widgets/document_source_tile.dart';
import 'package:uniun/features/shiv/document_viewer/pages/document_viewer_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../test/_helpers/docx_fixtures.dart';
import '../test/_helpers/pdf_fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUpAll(() async {
    await pdfrxFlutterInitialize();
    dir = await Directory.systemTemp.createTemp('viewer_e2e');
  });

  tearDownAll(() => dir.delete(recursive: true));

  Widget host(DocumentCitation c, {PdfBodyBuilder? pdfBody}) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: DocumentViewerPage(
      citation: c,
      docxSource: ArchiveDocxTextSource(),
      pdfBody: pdfBody ?? buildPdfViewer,
    ),
  );

  testWidgets('a PDF opens on the cited page on a real device', (t) async {
    final file = File('${dir.path}/eight.pdf')
      ..writeAsBytesSync(
        minimalPdf([
          for (var i = 1; i <= 8; i++) 'Page number $i of the file.',
        ]),
      );
    final controller = PdfViewerController();
    List<PdfPageTextRange>? highlights;

    await t.pumpWidget(
      host(
        DocumentCitation(
          chunkId: 's:0',
          sha256: 's',
          kind: DocumentKind.pdf,
          label: '6',
          snippet: 'Page number 6 of the file.',
          localPath: file.path,
          title: 'Eight pages',
        ),
        pdfBody: (path, page, snippet) => buildPdfViewer(
          path,
          page,
          snippet,
          controller: controller,
          onHighlights: (h) => highlights = h,
        ),
      ),
    );
    for (var i = 0; i < 100 && !controller.isReady; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    await t.pump(const Duration(seconds: 1));

    expect(controller.isReady, isTrue);
    expect(controller.pageNumber, 6);
    expect(highlights, isNotNull, reason: 'the cited page was searched');
    expect(
      highlights!.map((h) => h.pageNumber).toSet(),
      {6},
      reason: 'the cited passage is marked, on its own page only',
    );
  });

  testWidgets('a Word file shows its cited section tinted, on a device', (
    t,
  ) async {
    final file = File('${dir.path}/policy.docx')
      ..writeAsBytesSync(
        minimalDocx(
          document: wDocument(
            [
              for (var i = 0; i < 25; i++) ...[
                wP('Chapter $i', style: 'Heading1'),
                wP('Body of chapter $i. ' * 30),
              ],
              wP('Leave', style: 'Heading1'),
              wP('Ten days of leave may be carried forward.'),
            ].join(),
          ),
          styles: englishHeadingStyles,
        ),
      );

    await t.pumpWidget(
      host(
        DocumentCitation(
          chunkId: 'd:0',
          sha256: 'd',
          kind: DocumentKind.docx,
          label: 'Leave',
          snippet: 'Ten days of leave may be carried forward.',
          localPath: file.path,
          title: 'Policy',
        ),
      ),
    );
    await t.pumpAndSettle(const Duration(milliseconds: 200));

    final cited = find.textContaining('Ten days of leave');
    expect(cited, findsOneWidget);
    final top = t.getRect(cited).top;
    expect(
      top,
      lessThan(t.view.physicalSize.height / t.view.devicePixelRatio),
      reason: 'the cited section is scrolled into view',
    );
    expect(
      t.getRect(find.textContaining('Chapter 0').first).bottom,
      lessThan(0),
      reason: 'the top of a long document is scrolled above the screen',
    );
  });

  testWidgets('tapping a Sources tile opens the viewer on the cited page', (
    t,
  ) async {
    final file = File('${dir.path}/tap.pdf')
      ..writeAsBytesSync(
        minimalPdf([
          for (var i = 1; i <= 8; i++) 'Page number $i of the file.',
        ]),
      );
    final controller = PdfViewerController();
    final citation = DocumentCitation(
      chunkId: 's:0',
      sha256: 's',
      kind: DocumentKind.pdf,
      label: '3',
      snippet: 'Page number 3 of the file.',
      localPath: file.path,
      title: 'Eight pages',
    );
    // The same route shape app_router.dart declares: the citation rides as extra.
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              Scaffold(body: DocumentSourceTile(citation: citation)),
        ),
        GoRoute(
          name: AppRoutes.documentViewer,
          path: '/document/:sha256',
          builder: (_, state) => DocumentViewerPage(
            citation: state.extra! as DocumentCitation,
            pdfBody: (path, page, snippet) =>
                buildPdfViewer(path, page, snippet, controller: controller),
          ),
        ),
      ],
    );
    await t.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Page 3'), findsOneWidget);

    await t.tap(find.byType(DocumentSourceTile));
    await t.pumpAndSettle();
    for (var i = 0; i < 100 && !controller.isReady; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    await t.pump(const Duration(seconds: 1));

    expect(find.byType(DocumentViewerPage), findsOneWidget);
    expect(controller.pageNumber, 3);
  });

  testWidgets(
    'a Word file with a table and a picture shows both, on a device',
    (t) async {
      final png = img.encodePng(img.Image(width: 1200, height: 800));
      final file = File('${dir.path}/rich.docx')
        ..writeAsBytesSync(
          minimalDocx(
            document: wDocument(
              wP('Rates', style: 'Heading1') +
                  wTable([
                    ['Meals', '800 rupees'],
                    ['Hotel', '2500 rupees'],
                  ]) +
                  wDrawing('rId1') +
                  wP('Claims are due within 30 days.'),
            ),
            styles: englishHeadingStyles,
            extra: {
              'word/_rels/document.xml.rels': wRels({
                'rId1': 'media/image1.png',
              }),
            },
            media: {'word/media/image1.png': png},
          ),
        );

      await t.pumpWidget(
        host(
          DocumentCitation(
            chunkId: 'd:0',
            sha256: 'd',
            kind: DocumentKind.docx,
            label: 'Rates',
            snippet: 'Meals | 800 rupees',
            localPath: file.path,
            title: 'Rich',
          ),
        ),
      );
      await t.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.byType(Table), findsOneWidget);
      expect(find.text('2500 rupees'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.textContaining('due within 30 days'), findsOneWidget);
    },
  );
}
