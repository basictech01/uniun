import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/domain/entities/shiv/document_citation.dart';
import 'package:uniun/features/shiv/chat/widgets/document_source_tile.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Covers: document source tile title, location (page for PDF, heading for
/// DOCX, "text in image" for images), snippet, per-kind icon or thumbnail,
/// untitled fallback, opening PDFs, Word files and images in the app's own
/// viewers, a removed file, and overflow safety.
void main() {
  Widget host(DocumentCitation c) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: DocumentSourceTile(citation: c)),
  );

  DocumentCitation citation({
    String? title,
    String label = '4',
    DocumentKind kind = DocumentKind.pdf,
  }) => DocumentCitation(
    chunkId: 's:0',
    sha256: 's',
    kind: kind,
    label: label,
    snippet: 'Employees may carry forward ten days of leave.',
    localPath: '/p/doc.pdf',
    title: title,
  );

  testWidgets('shows the title, the page and the passage', (t) async {
    await t.pumpWidget(host(citation(title: 'Leave Circular.pdf')));

    expect(find.text('Leave Circular.pdf'), findsOneWidget);
    expect(find.text('Page 4'), findsOneWidget);
    expect(
      find.text('Employees may carry forward ten days of leave.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
  });

  testWidgets('without a title it falls back to the generic label', (t) async {
    await t.pumpWidget(host(citation()));

    expect(find.text('PDF document'), findsOneWidget);
  });

  testWidgets('a DOCX shows its section, not a page, with a document icon', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        citation(
          title: 'Leave Policy.docx',
          label: 'Annual Leave',
          kind: DocumentKind.docx,
        ),
      ),
    );

    expect(find.text('Section: Annual Leave'), findsOneWidget);
    expect(find.textContaining('Page'), findsNothing);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNothing);
  });

  testWidgets('a DOCX without a title falls back to "Word document"', (
    t,
  ) async {
    await t.pumpWidget(
      host(citation(label: 'Annual Leave', kind: DocumentKind.docx)),
    );

    expect(find.text('Word document'), findsOneWidget);
  });

  testWidgets('each kind has its own open tooltip', (t) async {
    await t.pumpWidget(host(citation(kind: DocumentKind.docx)));
    expect(find.byTooltip('Open document'), findsOneWidget);

    await t.pumpWidget(host(citation()));
    expect(find.byTooltip('Open PDF'), findsOneWidget);
  });

  group('image', () {
    // Every case loads the same file path; a load left in flight by one test
    // would be reused by the next from Flutter's image cache and never finish.
    tearDown(() => imageCache.clear());

    DocumentCitation imageCitation({String? title, String? path}) =>
        DocumentCitation(
          chunkId: 'img:0',
          sha256: 'img',
          kind: DocumentKind.image,
          label: '',
          snippet: 'OFFICE ORDER — leave rules revised',
          localPath: path ?? '/nonexistent/img.png',
          title: title,
        );

    testWidgets('an image removed since the answer says so, not a spinner', (
      t,
    ) async {
      var opened = false;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) =>
                Scaffold(body: DocumentSourceTile(citation: imageCitation())),
          ),
          GoRoute(
            name: AppRoutes.mediaDetail,
            path: '/media/:sha256',
            builder: (_, __) {
              opened = true;
              return const Scaffold();
            },
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
      await t.pump();

      await t.tap(find.byType(DocumentSourceTile));
      await t.pump();

      expect(
        opened,
        isFalse,
        reason: 'the viewer never resolves a file that is gone',
      );
      expect(
        find.text('This image is no longer on this device'),
        findsOneWidget,
      );
    });

    testWidgets('the thumbnail is decoded at tile size, not full resolution', (
      t,
    ) async {
      await t.pumpWidget(host(imageCitation()));
      await t.pump();

      final image = t.widget<Image>(find.byType(Image));
      final provider = image.image as ResizeImage;
      expect(provider.width, isNotNull);
      expect(
        provider.width!,
        lessThanOrEqualTo(44 * 4),
        reason: 'a 12 MP photo must not be decoded for a 44 px square',
      );
    });

    testWidgets('shows a thumbnail and says the text came from the image', (
      t,
    ) async {
      await t.pumpWidget(host(imageCitation(title: 'notice.jpg')));
      await t.pump();

      expect(find.text('Found in image'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.textContaining('Page'), findsNothing);
      expect(find.textContaining('Section'), findsNothing);
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNothing);
    });

    testWidgets('a missing file falls back to an image icon, not a crash', (
      t,
    ) async {
      await t.pumpWidget(host(imageCitation()));
      // Image.file reads the disk outside the fake clock; keep letting that
      // real I/O run until it fails over to the fallback, rather than
      // guessing how long it takes under load.
      final fallback = find.byIcon(Icons.image_outlined);
      for (var i = 0; i < 50 && fallback.evaluate().isEmpty; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await t.pump();
      }

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('an untitled image is called "Image", with its own tooltip', (
      t,
    ) async {
      await t.pumpWidget(host(imageCitation()));
      await t.pump();

      expect(find.text('Image'), findsOneWidget);
      expect(find.byTooltip('Open image'), findsOneWidget);
    });

    testWidgets('tapping opens the image in the in-app viewer', (t) async {
      final dir = (await t.runAsync(
        () => Directory.systemTemp.createTemp('tile_img'),
      ))!;
      final file = File('${dir.path}/img.png')..writeAsBytesSync([0]);
      String? opened;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => Scaffold(
              body: DocumentSourceTile(
                citation: imageCitation(path: file.path),
              ),
            ),
          ),
          GoRoute(
            name: AppRoutes.mediaDetail,
            path: '/media/:sha256',
            builder: (_, state) {
              opened = state.pathParameters['sha256'];
              return const Scaffold(body: Text('viewer'));
            },
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

      await t.tap(find.byType(DocumentSourceTile));
      await t.pumpAndSettle();

      expect(opened, 'img');
      expect(find.text('viewer'), findsOneWidget);
    });
  });

  group('opening a PDF or Word file', () {
    late Directory dir;
    late File file;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('tile_doc');
      file = File('${dir.path}/doc.bin')..writeAsBytesSync([0]);
    });

    tearDown(() => dir.delete(recursive: true));

    DocumentCitation docCitation(
      DocumentKind kind,
      String label, {
      String? path,
    }) => DocumentCitation(
      chunkId: 'd:0',
      sha256: 'dsha',
      kind: kind,
      label: label,
      snippet: 'the cited passage',
      localPath: path ?? file.path,
      title: 'Doc',
    );

    Future<DocumentCitation?> tapAndCapture(
      WidgetTester t,
      DocumentCitation c,
    ) async {
      DocumentCitation? received;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => Scaffold(body: DocumentSourceTile(citation: c)),
          ),
          GoRoute(
            name: AppRoutes.documentViewer,
            path: '/document/:sha256',
            builder: (_, state) {
              received = state.extra as DocumentCitation;
              return const Scaffold(body: Text('viewer'));
            },
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
      await t.tap(find.byType(DocumentSourceTile));
      await t.pumpAndSettle();
      return received;
    }

    testWidgets('a PDF opens in the in-app viewer with its page', (t) async {
      final c = docCitation(DocumentKind.pdf, '5');

      final received = await tapAndCapture(t, c);

      expect(received, same(c));
      expect(find.text('viewer'), findsOneWidget);
    });

    testWidgets('a Word file opens in the in-app viewer with its heading', (
      t,
    ) async {
      final c = docCitation(DocumentKind.docx, 'Annual Leave');

      final received = await tapAndCapture(t, c);

      expect(received?.label, 'Annual Leave');
      expect(find.text('viewer'), findsOneWidget);
    });

    testWidgets('a removed PDF says so instead of opening a viewer', (t) async {
      final c = docCitation(
        DocumentKind.pdf,
        '5',
        path: '${dir.path}/gone.pdf',
      );

      final received = await tapAndCapture(t, c);

      expect(received, isNull);
      expect(
        find.text('This document is no longer on this device'),
        findsOneWidget,
      );
    });
  });

  testWidgets('a passage with no heading shows no location line', (t) async {
    await t.pumpWidget(
      host(citation(title: 'Memo.docx', label: '', kind: DocumentKind.docx)),
    );

    expect(find.textContaining('Section'), findsNothing);
    expect(find.textContaining('Page'), findsNothing);
    expect(
      find.text('Employees may carry forward ten days of leave.'),
      findsOneWidget,
    );
  });

  testWidgets('the Hindi locale localises the section line', (t) async {
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('hi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DocumentSourceTile(
            citation: citation(label: 'वार्षिक अवकाश', kind: DocumentKind.docx),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();

    expect(find.text('अनुभाग: वार्षिक अवकाश'), findsOneWidget);
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  testWidgets('a very long passage is clipped, not overflowing', (t) async {
    await t.pumpWidget(
      host(
        DocumentCitation(
          chunkId: 's:0',
          sha256: 's',
          kind: DocumentKind.pdf,
          label: '1',
          snippet: 'word ' * 400,
          localPath: '/p/doc.pdf',
        ),
      ),
    );

    expect(t.takeException(), isNull);
  });

  testWidgets('a 100-char heading wraps without overflowing', (t) async {
    await t.pumpWidget(
      host(
        citation(
          label: '${('Heading ' * 13).substring(0, 99)}…',
          kind: DocumentKind.docx,
        ),
      ),
    );

    expect(t.takeException(), isNull);
  });

  testWidgets('a very long title is clipped, not overflowing', (t) async {
    await t.pumpWidget(host(citation(title: 'circular-${'x' * 300}.pdf')));

    expect(t.takeException(), isNull);
  });

  testWidgets('unicode and RTL content render without error', (t) async {
    await t.pumpWidget(
      host(
        const DocumentCitation(
          chunkId: 's:0',
          sha256: 's',
          kind: DocumentKind.pdf,
          label: '२',
          snippet: 'भारत सरकार की नीति — مرحبا 😀',
          localPath: '/p/doc.pdf',
          title: 'परिपत्र.pdf',
        ),
      ),
    );

    expect(find.text('परिपत्र.pdf'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
