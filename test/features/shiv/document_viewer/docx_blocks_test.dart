import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uniun/data/datasources/docx/docx_text_source.dart';
import 'package:uniun/features/shiv/document_viewer/widgets/docx_section_view.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Covers: docxBlocks splitting a section into text, table and picture blocks,
/// and DocxSectionView drawing a table as a grid and a picture as an image.
void main() {
  group('docxBlocks', () {
    test('paragraphs become text blocks', () {
      final b = docxBlocks('First paragraph.\n\nSecond paragraph.');

      expect(b.map((x) => (x as DocxText).text), [
        'First paragraph.',
        'Second paragraph.',
      ]);
    });

    test('rows joined by a pipe become one table', () {
      final b = docxBlocks('Meals | 800 rupees\nHotel | 2500 rupees');

      final t = b.single as DocxTable;
      expect(t.rows, [
        ['Meals', '800 rupees'],
        ['Hotel', '2500 rupees'],
      ]);
    });

    test('a table between paragraphs keeps its place', () {
      final b = docxBlocks('Rates\n\nMeals | 800\n\nSubmit within 30 days.');

      expect(b.map((x) => x.runtimeType), [DocxText, DocxTable, DocxText]);
    });

    test('a picture marker becomes a picture block where it sat', () {
      final b = docxBlocks('Before\n${docxImageMarker('/tmp/a.png')}\nAfter');

      expect(b.map((x) => x.runtimeType), [DocxText, DocxPicture, DocxText]);
      expect((b[1] as DocxPicture).path, '/tmp/a.png');
    });

    test('a single line with a spaced pipe is read as a one-row table', () {
      // The reader writes a table row exactly this way, so a prose line using
      // " | " cannot be told apart. A pipe without spaces is left alone.
      expect(docxBlocks('Meals | 800').single, isA<DocxTable>());
      expect(docxBlocks('Use the|symbol here.').single, isA<DocxText>());
    });

    test('a block with only some pipe lines stays text', () {
      expect(docxBlocks('a | b\nplain line').single, isA<DocxText>());
    });

    test('empty text has no blocks', () {
      expect(docxBlocks(''), isEmpty);
      expect(docxBlocks('\n\n  \n\n'), isEmpty);
    });

    test('Devanagari cells survive', () {
      final t = docxBlocks('शुल्क | 20 रुपये').single as DocxTable;

      expect(t.rows.single, ['शुल्क', '20 रुपये']);
    });
  });

  group('DocxSectionView', () {
    late Directory dir;

    setUp(() async => dir = await Directory.systemTemp.createTemp('blocks'));
    tearDown(() async {
      imageCache.clear();
      await dir.delete(recursive: true);
    });

    Widget host(List<DocxSection> sections) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: DocxSectionView(sections: sections)),
    );

    testWidgets('a table is drawn as a grid of cells', (t) async {
      await t.pumpWidget(
        host([(label: 'Rates', text: 'Rates\n\nMeals | 800\nHotel | 2500')]),
      );

      expect(find.byType(Table), findsOneWidget);
      expect(find.text('Meals'), findsOneWidget);
      expect(find.text('2500'), findsOneWidget);
    });

    testWidgets('a short row is padded, not a crash', (t) async {
      await t.pumpWidget(host([(label: 'R', text: 'a | b | c\nd | e')]));

      expect(find.byType(Table), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('a picture is drawn inline', (t) async {
      final file = File('${dir.path}/p.png')
        ..writeAsBytesSync(img.encodePng(img.Image(width: 20, height: 10)));

      await t.pumpWidget(
        host([(label: 'S', text: 'S\n${docxImageMarker(file.path)}\ntext')]),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('a picture whose file is gone is skipped, not a crash', (
      t,
    ) async {
      await t.pumpWidget(
        host([(label: 'S', text: docxImageMarker('${dir.path}/gone.png'))]),
      );
      for (var i = 0; i < 20; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await t.pump();
      }

      expect(t.takeException(), isNull);
    });
  });
}
