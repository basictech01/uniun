import 'package:flutter/material.dart';
import 'package:uniun/common/widgets/note_card/reference_note_card.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/features/thread/widgets/thread_section_label.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Renders the ancestor chain ABOVE the focused note (X/Twitter style).
/// Oldest ancestor is first; the last item connects via thread line to the
/// root note card below.
class ThreadParentContext extends StatefulWidget {
  const ThreadParentContext({
    super.key,
    required this.notes,
    required this.profiles,
    required this.onNoteTap,
    this.isSiblingGroup = false,
  });

  final List<NoteEntity> notes;
  final Map<String, ProfileEntity> profiles;
  final void Function(String noteId) onNoteTap;

  /// When true, rows are unrelated siblings (e.g. outgoing references all
  /// pointing to the same root note below). No vertical line is drawn between
  /// rows; only the last row emits a short stem to the root card. Beyond
  /// [_collapseThreshold] items, the first N are shown and the rest hidden
  /// behind a "Show more" button (X/Twitter-style).
  final bool isSiblingGroup;

  static const int _collapseThreshold = 2;

  @override
  State<ThreadParentContext> createState() => _ThreadParentContextState();
}

class _ThreadParentContextState extends State<ThreadParentContext> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final notes = widget.notes;
    if (notes.isEmpty) return const SizedBox.shrink();

    final collapse =
        widget.isSiblingGroup &&
        !_expanded &&
        notes.length > ThreadParentContext._collapseThreshold;
    final visible = collapse
        ? notes.take(ThreadParentContext._collapseThreshold).toList()
        : notes;
    final hiddenCount = notes.length - visible.length;

    final rows = <Widget>[
      ...List.generate(visible.length, (i) {
        final isLast = i == visible.length - 1;
        // Sibling/reference mode: each reference chains DOWN to the next, so
        // the stick sits ABOVE every following reference and the last one has
        // no stick beneath it. A reply/parent chain instead connects every
        // row down to the root note below.
        final showConnector = widget.isSiblingGroup ? !isLast : true;
        // Sibling connectors bridge the inter-row gap so the line flows into
        // the next reference's avatar; the parent stem stops at its own row.
        final double connectorBottom = widget.isSiblingGroup ? -10 : 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (showConnector)
                Positioned(
                  left: 18,
                  top: 40,
                  bottom: connectorBottom,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ReferenceNoteCard(
                note: visible[i],
                profile: widget.profiles[visible[i].authorPubkey],
                onTap: () => widget.onNoteTap(visible[i].id),
              ),
            ],
          ),
        );
      }),
      if (collapse)
        Padding(
          padding: const EdgeInsets.only(left: 52, top: 4, bottom: 4),
          child: GestureDetector(
            onTap: () => setState(() => _expanded = true),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  l10n.threadShowMoreReferences(hiddenCount),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.expand_more_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: ThreadSectionLabel(
            widget.isSiblingGroup
                ? l10n.threadReferencesLabel
                : l10n.threadReplyingToLabel,
            icon: widget.isSiblingGroup
                ? Icons.link_rounded
                : Icons.reply_rounded,
          ),
        ),
        // References (and the reply/parent chain) stay flat and transparent on
        // the thread background — no card fill — matching the design-system
        // mock's reference notes.
        ...rows,
      ],
    );
  }
}
