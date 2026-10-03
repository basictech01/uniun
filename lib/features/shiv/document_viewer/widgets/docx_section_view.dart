import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uniun/data/datasources/docx/docx_text_source.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// One piece of a section, in reading order.
sealed class DocxBlock {
  const DocxBlock();
}

final class DocxText extends DocxBlock {
  const DocxText(this.text);
  final String text;
}

/// A table, one list of cell texts per row.
final class DocxTable extends DocxBlock {
  const DocxTable(this.rows);
  final List<List<String>> rows;
}

final class DocxPicture extends DocxBlock {
  const DocxPicture(this.path);
  final String path;
}

/// Splits a section's extracted text into text, table and picture blocks.
///
/// The reader writes a table row as `cell | cell` and a large picture as a
/// marker (see [docxImageMarker]); a paragraph is everything between blank
/// lines. A block whose every line holds a ` | ` is a table.
List<DocxBlock> docxBlocks(String text) {
  final blocks = <DocxBlock>[];
  for (final part in text.split(RegExp(r'\n\s*\n'))) {
    var from = 0;
    for (final m in docxImageMarkerPattern.allMatches(part)) {
      _addText(blocks, part.substring(from, m.start));
      blocks.add(DocxPicture(m[1]!));
      from = m.end;
    }
    _addText(blocks, part.substring(from));
  }
  return blocks;
}

void _addText(List<DocxBlock> blocks, String raw) {
  final text = raw.trim();
  if (text.isEmpty) return;
  final lines = text.split('\n');
  if (lines.every((l) => l.contains(' | '))) {
    blocks.add(
      DocxTable([
        for (final l in lines) [for (final c in l.split(' | ')) c.trim()],
      ]),
    );
  } else {
    blocks.add(DocxText(text));
  }
}

/// A Word document, one block per heading section, opened scrolled to the cited
/// section and with that section tinted. Paragraphs, tables and large pictures
/// are shown; styling, small pictures and page layout are not.
///
/// Word has no fixed pages — the same file paginates differently in every
/// viewer — so the heading is the only honest location.
class DocxSectionView extends StatefulWidget {
  const DocxSectionView({super.key, required this.sections, this.target});

  final List<DocxSection> sections;

  /// Index of the cited section, or `null` to open at the top.
  final int? target;

  @override
  State<DocxSectionView> createState() => _DocxSectionViewState();
}

class _DocxSectionViewState extends State<DocxSectionView> {
  final _targetKey = GlobalKey();
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    // A section is as tall as its content, so its offset is not known up
    // front; ask the laid-out widget to scroll itself into view. Pictures load
    // after the first frame and move it, so it settles once more after them.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTarget());
    _settle = Timer(const Duration(milliseconds: 400), _scrollToTarget);
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  void _scrollToTarget() {
    final ctx = _targetKey.currentContext;
    if (ctx != null && ctx.mounted) {
      Scrollable.ensureVisible(ctx, alignment: 0.05);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.documentViewerTextOnly,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < widget.sections.length; i++)
            Container(
              key: i == widget.target ? _targetKey : null,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: i == widget.target
                    ? scheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final b in docxBlocks(widget.sections[i].text))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _block(context, b),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _block(BuildContext context, DocxBlock block) {
    final scheme = Theme.of(context).colorScheme;
    return switch (block) {
      DocxText(:final text) => SelectableText(
        text,
        style: const TextStyle(fontSize: 15, height: 1.5),
      ),
      DocxTable(:final rows) => _table(rows, scheme),
      DocxPicture(:final path) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(path),
          fit: BoxFit.fitWidth,
          width: double.infinity,
          // A scanned page is thousands of pixels wide for a phone screen.
          cacheWidth:
              (MediaQuery.sizeOf(context).width *
                      MediaQuery.devicePixelRatioOf(context))
                  .round(),
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    };
  }

  Widget _table(List<List<String>> rows, ColorScheme scheme) {
    final columns = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(color: scheme.outlineVariant),
        children: [
          for (final r in rows)
            TableRow(
              children: [
                for (var c = 0; c < columns; c++)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      c < r.length ? r[c] : '',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
