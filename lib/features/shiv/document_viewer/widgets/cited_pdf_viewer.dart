import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uniun/features/shiv/document_viewer/utils/passage_pattern.dart';

/// A PDF opened on [page] with the start of the cited [snippet] highlighted on
/// that page.
///
/// The snippet is a chunk — the PDF's own extracted text — so its first words
/// (see [passagePattern]) are found in the viewer's text for that page. Only the
/// cited page is searched: the citation names it, and the same phrase on
/// another page is not the passage that was cited. On a page that was read
/// with OCR there is no text layer: nothing is highlighted and the reader still
/// lands on the right page.
/// Fills each of [ranges] that lies on [page] with a translucent highlight.
/// [pageRect] is where the page sits on [canvas].
@visibleForTesting
void paintHighlights(
  Canvas canvas,
  Rect pageRect,
  PdfPage page,
  List<PdfPageTextRange> ranges,
) {
  for (final range in ranges) {
    if (range.pageNumber != page.pageNumber) continue;
    final rect = range.bounds
        .toRect(page: page, scaledPageSize: pageRect.size)
        .translate(pageRect.left, pageRect.top);
    canvas.drawRect(rect, Paint()..color = Colors.yellow.withAlpha(127));
  }
}

class CitedPdfViewer extends StatefulWidget {
  const CitedPdfViewer({
    super.key,
    required this.path,
    required this.page,
    required this.snippet,
    this.controller,
    this.onHighlights,
  });

  final String path;
  final int page;
  final String snippet;

  /// Lets a test read where the viewer landed.
  final PdfViewerController? controller;

  /// Called with the highlighted ranges once the page has been searched
  /// (empty when nothing matched). For tests.
  final ValueChanged<List<PdfPageTextRange>>? onHighlights;

  @override
  State<CitedPdfViewer> createState() => _CitedPdfViewerState();
}

class _CitedPdfViewerState extends State<CitedPdfViewer> {
  late final PdfViewerController _controller =
      widget.controller ?? PdfViewerController();

  List<PdfPageTextRange> _highlights = const [];

  Future<void> _findPassage(PdfDocument document) async {
    final pattern = passagePattern(widget.snippet);
    final index = widget.page - 1;
    var found = <PdfPageTextRange>[];
    if (pattern != null && index >= 0 && index < document.pages.length) {
      try {
        // A page is a placeholder until loaded, with no text.
        final page = await document.pages[index].ensureLoaded();
        final text = await page.loadStructuredText();
        found = await text.allMatches(pattern).toList();
      } catch (_) {
        // A page whose text cannot be read simply has no highlight.
      }
    }
    if (!mounted) return;
    setState(() => _highlights = found);
    _controller.invalidate();
    widget.onHighlights?.call(found);
  }

  void _paint(Canvas canvas, Rect pageRect, PdfPage page) =>
      paintHighlights(canvas, pageRect, page, _highlights);

  @override
  Widget build(BuildContext context) => PdfViewer.file(
    widget.path,
    controller: _controller,
    initialPageNumber: widget.page,
    params: PdfViewerParams(
      pagePaintCallbacks: [_paint],
      onViewerReady: (document, _) => _findPassage(document),
    ),
  );
}
