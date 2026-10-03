import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/data/datasources/docx/docx_text_source.dart';
import 'package:uniun/domain/entities/shiv/document_citation.dart';
import 'package:uniun/features/shiv/document_viewer/cubit/docx_viewer_cubit.dart';
import 'package:uniun/features/shiv/document_viewer/widgets/cited_pdf_viewer.dart';
import 'package:uniun/features/shiv/document_viewer/widgets/docx_section_view.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Builds the PDF body, opened on [page] (1-based) with [snippet] highlighted.
/// Replaceable so tests can check the page without PDFium.
typedef PdfBodyBuilder = Widget Function(String path, int page, String snippet);

Widget buildPdfViewer(
  String path,
  int page,
  String snippet, {
  PdfViewerController? controller,
  ValueChanged<List<PdfPageTextRange>>? onHighlights,
}) => CitedPdfViewer(
  path: path,
  page: page,
  snippet: snippet,
  controller: controller,
  onHighlights: onHighlights,
);

/// A cited document opened where the citation points: a PDF on its page, a
/// Word file on its heading's section. Reading rather than checking is better
/// in the OS viewer, so that stays one tap away.
///
/// A PDF lands on the page and highlights the cited passage by searching its
/// text layer for it (see [CitedPdfViewer]).
class DocumentViewerPage extends StatelessWidget {
  const DocumentViewerPage({
    super.key,
    required this.citation,
    this.pdfBody = buildPdfViewer,
    this.docxSource,
  });

  final DocumentCitation citation;
  final PdfBodyBuilder pdfBody;

  /// Defaults to the app's reader; tests pass their own.
  final DocxTextSource? docxSource;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final exists = File(citation.localPath).existsSync();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          citation.title ??
              (citation.kind == DocumentKind.pdf
                  ? l10n.shivSourcesDocumentUntitled
                  : l10n.shivSourcesDocxUntitled),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (exists)
            IconButton(
              tooltip: l10n.documentViewerOpenExternal,
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: () => OpenFilex.open(citation.localPath),
            ),
        ],
      ),
      body: exists
          ? _body(context, l10n)
          : _message(l10n.documentViewerFileGone),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n) {
    switch (citation.kind) {
      case DocumentKind.pdf:
        return pdfBody(
          citation.localPath,
          int.tryParse(citation.label) ?? 1,
          citation.snippet,
        );
      case DocumentKind.docx:
        return BlocProvider(
          create: (_) =>
              DocxViewerCubit(docxSource ?? getIt<DocxTextSource>())
                ..load(citation.localPath, citation.label, citation.snippet),
          child: BlocBuilder<DocxViewerCubit, DocxViewerState>(
            builder: (_, state) => switch (state) {
              DocxViewerLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              DocxViewerFailed() => _message(l10n.documentViewerReadError),
              DocxViewerLoaded(:final sections, :final target) =>
                DocxSectionView(sections: sections, target: target),
            },
          ),
        );
      case DocumentKind.image:
        // Images open in the media viewer, never here.
        return _message(l10n.documentViewerReadError);
    }
  }

  Widget _message(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
