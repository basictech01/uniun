import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/core/l10n/app_language.dart';
import 'package:uniun/core/l10n/locale_cubit.dart';
import 'package:uniun/features/settings/widgets/settings_app_bar.dart';
import 'package:uniun/features/settings/widgets/settings_card.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Full language picker. Reachable from the welcome screen ("More languages")
/// and from Settings. Lists every [AppLanguage]: supported ones are selectable
/// (a check marks the active locale); not-yet-translated ones are greyed with a
/// "Coming soon" badge. Reads/writes the app-wide [LocaleCubit].
class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final active = context.watch<LocaleCubit>().activeLanguage;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: SettingsAppBar(title: l10n.languageSelectTitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          SettingsGroup(
            children: [
              for (final lang in [
                AppLanguage.gujarati,
                AppLanguage.japanese,
                ...AppLanguage.values.where(
                  (language) =>
                      language != AppLanguage.gujarati &&
                      language != AppLanguage.japanese,
                ),
              ])
                _LanguageTile(
                  language: lang,
                  isActive: lang == active,
                  comingSoonLabel: l10n.languageComingSoon,
                  onTap: lang.supported
                      ? () {
                          context.read<LocaleCubit>().setLanguage(lang);
                          Navigator.of(context).pop();
                        }
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.isActive,
    required this.comingSoonLabel,
    required this.onTap,
  });

  final AppLanguage language;
  final bool isActive;
  final String comingSoonLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final titleColor = enabled
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurfaceVariant;

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language.nativeName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  language.englishName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!language.supported)
            _ComingSoonBadge(label: comingSoonLabel)
          else if (isActive)
            Icon(
              Icons.check_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );

    if (!enabled) return Opacity(opacity: 0.7, child: row);
    return InkWell(onTap: onTap, child: row);
  }
}

class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
