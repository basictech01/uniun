import 'dart:io';

import 'package:uniun/data/datasources/pdf/pdf_page_signals.dart';
import 'package:uniun/data/datasources/pdf/pdf_text_source.dart';

/// Deterministic [PdfTextSource]: returns preset pages per path, counts reads.
class FakePdfTextSource implements PdfTextSource {
  /// path -> pages. A missing key or a `null` value simulates an unreadable file.
  final Map<String, List<String>?> pages = {};
  int calls = 0;

  /// path -> per-page signals. A missing key answers `null`, which the
  /// extraction service treats as "no evidence": text layer only.
  final Map<String, List<PdfPageSignals>?> signals = {};

  /// Every [renderForOcr] request, in order. Each answers [renderKey], so a
  /// test keys its fake OCR text on that.
  final List<({String path, int page, PdfBox? region})> renders = [];

  /// When set, each render is written there as a real (empty) file, so a
  /// test can check the caller deletes it.
  Directory? renderDir;

  /// Pages whose render fails.
  final Set<int> failRenderPages = {};

  /// When set, [pagesText] throws it instead of answering.
  Object? throwOnRead;

  /// When set, [pagesText] awaits it before answering (for concurrency tests).
  Future<void>? gate;

  @override
  Future<List<String>?> pagesText(String path) async {
    calls++;
    if (gate != null) await gate;
    if (throwOnRead != null) throw throwOnRead!;
    return pages[path];
  }

  @override
  Future<List<PdfPageSignals>?> pageSignals(String path) async =>
      signals[path];

  @override
  Future<String?> renderForOcr(
    String path,
    int pageIndex, {
    PdfBox? region,
  }) async {
    renders.add((path: path, page: pageIndex, region: region));
    if (failRenderPages.contains(pageIndex)) return null;
    final out = renderKey(path, pageIndex, region: region != null);
    if (renderDir != null) await File(out).writeAsBytes(const []);
    return out;
  }

  String renderKey(String path, int page, {bool region = false}) {
    final name = 'render_${path.hashCode}_$page${region ? '_region' : ''}';
    return renderDir == null ? name : '${renderDir!.path}/$name.png';
  }
}
