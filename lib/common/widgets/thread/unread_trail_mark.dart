import 'package:flutter/material.dart';
import 'package:uniun/domain/entities/followed_note/thread_unread_marker.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// A small line above a note in a followed note's thread: a bright dot and
/// "New" when the note itself is unread, a quiet dot and "New reply inside"
/// when the unread note is further down. Draws nothing for [marker] null.
class UnreadTrailMark extends StatelessWidget {
  const UnreadTrailMark({super.key, required this.marker});

  final ThreadUnreadMarker? marker;

  @override
  Widget build(BuildContext context) {
    final m = marker;
    if (m == null || (!m.unread && !m.unreadInside)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final fresh = m.unread;
    final color = fresh ? scheme.error : scheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Container(
            key: const ValueKey('unread-trail-dot'),
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: fresh
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            fresh ? l10n.threadNewNote : l10n.threadNewReplyInside,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
