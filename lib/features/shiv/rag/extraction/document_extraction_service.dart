import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/data/datasources/docx/docx_text_source.dart';
import 'package:uniun/data/datasources/image_labels/image_label_source.dart';
import 'package:uniun/data/datasources/ocr/ocr_text_source.dart';
import 'package:uniun/data/datasources/pdf/pdf_page_signals.dart';
import 'package:uniun/data/datasources/pdf/pdf_text_source.dart';
import 'package:uniun/features/shiv/rag/extraction/chunk.dart';
import 'package:uniun/features/shiv/rag/extraction/page_ocr_plan.dart';
import 'package:uniun/features/shiv/rag/extraction/text_quality_gate.dart';

/// Why a document cannot be searched.
enum NotSearchableReason {
  /// The reader could not open it at all — corrupt, truncated, encrypted, or
  /// not the format its mime claimed.
  unreadable,

  /// Opened fine, but holds no usable text: a scan, or a broken font encoding
  /// that extracts as mojibake.
  noTextLayer,
}

sealed class ExtractionResult {
  const ExtractionResult();
}

/// Text was extracted, passed the quality gate, and chunked.
final class Extracted extends ExtractionResult {
  const Extracted({required this.chunks, required this.pageCount});

  final List<Chunk> chunks;
  final int pageCount;
}

/// The document is kept but cannot be searched. An expected outcome for a scan —
/// not a failure, and never surfaced to the user as an error.
final class NotSearchable extends ExtractionResult {
  const NotSearchable(this.reason, {this.pageCount = 0});

  final NotSearchableReason reason;
  final int pageCount;
}

/// Document file → labelled chunks, or the reason it cannot be searched.
///
/// Never throws: every failure is a [NotSearchable]. Indexing runs off the chat
/// path, and a document that cannot be read must not be able to break it.
@lazySingleton
class DocumentExtractionService {
  DocumentExtractionService(this._pdf, this._docx, this._ocr, this._labels);

  final PdfTextSource _pdf;
  final DocxTextSource _docx;
  final OcrTextSource _ocr;
  final ImageLabelSource _labels;

  Future<ExtractionResult> extract(String path, DocumentKind kind) async {
    final String text;
    final List<Chunk> chunks;
    // Only a PDF has pages; a DOCX paginates differently in every viewer and
    // is labelled by heading instead, and an image has neither.
    final int pageCount;
    // Set when every PDF page was planned and read on its own: the pages
    // are already gated, so the whole-document prose gate would only refuse
    // a short but genuine document.
    var pagesGated = false;
    try {
      switch (kind) {
        case DocumentKind.pdf:
          final pages = await _pdf.pagesText(path);
          if (pages == null) return _unreadable;
          final signals = await _pdf.pageSignals(path);
          final read = signals == null || signals.length != pages.length
              ? pages
              : await _readPages(path, pages, signals);
          pagesGated = !identical(read, pages);
          text = read.join('\n');
          chunks = chunkPages(read);
          pageCount = pages.length;
        case DocumentKind.docx:
          final dir = await Directory.systemTemp.createTemp('uniun_docx_');
          final List<DocxSection> sections;
          try {
            final raw = await _docx.sectionsText(path, imageDir: dir.path);
            if (raw == null) return _unreadable;
            sections = [
              for (final s in raw)
                (label: s.label, text: await _readPictures(s.text)),
            ];
          } finally {
            await dir.delete(recursive: true);
          }
          text = sections.map((s) => s.text).join('\n');
          chunks = chunkSections(sections);
          pageCount = 0;
        case DocumentKind.image:
          final read = await _ocr.imageText(path);
          final seen = await _labels.imageLabels(path);
          // OCR could not decode the file and labeling saw nothing in it.
          if (read == null && (seen == null || seen.isEmpty)) {
            return _unreadable;
          }
          // The text inside the image and what the image shows are separate
          // passages, so "the photo of my dog" and "what does the notice say"
          // each match the passage they are about. An image has no pages or
          // headings, so both are unlabelled.
          final hasText =
              read != null &&
              looksLikeProse(read, minChars: kMinImageTextChars);
          final sections = [
            if (hasText) (label: '', text: read),
            if (seen != null && seen.isNotEmpty)
              (label: '', text: describeImageLabels(seen)),
          ];
          text = sections.map((s) => s.text).join('\n');
          chunks = chunkSections(sections);
          pageCount = 0;
      }
    } catch (_) {
      return _unreadable;
    }

    // The prose gate catches scans, broken font encodings and OCR noise — a
    // PDF's or an image's failure modes. Images use a far lower minimum: a
    // sign or a receipt is short and real. DOCX text is the author's own
    // characters, so only an empty document is refused.
    final garbled = switch (kind) {
      DocumentKind.pdf => !pagesGated && !looksLikeProse(text),
      // Gated above, per passage: OCR text by the prose gate, labels not at all.
      DocumentKind.image => false,
      DocumentKind.docx => false,
    };
    if (garbled || chunks.isEmpty) {
      return NotSearchable(
        NotSearchableReason.noTextLayer,
        pageCount: pageCount,
      );
    }
    return Extracted(chunks: chunks, pageCount: pageCount);
  }

