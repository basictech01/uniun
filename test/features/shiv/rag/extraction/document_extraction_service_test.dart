import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/data/datasources/docx/docx_text_source.dart';
import 'package:uniun/data/datasources/pdf/pdf_page_signals.dart';
import 'package:uniun/features/shiv/rag/extraction/document_extraction_service.dart';

import '../../../../_helpers/fake_docx_text_source.dart';
import '../../../../_helpers/fake_image_label_source.dart';
import '../../../../_helpers/fake_ocr_text_source.dart';
import '../../../../_helpers/fake_pdf_text_source.dart';

/// Covers: DocumentExtractionService dispatching by kind (PDF, DOCX, image
/// OCR and labels) and composing source, gate and chunker; reading each PDF
/// page by its OCR plan; both not-searchable reasons; page counts; no
/// exception leak.
void main() {
  const prose = 'The quarterly leave policy has been revised. ';
  late FakePdfTextSource source;
  late FakeDocxTextSource docx;
  late FakeOcrTextSource ocr;
  late FakeImageLabelSource labels;
  late DocumentExtractionService service;

  setUp(() {
    source = FakePdfTextSource();
    docx = FakeDocxTextSource();
    ocr = FakeOcrTextSource();
    labels = FakeImageLabelSource();
    service = DocumentExtractionService(source, docx, ocr, labels);
  });

  group('readable prose', () {
    test('becomes labelled chunks with the page count', () async {
      source.pages['/a.pdf'] = [prose * 6, 'Second page. ${prose * 6}'];

      final result = await service.extract('/a.pdf', DocumentKind.pdf);

      expect(result, isA<Extracted>());
      final extracted = result as Extracted;
      expect(extracted.pageCount, 2);
      expect(extracted.chunks.map((c) => c.label).toSet(), {'1', '2'});
      expect(extracted.chunks.map((c) => c.ordinal),
          List.generate(extracted.chunks.length, (i) => i));
    });

    test('reads the file exactly once', () async {
      source.pages['/a.pdf'] = [prose * 6];

      await service.extract('/a.pdf', DocumentKind.pdf);

      expect(source.calls, 1);
    });
  });

  group('not searchable', () {
    test('mojibake fails the gate as noTextLayer, keeping the page count',
        () async {
      source.pages['/a.pdf'] = ['!" #\$%\$ &\'()' * 40, '!" #\$%\$ &\'()' * 40];

      final result = await service.extract('/a.pdf', DocumentKind.pdf);

      final n = result as NotSearchable;
      expect(n.reason, NotSearchableReason.noTextLayer);
      expect(n.pageCount, 2);
    });

    test('a scan (blank pages) is noTextLayer', () async {
      source.pages['/a.pdf'] = ['', '  ', ''];

      final result = await service.extract('/a.pdf', DocumentKind.pdf);

      expect((result as NotSearchable).reason, NotSearchableReason.noTextLayer);
    });

    test('text too short to be worth indexing is noTextLayer', () async {
      source.pages['/a.pdf'] = ['Received.'];

      expect(((await service.extract('/a.pdf', DocumentKind.pdf)) as NotSearchable).reason,
          NotSearchableReason.noTextLayer);
    });

    test('a file the source cannot open is unreadable', () async {
      final result = await service.extract('/missing.pdf', DocumentKind.pdf);

      expect((result as NotSearchable).reason, NotSearchableReason.unreadable);
    });

    test('a source that throws is unreadable, never an exception', () async {
      source.throwOnRead = StateError('pdfium exploded');

      final result = await service.extract('/a.pdf', DocumentKind.pdf);

      expect((result as NotSearchable).reason, NotSearchableReason.unreadable);
    });
  });

  group('image', () {
    test('text read in an image becomes unlabelled chunks with no page count',
        () async {
      ocr.texts['/a.png'] = 'OFFICE ORDER\n\n${prose * 6}';

      final e = await service.extract('/a.png', DocumentKind.image) as Extracted;

      expect(e.pageCount, 0);
      expect(e.chunks.map((c) => c.label).toSet(), {''});
      expect(e.chunks.first.text, startsWith('OFFICE ORDER'));
    });

    test('a short sign, receipt or caption is still indexed', () async {
      for (final (path, text) in [
        ('/sign.jpg', 'PLATFORM 3 → DELHI 14:20'),
        ('/receipt.jpg', 'TOTAL Rs 1,240.00\nPAID BY UPI'),
        ('/board.jpg', 'Q3 rollout: freeze on 12 Oct'),
      ]) {
        ocr.texts[path] = text;

        expect(await service.extract(path, DocumentKind.image),
            isA<Extracted>(),
            reason: text);
      }
    });

    test('a few stray characters are still too little to index', () async {
      ocr.texts['/a.jpg'] = 'Il oO';

      expect(
        ((await service.extract('/a.jpg', DocumentKind.image)) as NotSearchable)
            .reason,
        NotSearchableReason.noTextLayer,
      );
    });

    test('a photo without text is described by what is in it', () async {
      ocr.texts['/dog.jpg'] = '';
      labels.labels['/dog.jpg'] = ['Dog', 'Beach', 'Sky'];

      final e = await service.extract('/dog.jpg', DocumentKind.image)
          as Extracted;

      expect(e.chunks.single.text, 'Photo showing: dog, beach, sky');
      expect(e.chunks.single.label, '');
    });

    test('text and contents become separate passages', () async {
      ocr.texts['/board.jpg'] = 'Q3 rollout: freeze on 12 Oct';
      labels.labels['/board.jpg'] = ['Whiteboard', 'Room'];

      final e = await service.extract('/board.jpg', DocumentKind.image)
          as Extracted;

      expect(e.chunks.map((c) => c.text).toList(), [
        'Q3 rollout: freeze on 12 Oct',
        'Photo showing: whiteboard, room',
      ]);
    });

    test('OCR noise is dropped but the photo\'s contents are kept', () async {
      ocr.texts['/street.jpg'] = '|| ;; 1 / .';
      labels.labels['/street.jpg'] = ['Car', 'Road'];

      final e = await service.extract('/street.jpg', DocumentKind.image)
          as Extracted;

      expect(e.chunks.single.text, 'Photo showing: car, road');
    });

    test('text is still indexed when labeling cannot read the file', () async {
      ocr.texts['/n.jpg'] = 'PLATFORM 3 → DELHI 14:20';
      labels.labels['/n.jpg'] = null;

      final e = await service.extract('/n.jpg', DocumentKind.image)
          as Extracted;

      expect(e.chunks.single.text, 'PLATFORM 3 → DELHI 14:20');
    });

    test('a file neither OCR nor labeling can read is unreadable', () async {
      labels.labels['/bad.jpg'] = null;

      final n = await service.extract('/bad.jpg', DocumentKind.image)
          as NotSearchable;

      expect(n.reason, NotSearchableReason.unreadable);
    });

    test('a photo with no text in it is noTextLayer', () async {
      ocr.texts['/a.jpg'] = '';

      final n = await service.extract('/a.jpg', DocumentKind.image)
          as NotSearchable;

      expect(n.reason, NotSearchableReason.noTextLayer);
    });

    test('OCR noise fails the prose gate, like a scan', () async {
      ocr.texts['/a.jpg'] = '|| ;; 1 / . - = ~ ' * 20;

      expect(
        ((await service.extract('/a.jpg', DocumentKind.image)) as NotSearchable)
            .reason,
        NotSearchableReason.noTextLayer,
      );
    });

    test('a file OCR cannot read is unreadable', () async {
      final n = await service.extract('/gone.png', DocumentKind.image)
          as NotSearchable;

      expect(n.reason, NotSearchableReason.unreadable);
    });

    test('an OCR engine that throws is unreadable, never an exception',
        () async {
      ocr.throwOnRead = StateError('ml kit exploded');

      final n = await service.extract('/a.png', DocumentKind.image)
          as NotSearchable;

      expect(n.reason, NotSearchableReason.unreadable);
    });

    test('Devanagari text passes the gate and chunks', () async {
      ocr.texts['/a.png'] = 'कार्यालय आदेश। सभी कर्मचारियों के लिए अवकाश नीति। ' * 8;

      expect(await service.extract('/a.png', DocumentKind.image),
          isA<Extracted>());
    });

    test('an image never touches the PDF or DOCX readers', () async {
      ocr.texts['/a.png'] = prose * 6;

      await service.extract('/a.png', DocumentKind.image);

      expect((source.calls, docx.calls, ocr.calls), (0, 0, 1));
    });
  });

  group('docx', () {
    test('sections become heading-labelled chunks with no page count',
        () async {
      docx.sections['/a.docx'] = [
        (label: '', text: prose * 3),
        (label: 'Annual Leave', text: 'Annual Leave\n\n${prose * 3}'),
      ];

      final extracted =
          await service.extract('/a.docx', DocumentKind.docx) as Extracted;

      expect(extracted.pageCount, 0);
      expect(extracted.chunks.map((c) => c.label).toList(),
          ['', 'Annual Leave']);
    });

    test('each kind reads only its own source', () async {
      source.pages['/a.pdf'] = [prose * 6];
      docx.sections['/a.docx'] = [(label: 'A', text: prose * 6)];

      await service.extract('/a.pdf', DocumentKind.pdf);
      await service.extract('/a.docx', DocumentKind.docx);

      expect(source.calls, 1);
      expect(docx.calls, 1);
    });

    test('a file the source cannot read is unreadable', () async {
      final result = await service.extract('/missing.docx', DocumentKind.docx);

      expect((result as NotSearchable).reason, NotSearchableReason.unreadable);
    });

    test('a source that throws is unreadable, never an exception', () async {
      docx.throwOnRead = StateError('zip exploded');

      final result = await service.extract('/a.docx', DocumentKind.docx);

      expect((result as NotSearchable).reason, NotSearchableReason.unreadable);
    });

    test('a short memo is indexed — the prose gate is for PDFs only',
        () async {
      docx.sections['/a.docx'] = [(label: 'Memo', text: 'Memo\n\nApproved.')];

      final e = await service.extract('/a.docx', DocumentKind.docx) as Extracted;

      expect(e.chunks.single.label, 'Memo');
    });

    test('a table of figures is indexed despite few letters', () async {
      docx.sections['/a.docx'] = [
        (label: 'Rates', text: '2024 | 4500 | 3000\n2025 | 4800 | 3200'),
      ];

      expect(await service.extract('/a.docx', DocumentKind.docx),
          isA<Extracted>());
    });

    test('the same short text in a PDF is still refused', () async {
      source.pages['/a.pdf'] = ['Memo. Approved.'];

      expect(
        ((await service.extract('/a.pdf', DocumentKind.pdf)) as NotSearchable)
            .reason,
        NotSearchableReason.noTextLayer,
      );
    });

    test('a DOCX whose sections are all blank is noTextLayer', () async {
      docx.sections['/a.docx'] = [(label: 'X', text: '  \n\n ')];

      final n =
          await service.extract('/a.docx', DocumentKind.docx) as NotSearchable;

      expect(n.reason, NotSearchableReason.noTextLayer);
      expect(n.pageCount, 0);
    });

    test('a document with no sections is noTextLayer', () async {
      docx.sections['/a.docx'] = const [];

      expect(
        ((await service.extract('/a.docx', DocumentKind.docx)) as NotSearchable)
            .reason,
        NotSearchableReason.noTextLayer,
      );
    });
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  group('pdf pages read by their plan', () {
    const typed = 'Leave rules for every employee of the department. ';
    const scanText = 'Annexure A: list of officers transferred this month.';
    const photoText = 'Notice: the office stays closed on Friday.';
    const box = (left: 50.0, bottom: 100.0, right: 545.0, top: 500.0);

    PdfPageSignals signal({
      int chars = 1000,
      int? letters,
      bool legacyFont = false,
      double imageCoverage = 0,
      PdfBox? largestImage,
    }) =>
        PdfPageSignals(
          width: 595,
          height: 842,
          rotation: 0,
          chars: chars,
          letters: letters ?? (chars * 0.8).round(),
          unmapped: 0,
          invisible: 0,
          legacyFont: legacyFont,
          imageCoverage: imageCoverage,
          largestImage: largestImage,
          largestImageCoverage: largestImage == null ? 0 : imageCoverage,
          charsInLargestImage: 0,
        );

    final typedPage = signal();
    final scannedPage = signal(chars: 0, imageCoverage: 1);

    Future<Extracted> extract() async =>
        await service.extract('/a.pdf', DocumentKind.pdf) as Extracted;

    test('a typed page keeps its text layer and is never rendered', () async {
      source.pages['/a.pdf'] = [typed * 3];
      source.signals['/a.pdf'] = [typedPage];

      final result = await extract();

      expect(result.chunks.single.text, (typed * 3).trim());
      expect(source.renders, isEmpty);
      expect(ocr.calls, 0);
    });

    test('only the scanned page of a mixed document is read with OCR',
        () async {
      source.pages['/a.pdf'] = [typed * 3, ''];
      source.signals['/a.pdf'] = [typedPage, scannedPage];
      ocr.texts[source.renderKey('/a.pdf', 1)] = scanText;

      final result = await extract();

      expect(source.renders.map((r) => r.page), [1]);
      expect(source.renders.single.region, isNull);
      expect(result.pageCount, 2);
      expect(result.chunks.map((c) => (c.label, c.text)), [
        ('1', (typed * 3).trim()),
        ('2', scanText),
      ]);
    });

    test('a pasted image is read on its own, beside the text layer', () async {
      source.pages['/a.pdf'] = [typed * 3];
      source.signals['/a.pdf'] = [
        signal(imageCoverage: 0.4, largestImage: box),
      ];
      ocr.texts[source.renderKey('/a.pdf', 0, region: true)] = photoText;

      final result = await extract();

      expect(source.renders.single.region, box);
      expect(result.chunks.map((c) => c.text).join('\n'),
          allOf(contains(typed.trim()), contains(photoText)));
    });

    test('a legacy-font page is replaced by OCR, never kept as gibberish',
        () async {
      const gibberish = 'Hkkjr ljdkj ds deZpkfj;ksa ds fy, uhfr ';
      source.pages['/a.pdf'] = [gibberish * 10];
      source.signals['/a.pdf'] = [signal(legacyFont: true)];
      ocr.texts[source.renderKey('/a.pdf', 0)] =
          'भारत सरकार के कर्मचारियों के लिए नीति';

      final result = await extract();

      expect(result.chunks.single.text, 'भारत सरकार के कर्मचारियों के लिए नीति');
    });

    test('a mostly-image page keeps whichever reading is longer', () async {
      source.pages['/a.pdf'] = ['Office of the Collector, Pune'];
      source.signals['/a.pdf'] = [signal(chars: 25, imageCoverage: 0.6)];
      ocr.texts[source.renderKey('/a.pdf', 0)] =
          'Office of the Collector, Pune. $scanText';

      final result = await extract();

      expect(result.chunks.single.text,
          'Office of the Collector, Pune. $scanText');
    });

    test('a blank page is skipped without rendering', () async {
      source.pages['/a.pdf'] = [typed * 3, ''];
      source.signals['/a.pdf'] = [typedPage, signal(chars: 0)];

      final result = await extract();

      expect(source.renders, isEmpty);
      expect(result.chunks.map((c) => c.label).toSet(), {'1'});
    });

    test('a short typed page is indexed — pages are gated one by one',
        () async {
      source.pages['/a.pdf'] = [typed];
      source.signals['/a.pdf'] = [signal(chars: 45)];

      expect((await extract()).chunks.single.text, typed.trim());
    });

    test('each render is deleted once read', () async {
      final dir = await Directory.systemTemp.createTemp('extract_render');
      addTearDown(() => dir.delete(recursive: true));
      source.renderDir = dir;
      source.pages['/a.pdf'] = [''];
      source.signals['/a.pdf'] = [scannedPage];
      ocr.texts[source.renderKey('/a.pdf', 0)] = scanText;

      await extract();

      expect(dir.listSync(), isEmpty);
    });

    // ── Edge cases ────────────────────────────────────────────────────────

    test('a scan OCR finds nothing in is noTextLayer, keeping the page count',
        () async {
      source.pages['/a.pdf'] = ['', ''];
      source.signals['/a.pdf'] = [scannedPage, scannedPage];

      final result = await service.extract('/a.pdf', DocumentKind.pdf);

      expect((result as NotSearchable).reason, NotSearchableReason.noTextLayer);
      expect(result.pageCount, 2);
    });

    test('OCR noise on a scanned page is dropped', () async {
      source.pages['/a.pdf'] = [typed * 3, ''];
      source.signals['/a.pdf'] = [typedPage, scannedPage];
      ocr.texts[source.renderKey('/a.pdf', 1)] = r'|| ~~ ## @@ %% ^^ ** ||';

      expect((await extract()).chunks.map((c) => c.label).toSet(), {'1'});
    });

    test('a page that fails to render costs only that page', () async {
      source.pages['/a.pdf'] = [typed * 3, ''];
      source.signals['/a.pdf'] = [typedPage, scannedPage];
      source.failRenderPages.add(1);

      expect((await extract()).chunks.map((c) => c.label).toSet(), {'1'});
    });

    test('an OCR engine that throws costs only that page', () async {
      source.pages['/a.pdf'] = [typed * 3, ''];
      source.signals['/a.pdf'] = [typedPage, scannedPage];
      ocr.throwOnRead = StateError('ml kit crashed');

      expect((await extract()).chunks.map((c) => c.label).toSet(), {'1'});
    });

    test('signals that disagree with the page count fall back to the layer',
        () async {
      source.pages['/a.pdf'] = [typed * 10, typed * 10];
      source.signals['/a.pdf'] = [scannedPage];

      final result = await extract();

      expect(source.renders, isEmpty);
      expect(result.chunks.map((c) => c.label).toSet(), {'1', '2'});
    });

    test('without signals, the whole-document gate still refuses short text',
        () async {
      source.pages['/a.pdf'] = [typed];

      expect(await service.extract('/a.pdf', DocumentKind.pdf),
          isA<NotSearchable>());
    });
  });

  group('docx pictures', () {
    const notice = 'Notice: the office stays closed on Friday.';
    final pic = docxImageMarker('/tmp/pic.png');

    Future<Extracted> extract() async =>
        await service.extract('/a.docx', DocumentKind.docx) as Extracted;

    test('text read in a picture takes the picture\'s place', () async {
      docx.sections['/a.docx'] = [
        (label: 'Annexure', text: 'Before.\n\n$pic\n\nAfter.'),
      ];
      ocr.texts['/tmp/pic.png'] = notice;

      final result = await extract();

      expect(result.chunks.single.label, 'Annexure');
      expect(result.chunks.single.text, 'Before.\n\n$notice\n\nAfter.');
    });

    test('pictures are extracted into a temp folder that is removed after',
        () async {
      docx.sections['/a.docx'] = [(label: '', text: 'Text.')];

      await extract();

      expect(docx.imageDir, isNotNull);
      expect(Directory(docx.imageDir!).existsSync(), isFalse);
    });

    test('a picture-only section is indexed by its text', () async {
      docx.sections['/a.docx'] = [(label: 'Scan', text: pic)];
      ocr.texts['/tmp/pic.png'] = notice;

      expect((await extract()).chunks.single.text, notice);
    });

    // ── Edge cases ────────────────────────────────────────────────────────

    test('a picture with no readable text leaves no marker behind', () async {
      docx.sections['/a.docx'] = [
        (label: '', text: 'Before.\n\n\n$pic\n\n\nAfter.'),
      ];
      ocr.texts['/tmp/pic.png'] = r'~~ || ## ~~';

      expect((await extract()).chunks.single.text, 'Before.\n\nAfter.');
    });

    test('a section that was only an unreadable picture is dropped', () async {
      docx.sections['/a.docx'] = [
        (label: 'Scan', text: pic),
        (label: 'Body', text: 'Real text.'),
      ];

      expect((await extract()).chunks.map((c) => c.label), ['Body']);
    });

    test('an OCR engine that throws costs only the picture', () async {
      docx.sections['/a.docx'] = [(label: '', text: 'Text.\n\n$pic')];
      ocr.throwOnRead = StateError('ml kit crashed');

      expect((await extract()).chunks.single.text, 'Text.');
    });

    test('a document of unreadable pictures only is noTextLayer', () async {
      docx.sections['/a.docx'] = [(label: '', text: pic)];

      final result = await service.extract('/a.docx', DocumentKind.docx);

      expect((result as NotSearchable).reason, NotSearchableReason.noTextLayer);
    });
  });

  group('degenerate input', () {
    test('an empty page list is noTextLayer', () async {
      source.pages['/a.pdf'] = const [];

      expect(((await service.extract('/a.pdf', DocumentKind.pdf)) as NotSearchable).reason,
          NotSearchableReason.noTextLayer);
    });

    test('one long page still yields several capped chunks', () async {
      source.pages['/a.pdf'] = [prose * 200];

      final extracted = await service.extract('/a.pdf', DocumentKind.pdf) as Extracted;

      expect(extracted.pageCount, 1);
      expect(extracted.chunks.length, greaterThan(1));
      expect(extracted.chunks.every((c) => c.text.length <= 700), isTrue);
      expect(extracted.chunks.map((c) => c.label).toSet(), {'1'});
    });

    test('Devanagari prose passes the gate and chunks', () async {
      source.pages['/a.pdf'] = ['भारत सरकार के कर्मचारियों के लिए नीति। ' * 10];

      expect(await service.extract('/a.pdf', DocumentKind.pdf), isA<Extracted>());
    });
  });
}
