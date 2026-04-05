import 'package:flutter/material.dart';
import 'package:uniun/core/theme/app_theme.dart';

enum ReferenceSectionStyle { grid, list }

class NoteReferencesSection extends StatelessWidget {
  const NoteReferencesSection({
    super.key,
    required this.title,
    required this.references,
    this.style = ReferenceSectionStyle.list,
    this.badge,
  });

  final String title;
  final List<ReferenceEntry> references;
  final ReferenceSectionStyle style;
  final String? badge;


  @override
  Widget build(BuildContext context) {
    if (references.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Content ────────────────────────────────────────────────────────
        if (style == ReferenceSectionStyle.grid)
          _GridContent(references: references)
        else
          _ListContent(references: references),
      ],
    );
  }
}

// ── Grid layout (Referenced By) ───────────────────────────────────────────────

class _GridContent extends StatelessWidget {
  const _GridContent({required this.references});
  final List<ReferenceEntry> references;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemCount: references.length,
      itemBuilder: (_, i) => _GridCard(entry: references[i]),
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({required this.entry});
  final ReferenceEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              '"${entry.subtitle}"',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── List layout (References) ──────────────────────────────────────────────────

class _ListContent extends StatelessWidget {
  const _ListContent({required this.references});
  final List<ReferenceEntry> references;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: List.generate(references.length, (i) {
          final entry = references[i];
          final isLast = i == references.length - 1;
          return InkWell(
            onTap: () {},
            borderRadius: BorderRadius.vertical(
              top: i == 0 ? const Radius.circular(18) : Radius.zero,
              bottom: isLast ? const Radius.circular(18) : Radius.zero,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: AppColors.outlineVariant
                              .withValues(alpha: 0.15),
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDBC7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: AppColors.tertiary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        if (entry.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            entry.subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.outlineVariant,
                    size: 18,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class ReferenceEntry {
  const ReferenceEntry({required this.title, this.subtitle = ''});
  final String title;
  final String subtitle;
}