  static const _unreadable = NotSearchable(NotSearchableReason.unreadable);

  /// Each page's text by its plan: the text layer where it is good, OCR where
  /// it is missing or garbled, and both where a typed page carries a pasted
  /// image. A page that yields nothing worth reading becomes `''` so page
  /// labels stay aligned.
  Future<List<String>> _readPages(
    String path,
    List<String> layers,
    List<PdfPageSignals> signals,
  ) async {
    final out = <String>[];
    for (var i = 0; i < layers.length; i++) {
      final layer = _worthReading(layers[i]);
      out.add(switch (planPage(signals[i])) {
        UseTextLayer() => layer,
        SkipPage() => '',
        // The layer is garbage or a stamp line; never fall back to it.
        OcrWholePage(keepLongerText: false) => await _ocrPage(path, i),
        OcrWholePage(keepLongerText: true) => _longer(
          await _ocrPage(path, i),
          layer,
        ),
        OcrRegion(:final region) => [
          layer,
          await _ocrPage(path, i, region: region),
        ].where((t) => t.isNotEmpty).join('\n\n'),
      });
    }
    return out;
  }

  /// Swaps each picture marker in a DOCX section for the text OCR finds in
  /// it, where the picture sat.
  Future<String> _readPictures(String text) async {
    final out = StringBuffer();
    var from = 0;
    for (final m in docxImageMarkerPattern.allMatches(text)) {
      out
        ..write(text.substring(from, m.start))
        ..write(await _ocrFile(m[1]!));
      from = m.end;
    }
    out.write(text.substring(from));
    return out.toString().trim();
  }

  Future<String> _ocrPage(String path, int page, {PdfBox? region}) async {
    final png = await _pdf.renderForOcr(path, page, region: region);
    return png == null ? '' : _ocrFile(png);
  }

  /// OCR text of the temp image at [path], gated, and the file deleted.
  Future<String> _ocrFile(String path) async {
    try {
      return _worthReading(await _ocr.imageText(path) ?? '');
    } catch (_) {
      // One page OCR could not read must not cost the others their text.
      return '';
    } finally {
      try {
        await File(path).delete();
      } catch (_) {}
    }
  }

  /// The page gate: the image floor, since a page — like a sign — can be
  /// short and real; the letter ratio still drops OCR noise and mojibake.
  static String _worthReading(String text) =>
      looksLikeProse(text, minChars: kMinImageTextChars) ? text.trim() : '';

  static String _longer(String a, String b) => a.length >= b.length ? a : b;
}

/// What the embedder and the model read for an image's contents. LLM-facing
/// like the prompt's section markers, so it stays English and is not
/// localised; ML Kit's labels are English too.
String describeImageLabels(List<String> labels) =>
    'Photo showing: ${labels.map((l) => l.toLowerCase()).join(', ')}';
