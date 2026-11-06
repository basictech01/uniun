import 'package:flutter/material.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/features/shiv/nataraj/bloc/nataraj_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Centered empty / terminal state widget for the Nataraj deck area.
///
/// Renders different copy for [NatarajStatus.needsMoreNotes] and
/// [NatarajStatus.exhausted]. [onAddNotes] is fired when the CTA is tapped.
class NatarajEmptyState extends StatelessWidget {
  const NatarajEmptyState({
    super.key,
    required this.status,
    required this.onAddNotes,
  });

  final NatarajStatus status;
  final VoidCallback onAddNotes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (status) {
      NatarajStatus.needsMoreNotes => _EmptyStateBody(
          emoji: '✦',
          title: l10n.natarajEmptyNeedsMoreTitle,
          body: l10n.natarajEmptyNeedsMoreBody,
          ctaLabel: l10n.natarajEdgePublish, // reuses "Publish" action label
          onCta: onAddNotes,
        ),
      NatarajStatus.exhausted => _EmptyStateBody(
          emoji: '✦',
          title: l10n.natarajExhaustedTitle,
          body: l10n.natarajExhaustedBody,
          ctaLabel: l10n.natarajEdgePublish,
          onCta: onAddNotes,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _EmptyStateBody extends StatelessWidget {
  const _EmptyStateBody({
    required this.emoji,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
  });

  final String emoji;
  final String title;
  final String body;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _CtaButton(label: ctaLabel, onTap: onCta),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return UniunButton(
      expand: false,
      height: 48,
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      label: label,
      onPressed: onTap,
    );
  }
}
