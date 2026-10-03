import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/domain/entities/shiv/document_citation.dart';
import 'package:uniun/features/shiv/document_viewer/pages/document_viewer_page.dart';
import 'package:uniun/features/shiv/document_viewer/widgets/docx_section_view.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../../../_helpers/fake_docx_text_source.dart';

/// Covers: DocumentViewerPage opening a PDF on its cited page and a Word file
/// on its heading's section (scrolled to and tinted), the external-viewer
/// action, a removed file, an unreadable Word file, and long documents.
void main() {
  late Directory dir;
  late File file;
  late FakeDocxTextSource docx;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('viewer_page');
    file = File('${dir.path}/doc.bin')..writeAsBytesSync([0]);
    docx = FakeDocxTextSource();
  });

  tearDown(() => dir.delete(recursive: true));

  DocumentCitation citation({
    required DocumentKind kind,
    String label = '4',
    String? title = 'Leave Circular',
    String? path,
    String snippet = 'ten days may be carried forward',
  }) => DocumentCitation(
    chunkId: 's:0',
    sha256: 's',
    kind: kind,
    label: label,
    snippet: snippet,
    localPath: path ?? file.path,
    title: title,
  );

  /// The cubit creates a temp folder (real I/O, outside the fake clock), so
  /// let real time pass until the spinner is gone, then settle animations.
  Future<void> loaded(WidgetTester t) async {
    for (
      var i = 0;
      i < 100 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      i++
    ) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pump(const Duration(milliseconds: 50));
    }
    await t.pumpAndSettle();
  }

  Future<void> show(
    WidgetTester t,
    DocumentCitation c, {
    PdfBodyBuilder? pdfBody,
  }) => t.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DocumentViewerPage(
        citation: c,
        docxSource: docx,
        pdfBody: pdfBody ?? (p, n, snippet) => Text('pdf $p page $n'),
      ),
    ),
  );

  group('PDF', () {
    testWidgets('opens on the cited page', (t) async {
      await show(t, citation(kind: DocumentKind.pdf, label: '7'));

      expect(find.text('pdf ${file.path} page 7'), findsOneWidget);
    });

    testWidgets('a label that is not a number opens on page 1', (t) async {
      await show(t, citation(kind: DocumentKind.pdf, label: ''));

      expect(find.text('pdf ${file.path} page 1'), findsOneWidget);
    });

    testWidgets('shows the title and offers the other-app action', (t) async {
      await show(t, citation(kind: DocumentKind.pdf));

      expect(find.text('Leave Circular'), findsOneWidget);
      expect(find.byTooltip('Open in another app'), findsOneWidget);
    });

    testWidgets('an untitled PDF falls back to the generic name', (t) async {
      await show(t, citation(kind: DocumentKind.pdf, title: null));

      expect(find.text('PDF document'), findsOneWidget);
    });

    testWidgets('a file removed since the answer says so', (t) async {
      await show(
        t,
        citation(kind: DocumentKind.pdf, path: '${dir.path}/gone.pdf'),
      );

      expect(
        find.text('This document is no longer on this device'),
        findsOneWidget,
      );
      expect(find.textContaining('pdf '), findsNothing);
      expect(
        find.byTooltip('Open in another app'),
        findsNothing,
        reason: 'there is nothing to hand over',
      );
    });
  });

  group('Word', () {
    testWidgets('shows every section and tints the cited one', (t) async {
      docx.sections[file.path] = [
        (label: 'Intro', text: 'Intro\n\nwelcome'),
        (label: 'Leave', text: 'Leave\n\nten days may be carried forward'),
      ];

      await show(t, citation(kind: DocumentKind.docx, label: 'Leave'));
      await loaded(t);

      expect(find.textContaining('welcome'), findsOneWidget);
      expect(find.textContaining('ten days'), findsOneWidget);
      final tinted = t
          .widgetList<Container>(find.byType(Container))
          .where(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color ==
                    Theme.of(
                      t.element(find.byType(DocxSectionView)),
                    ).colorScheme.primaryContainer,
          );
      expect(tinted, hasLength(1));
      expect(
        find.text(
          'Text, tables and large pictures — open in another app for the full layout',
        ),
        findsOneWidget,
      );
    });

    testWidgets('scrolls a section far down the document into view', (t) async {
      docx.sections[file.path] = [
        for (var i = 0; i < 40; i++)
          (label: 'S$i', text: 'S$i\n\n${'filler line\n' * 12}'),
        (label: 'Leave', text: 'Leave\n\nten days may be carried forward'),
      ];

      await show(t, citation(kind: DocumentKind.docx, label: 'Leave'));
      await loaded(t);

      expect(
        find.textContaining('ten days may be carried forward'),
        findsOneWidget,
        reason: 'it is built and on screen, not left below the fold',
      );
      final box = t.getRect(find.textContaining('ten days may be carried'));
      expect(
        box.top,
        lessThan(t.view.physicalSize.height / t.view.devicePixelRatio),
      );
    });

    testWidgets('a heading that cannot be placed opens at the top, untinted', (
      t,
    ) async {
      docx.sections[file.path] = [(label: 'Intro', text: 'Intro\n\nwelcome')];

      await show(t, citation(kind: DocumentKind.docx, label: 'Gone'));
      await loaded(t);

      expect(find.textContaining('welcome'), findsOneWidget);
    });

    testWidgets('an unreadable Word file says so', (t) async {
      await show(t, citation(kind: DocumentKind.docx, label: 'Leave'));
      await loaded(t);

      expect(
        find.text('This document could not be opened here'),
        findsOneWidget,
      );
    });

    testWidgets('Devanagari text renders', (t) async {
      docx.sections[file.path] = [
        (label: 'अवकाश', text: 'अवकाश\n\nदस दिन आगे ले जा सकते हैं।'),
      ];

      await show(
        t,
        citation(kind: DocumentKind.docx, label: 'अवकाश', snippet: 'दस दिन'),
      );
      await loaded(t);

      expect(find.textContaining('दस दिन आगे'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });
}
