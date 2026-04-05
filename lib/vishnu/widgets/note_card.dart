import 'package:flutter/material.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';

class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.profile,
    this.replyCount = 0,
    this.isFollowed = false,
    this.isSaved = false,
    this.onFollowTap,
    this.onSaveTap,
  });

  final NoteEntity note;
  final VoidCallback onTap;
  final ProfileEntity? profile;
  final int replyCount;
  final bool isFollowed;
  final bool isSaved;
  final VoidCallback? onFollowTap;
  /// Called when user taps save — parent is responsible for persisting.
  final VoidCallback? onSaveTap;

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.isSaved;
  }

  @override
  void didUpdateWidget(NoteCard old) {
    super.didUpdateWidget(old);
    if (old.isSaved != widget.isSaved) _isSaved = widget.isSaved;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = widget.profile;
    final displayName = profile?.name ??
        profile?.username ??
        _shortName(widget.note.authorPubkey);

    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ──────────────────────────────────────────────────
            UserAvatar(
              seed: widget.note.authorPubkey,
              photoUrl: profile?.avatarUrl,
              size: 40,
              borderRadius: 20,
            ),
            const SizedBox(width: 12),

            // ── Content ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author row
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _timeAgo(widget.note.created),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.more_horiz_rounded,
                        size: 18,
                        color: AppColors.outlineVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Note content
                  Text(
                    widget.note.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                      height: 1.55,
                    ),
                  ),

                  // Hashtag chips
                  if (widget.note.tTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: widget.note.tTags
                          .take(3)
                          .map(
                            (t) => Text(
                              '#$t',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // ── Action row ────────────────────────────────────────
                  Row(
                    children: [
                      // Follow / Following
                      _ActionChip(
                        icon: widget.isFollowed
                            ? Icons.link_rounded
                            : Icons.add_link_rounded,
                        label: widget.isFollowed ? l10n.actionFollowing : l10n.actionFollow,
                        color: widget.isFollowed
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                        onTap: widget.onFollowTap ?? () {},
                      ),
                      const SizedBox(width: 20),

                      // Reply count
                      _ActionChip(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: '${widget.replyCount}',
                        color: AppColors.onSurfaceVariant,
                        onTap: widget.onTap,
                      ),
                      const SizedBox(width: 20),

                      // Save toggle — optimistic UI, parent persists
                      _ActionChip(
                        icon: _isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        label: _isSaved ? l10n.actionSaved : l10n.actionSave,
                        color: _isSaved
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                        onTap: () {
                          setState(() => _isSaved = !_isSaved);
                          widget.onSaveTap?.call();
                        },
                      ),

                      // Thread indicator
                      if (widget.note.eTagRefs.isNotEmpty) ...[
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.account_tree_rounded,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              l10n.vishnuThread,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortName(String pubkey) {
    if (pubkey.length <= 16) return pubkey;
    return '${pubkey.substring(0, 8)}...${pubkey.substring(pubkey.length - 4)}';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
