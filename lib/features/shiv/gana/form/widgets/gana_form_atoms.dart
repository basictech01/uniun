part of '../pages/gana_form_page.dart';

class _EnabledSwitch extends StatelessWidget {
  const _EnabledSwitch({required this.state});
  final GanaFormState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      value: state.enabled,
      onChanged: (v) =>
          context.read<GanaFormBloc>().add(GanaFormEnabledToggleEvent(v)),
      title: Text(l10n.ganaFormEnabledLabel),
      subtitle: Text(l10n.ganaFormEnabledHelp),
      contentPadding: EdgeInsets.zero,
    );
  }
}

// ── Atoms ────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.6,
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      );
}

class _SectionSubtitle extends StatelessWidget {
  const _SectionSubtitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
            fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
}

/// Inline hint that explains why `canSave` is false. Replaces the
/// previous silent-grey-Save UX where the user had to guess what was
/// missing. Pulls its message from `state.saveBlocker(l10n)`.
class _SaveBlockerHint extends StatelessWidget {
  const _SaveBlockerHint({required this.reason});
  final String reason;

  @override
  Widget build(BuildContext context) {
    if (reason.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: Theme.of(context).colorScheme.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              style: TextStyle(
                  fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty-state for the Manas section when the user has zero Manases.
/// Pushes to the Brahma Manas form and reloads on return so the user
/// can keep creating the Gana without losing what they typed.
class _NoManasesCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.ganaFormManasEmpty,
            style: TextStyle(
                fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () async {
              final created =
                  await context.pushNamed<bool>(AppRoutes.brahmaManasForm);
              if (created == true && context.mounted) {
                final bloc = context.read<GanaFormBloc>();
                bloc.add(const GanaFormRefreshManasesEvent());
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.ganaFormManasCreateNew),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
InputDecoration _inputDeco(BuildContext context, String hint) =>
    InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainer,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );

String _shortKey(String s) {
  if (s.length <= 14) return s;
  return '${s.substring(0, 8)}…${s.substring(s.length - 4)}';
}
