import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:uniun/data/datasources/docx/docx_text_source.dart';

import '../../../_helpers/docx_fixtures.dart';

/// Covers: ArchiveDocxTextSource against real Word/LibreOffice output and exact
/// in-test packages — heading detection, reading order, excluded markup,
/// which embedded pictures are extracted for OCR, and every unreadable input.
void main() {
  final source = ArchiveDocxTextSource();

  Future<List<DocxSection>?> read(List<int> bytes) async =>
      source.sectionsText(await writeTempDocx(bytes));

  Future<List<DocxSection>?> readBody(String body, {String? styles}) =>
      read(minimalDocx(document: wDocument(body), styles: styles));

  List<String> labels(List<DocxSection>? s) => [for (final x in s!) x.label];
  String allText(List<DocxSection>? s) => s!.map((x) => x.text).join('\n');

  group('real documents', () {
    test('LibreOffice headings become section labels in order', () async {
      final s = await source.sectionsText(
          docxFixture('leave-policy-libreoffice.docx'));

      expect(labels(s),
          ['', 'Annual Leave', 'Sick Leave', 'Remote Work', 'Travel and Expenses']);
      expect(s![0].text, contains('applies to every UNIUN team member'));
      expect(s[1].text, startsWith('Annual Leave'),
          reason: 'the heading stays in its section for the embedder');
      expect(s[1].text, contains('24 days of paid annual leave'));
      expect(s[4].text, contains('within 30 days of the expense'));
      expect(s[4].text, contains('Meals | 800 rupees'),
          reason: 'the table belongs to the section it sits in');
    });

    test('Word content controls are read, not dropped', () async {
      final s = await source.sectionsText(
          docxFixture('uspto-initial-filing-template.docx'));

      final text = allText(s);
      expect(text, contains('Choose a Claims Section Header'),
          reason: 'this text exists only inside a block-level w:sdt');
      expect(text, contains('Insert your claims in this section'));
    });

    test('custom header styles that are not headings give no label', () async {
      final s = await source.sectionsText(
          docxFixture('uspto-initial-filing-template.docx'));

      expect(labels(s), ['']);
    });

    test('a table-heavy form yields its text without field codes', () async {
      final s = await source.sectionsText(
          docxFixture('nist-cui-ssp-template.docx'));

      final text = allText(s);
      expect(text, contains('SYSTEM IDENTIFICATION'));
      expect(text, contains('Office Address: |'),
          reason: 'table cells are joined per row');
      expect(text, isNot(contains('FORMCHECKBOX')),
          reason: '330 field codes in this file must not leak into the text');
    });

    test('an outline level set directly on a paragraph makes a heading',
        () async {
      final s = await source.sectionsText(
          docxFixture('nist-cui-ssp-template.docx'));

      expect(labels(s), ['', 'Roles of Users and Number of Each Type:']);
    });

    test('reading the same file twice gives the same result', () async {
      final path = docxFixture('leave-policy-libreoffice.docx');

      expect(await source.sectionsText(path), await source.sectionsText(path));
    });
  });

  group('headings', () {
    test('Word heading styles start sections; text above the first is unlabelled',
        () async {
      final s = await readBody(
        wP('Preamble text.') +
            wP('Scope', style: 'Heading1') +
            wP('Scope body.') +
            wP('Details', style: 'Heading2') +
            wP('Details body.'),
        styles: englishHeadingStyles,
      );

      expect(s, [
        (label: '', text: 'Preamble text.'),
        (label: 'Scope', text: 'Scope\n\nScope body.'),
        (label: 'Details', text: 'Details\n\nDetails body.'),
      ]);
    });

    test('the Title style is a heading', () async {
      final s = await readBody(
        wP('Leave Policy', style: 'Title') + wP('Body.'),
        styles: englishHeadingStyles,
      );

      expect(labels(s), ['Leave Policy']);
    });

    test('a localised style id is recognised by its name', () async {
      final s = await readBody(
        wP('Geltungsbereich', style: 'berschrift1') + wP('Text.'),
        styles: wStyles([
          (id: 'berschrift1', name: 'heading 1', basedOn: null, outline: null),
        ]),
      );

      expect(labels(s), ['Geltungsbereich']);
    });

    test('style names match case-insensitively', () async {
      final s = await readBody(
        wP('Scope', style: 'H1') + wP('Text.'),
        styles: wStyles(
            [(id: 'H1', name: 'Heading 1', basedOn: null, outline: null)]),
      );

      expect(labels(s), ['Scope']);
    });

    test('a style based on a heading style is a heading', () async {
      final s = await readBody(
        wP('Scope', style: 'Fancy') + wP('Text.'),
        styles: wStyles([
          (id: 'Heading1', name: 'heading 1', basedOn: null, outline: null),
          (id: 'Mid', name: 'Mid', basedOn: 'Heading1', outline: null),
          (id: 'Fancy', name: 'Fancy', basedOn: 'Mid', outline: null),
        ]),
      );

      expect(labels(s), ['Scope']);
    });

    test('a style with an outline level is a heading', () async {
      final s = await readBody(
        wP('Scope', style: 'Custom') + wP('Text.'),
        styles: wStyles(
            [(id: 'Custom', name: 'Custom', basedOn: null, outline: 2)]),
      );

      expect(labels(s), ['Scope']);
    });

    test('outline level 9 is body text, not a heading', () async {
      final s = await readBody(wP('Not a heading', outline: 9) + wP('Text.'));

      expect(labels(s), ['']);
    });

    test('without styles.xml an outline level still works but a bare id does not',
        () async {
      final s = await readBody(
        wP('By id', style: 'Heading1') +
            wP('Body one.') +
            wP('By outline', outline: 0) +
            wP('Body two.'),
      );

      expect(labels(s), ['', 'By outline']);
    });

    test('a malformed styles.xml degrades to outline-level headings only',
        () async {
      final s = await read(minimalDocx(
        document: wDocument(wP('By id', style: 'Heading1') +
            wP('One.') +
            wP('By outline', outline: 0) +
            wP('Two.')),
        styles: '<w:styles><w:style',
      ));

      expect(labels(s), ['', 'By outline']);
    });

    test('an empty heading does not start a section', () async {
      final s = await readBody(
        wP('Scope', style: 'Heading1') +
            wP('One.') +
            wP('   ', style: 'Heading1') +
            wP('Two.'),
        styles: englishHeadingStyles,
      );

      expect(s, [(label: 'Scope', text: 'Scope\n\nOne.\n\nTwo.')]);
    });

    test('a heading with no body folds into the next section', () async {
      final s = await readBody(
        wP('Chapter', style: 'Heading1') +
            wP('Section', style: 'Heading2') +
            wP('Body.'),
        styles: englishHeadingStyles,
      );

      expect(s, [(label: 'Section', text: 'Chapter\n\nSection\n\nBody.')],
          reason: 'no title-only chunk; the parent heading stays as context');
    });

    test('a trailing heading with no body is still kept', () async {
      final s = await readBody(
        wP('Scope', style: 'Heading1') +
            wP('Body.') +
            wP('Appendix', style: 'Heading1'),
        styles: englishHeadingStyles,
      );

      expect(labels(s), ['Scope', 'Appendix']);
    });
  });

  group('text', () {
    test('tracked-change deletions are dropped and insertions kept', () async {
      final s = await readBody(
        '<w:p>'
        '<w:r><w:t xml:space="preserve">Leave is </w:t></w:r>'
        '<w:del w:id="1" w:author="a"><w:r><w:delText>20</w:delText></w:r></w:del>'
        '<w:ins w:id="2" w:author="a"><w:r><w:t>24</w:t></w:r></w:ins>'
        '<w:r><w:t xml:space="preserve"> days.</w:t></w:r>'
        '</w:p>',
      );

      expect(allText(s), 'Leave is 24 days.');
    });

    test('text moved under tracked changes is read once, at its new place',
        () async {
      final s = await readBody(
        '<w:p><w:moveFrom w:id="1" w:author="a"><w:r><w:t>Moved clause.</w:t>'
        '</w:r></w:moveFrom><w:r><w:t xml:space="preserve"> Stays.</w:t></w:r></w:p>'
        '<w:p><w:moveTo w:id="2" w:author="a"><w:r><w:t>Moved clause.</w:t>'
        '</w:r></w:moveTo></w:p>',
      );

      expect(allText(s), 'Stays.\n\nMoved clause.');
    });

    test('field codes are dropped and field results kept', () async {
      final s = await readBody(
        '<w:p>'
        '<w:r><w:t xml:space="preserve">Page </w:t></w:r>'
        '<w:r><w:fldChar w:fldCharType="begin"/></w:r>'
        '<w:r><w:instrText xml:space="preserve"> PAGE \\* MERGEFORMAT </w:instrText></w:r>'
        '<w:r><w:fldChar w:fldCharType="separate"/></w:r>'
        '<w:r><w:t>3</w:t></w:r>'
        '<w:r><w:fldChar w:fldCharType="end"/></w:r>'
        '</w:p>',
      );

      expect(allText(s), 'Page 3');
    });

    test('tabs and line breaks are kept', () async {
      final s = await readBody(
        '<w:p><w:r><w:t>a</w:t><w:tab/><w:t>b</w:t><w:br/><w:t>c</w:t>'
        '<w:cr/><w:t>d</w:t></w:r></w:p>',
      );

      expect(allText(s), 'a\tb\nc\nd');
    });

    test('table rows become pipe-joined lines between paragraphs', () async {
      final s = await readBody(
        wP('Before.') +
            wTable([
              ['Category', 'Limit'],
              ['Meals', '800'],
            ]) +
            wP('After.'),
      );

      expect(allText(s), 'Before.\n\nCategory | Limit\nMeals | 800\n\nAfter.');
    });

    test('empty table rows are dropped', () async {
      final s = await readBody(wTable([
        ['', ''],
        ['Meals', '800'],
      ]));

      expect(allText(s), 'Meals | 800');
    });

    test('text-box content is not read', () async {
      final s = await readBody(
        '<w:p><w:r><w:t xml:space="preserve">Body </w:t></w:r>'
        '<w:r><w:pict><w:txbxContent><w:p><w:r><w:t>boxed</w:t></w:r></w:p>'
        '</w:txbxContent></w:pict></w:r><w:r><w:t>text.</w:t></w:r></w:p>',
      );

      expect(allText(s), 'Body text.');
    });

    test('a text box inside a table cell is not read twice', () async {
      final s = await readBody(
        '<w:tbl><w:tr><w:tc><w:p><w:r><w:t>Cell</w:t></w:r><w:r>'
        '<mc:AlternateContent xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006">'
        '<mc:Choice><w:drawing><w:txbxContent><w:p><w:r><w:t>boxed</w:t></w:r></w:p>'
        '</w:txbxContent></w:drawing></mc:Choice><mc:Fallback><w:pict><w:txbxContent>'
        '<w:p><w:r><w:t>boxed</w:t></w:r></w:p></w:txbxContent></w:pict></mc:Fallback>'
        '</mc:AlternateContent></w:r></w:p></w:tc><w:tc>${wP('b')}</w:tc></w:tr></w:tbl>',
      );

      expect(allText(s), 'Cell | b');
    });

    test('paragraphs inside a block content control are read in place',
        () async {
      final s = await readBody(
        '${wP('First.')}'
        '<w:sdt><w:sdtPr/><w:sdtContent>${wP('Inside.')}</w:sdtContent></w:sdt>'
        '${wP('Last.')}',
      );

      expect(allText(s), 'First.\n\nInside.\n\nLast.');
    });

    test('a heading inside a content control still labels its section',
        () async {
      final s = await readBody(
        '<w:sdt><w:sdtContent>${wP('Scope', style: 'Heading1')}</w:sdtContent></w:sdt>'
        '${wP('Body.')}',
        styles: englishHeadingStyles,
      );

      expect(labels(s), ['Scope']);
    });

    test('a namespace prefix other than w still parses', () async {
      final s = await read(minimalDocx(
        document: wDocument(
          '<x:p><x:r><x:t>Prefixed.</x:t></x:r></x:p>',
          prefix: 'x',
        ),
      ));

      expect(allText(s), 'Prefixed.');
    });

    test('Devanagari, RTL and emoji survive intact', () async {
      const hindi = 'वार्षिक अवकाश 24 दिन है।';
      const arabic = 'الإجازة السنوية';
      const emoji = 'Leave 🏖️👨‍👩‍👧 approved';
      final s = await readBody(
        wP('अवकाश नीति', style: 'Heading1') +
            wP(hindi) +
            wP(arabic) +
            wP(emoji),
        styles: englishHeadingStyles,
      );

      expect(labels(s), ['अवकाश नीति']);
      expect(allText(s), allOf(contains(hindi), contains(arabic), contains(emoji)));
    });

    test('XML entities are decoded', () async {
      final s = await readBody(wP('Tom & Jerry <3 "quotes"'));

      expect(allText(s), 'Tom & Jerry <3 "quotes"');
    });

    test('a long heading label is collapsed and capped at 100 chars', () async {
      final long = List.filled(40, 'word').join('   ');
      final s = await readBody(
        wP(long, style: 'Heading1') + wP('Body.'),
        styles: englishHeadingStyles,
      );

      final label = s!.single.label;
      expect(label, hasLength(100));
      expect(label, endsWith('…'));
      expect(label, isNot(contains('  ')));
    });

    test('capping a heading never splits an emoji', () async {
      // 98 ASCII chars put the emoji's surrogate pair at code units 98-99,
      // straddling the 99-unit cut.
      final heading = '${'a' * 98}😀 and more text after the cut';
      final s = await readBody(
        wP(heading, style: 'Heading1') + wP('Body.'),
        styles: englishHeadingStyles,
      );

      final label = s!.single.label;
      final beforeEllipsis = label.substring(0, label.length - 1);
      final last = beforeEllipsis.codeUnitAt(beforeEllipsis.length - 1);
      expect(last >= 0xD800 && last <= 0xDBFF, isFalse,
          reason: 'a lone high surrogate renders as garbage');
      expect(label, endsWith('…'));
    });

    test('a document with no text yields no sections', () async {
      expect(await readBody(wP('   ') + wTable([['']])), isEmpty);
    });

    test('a large document parses', () async {
      final body = List.generate(
          2000, (i) => wP('Paragraph $i of a long policy document.')).join();

      final s = await readBody(body);

      expect(allText(s), contains('Paragraph 1999 of'));
    });
  });

  group('pictures', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('docx_pics'));
    tearDown(() => dir.delete(recursive: true));

    final png = img.encodePng(img.Image(width: 1200, height: 800));
    final jpg = img.encodeJpg(img.Image(width: 1200, height: 800));
    final rels = wRels({'rId1': 'media/image1.png'});
    final media = {'word/media/image1.png': png};

    Future<List<DocxSection>?> readPics(
      String body, {
      String? relsXml,
      Map<String, List<int>>? parts,
      String? styles,
    }) async =>
        source.sectionsText(
          await writeTempDocx(minimalDocx(
            document: wDocument(body),
            styles: styles,
            extra: {'word/_rels/document.xml.rels': relsXml ?? rels},
            media: parts ?? media,
          )),
          imageDir: dir.path,
        );

    List<String> files() => [for (final f in dir.listSync()) f.path];

    test('a large picture is written out and marked where it sits', () async {
      final s = await readPics(
          wP('Before the notice.') + wDrawing('rId1') + wP('After it.'));

      final path = files().single;
      expect(File(path).readAsBytesSync(), png);
      expect(s!.single.text,
          'Before the notice.\n\n\n${docxImageMarker(path)}\n\n\nAfter it.');
    });

    test('without a picture directory pictures are ignored', () async {
      final s = await source.sectionsText(await writeTempDocx(minimalDocx(
        document: wDocument(wP('Text.') + wDrawing('rId1')),
        extra: {'word/_rels/document.xml.rels': rels},
        media: media,
      )));

      expect(s!.single.text, 'Text.');
    });

    test('a JPEG is read like a PNG', () async {
      await readPics(wDrawing('rId1'),
          relsXml: wRels({'rId1': 'media/image1.jpeg'}),
          parts: {'word/media/image1.jpeg': jpg});

      expect(files().single, endsWith('.jpeg'));
    });

    test('a picture in a table cell is marked in its row', () async {
      final s = await readPics(
          '<w:tbl><w:tr><w:tc>${wP('Scan')}</w:tc>'
          '<w:tc>${wDrawing('rId1')}</w:tc></w:tr></w:tbl>');

      expect(s!.single.text, 'Scan | ${docxImageMarker(files().single)}');
    });

    test('a heading holding a picture keeps a clean label', () async {
      final p = wDrawing('rId1');
      final pictureRun = p.substring('<w:p>'.length, p.length - '</w:p>'.length);

      final s = await readPics(
          '<w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr>'
          '<w:r><w:t>Scan </w:t></w:r>$pictureRun</w:p>'
          '${wP('Body text.')}',
          styles: englishHeadingStyles);

      expect(s!.single.label, 'Scan');
      expect(s.single.text, contains(docxImageMarker(files().single)));
    });

    // ── Edge cases ────────────────────────────────────────────────────────

    test('a small logo is not extracted', () async {
      final s = await readPics(
          wP('Letterhead') + wDrawing('rId1', cx: 914400, cy: 457200));

      expect(files(), isEmpty);
      expect(s!.single.text, 'Letterhead');
    });

    test('a wide but short strip is too small in area', () async {
      await readPics(wDrawing('rId1', cx: 2400000, cy: 457200));

      expect(files(), isEmpty);
    });

    test('a low-resolution bitmap stretched across the page is not extracted',
        () async {
      for (final (w, h) in [(400, 300), (1200, 60)]) {
        await readPics(wDrawing('rId1'), parts: {
          'word/media/image1.png': img.encodePng(img.Image(width: w, height: h)),
        });
      }

      expect(files(), isEmpty);
    });

    test('a vector drawing is not extracted', () async {
      await readPics(wDrawing('rId1'),
          relsXml: wRels({'rId1': 'media/image1.svg'}),
          parts: {'word/media/image1.svg': utf8.encode('<svg xmlns="http://www.w3.org/2000/svg"/>')});

      expect(files(), isEmpty);
    });

    test('a picture that cannot be unzipped costs only itself', () async {
      final zip = withCorruptData(
        minimalDocx(
          document: wDocument(wP('Text.') + wDrawing('rId1')),
          extra: {'word/_rels/document.xml.rels': rels},
          media: media,
        ),
        'word/media/image1.png',
      );

      final s = await source.sectionsText(await writeTempDocx(zip),
          imageDir: dir.path);

      expect(s!.single.text, 'Text.');
      expect(files(), isEmpty);
    });

    test('a linked picture is not fetched', () async {
      await readPics(wDrawing('rId1', linked: true));
      await readPics(wDrawing('rId1'),
          relsXml: wRels({'rId1': 'https://example.com/a.png'},
              external: {'rId1'}));

      expect(files(), isEmpty);
    });

    test('a picture pasted twice is read once', () async {
      final s = await readPics(wDrawing('rId1') + wP('Again:') +
          wDrawing('rId1'));

      expect(files(), hasLength(1));
      expect(docxImageMarkerPattern.allMatches(s!.single.text), hasLength(1));
    });

    test('at most kMaxDocxImages pictures are read', () async {
      const n = kMaxDocxImages + 1;
      await readPics(
        [for (var i = 0; i < n; i++) wDrawing('rId$i')].join(),
        relsXml: wRels({for (var i = 0; i < n; i++) 'rId$i': 'media/i$i.png'}),
        parts: {
          for (var i = 0; i < n; i++)
            'word/media/i$i.png':
                img.encodePng(img.Image(width: 600 + i, height: 200)),
        },
      );

      expect(files(), hasLength(kMaxDocxImages));
    });

    test('a missing relationships part costs only the pictures', () async {
      final s = await source.sectionsText(
        await writeTempDocx(minimalDocx(
          document: wDocument(wP('Text.') + wDrawing('rId1')),
          media: media,
        )),
        imageDir: dir.path,
      );

      expect(s!.single.text, 'Text.');
      expect(files(), isEmpty);
    });
  });

  group('unreadable', () {
    test('a file that is not a zip', () async {
      expect(await read('%PDF-1.4 not a word file'.codeUnits), isNull);
    });

    test('an empty file', () async {
      expect(await read(const []), isNull);
    });

    test('a zip with no word/document.xml', () async {
      expect(
        await read(minimalDocx(
            document: null, extra: {'word/other.xml': '<a/>'})),
        isNull,
      );
    });

    test('malformed document XML', () async {
      expect(
          await read(minimalDocx(document: '<w:document><w:body><w:p>')), isNull);
    });

    test('document XML with no body', () async {
      expect(
        await read(minimalDocx(
            document: '<w:document xmlns:w="$wNs"></w:document>')),
        isNull,
      );
    });

    test('a document.xml declaring more than the size cap', () async {
      final zip = minimalDocx(document: wDocument(wP('Small really.')));

      final bomb =
          withDeclaredSize(zip, 'word/document.xml', kMaxDocxXmlBytes + 1);

      expect(await read(bomb), isNull);
    });


    test('a styles.xml declaring more than its cap degrades like a missing one',
        () async {
      final zip = minimalDocx(
        document: wDocument(wP('By id', style: 'Heading1') +
            wP('One.') +
            wP('By outline', outline: 0) +
            wP('Two.')),
        styles: englishHeadingStyles,
      );

      final s = await read(
          withDeclaredSize(zip, 'word/styles.xml', kMaxDocxStylesBytes + 1));

      expect(labels(s), ['', 'By outline']);
    });

    test('a path that does not exist', () async {
      final dir = await Directory.systemTemp.createTemp('docx_missing');

      expect(await source.sectionsText('${dir.path}/nope.docx'), isNull);
    });
  });
}
