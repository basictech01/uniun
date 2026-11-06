import 'package:flutter/material.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/core/i18n/translation_language.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Language picker for note translation.
///
/// Shown on the FIRST Translate tap only — the chosen language is persisted and
/// every later tap translates in one go. Re-openable from the "Change" action
/// on a translated note's footer.
///
/// Returns the picked [TranslationLanguage], or null if dismissed.
class TranslateLanguageSheet extends StatefulWidget {
  const TranslateLanguageSheet({
    super.key,
    required this.initial,
    this.seededFromAppLocale = false,
  });

  /// Pre-selected on open — the persisted choice, or the app locale on first
  /// run so the common case is confirm-and-go.
  final TranslationLanguage initial;

  /// True only on first run, when [initial] is a guess from the app locale
  /// rather than something the user picked — drives the explanatory hint.
  final bool seededFromAppLocale;

  static Future<TranslationLanguage?> show(
    BuildContext context, {
    required TranslationLanguage initial,
    bool seededFromAppLocale = false,
  }) {
    return showModalBottomSheet<TranslationLanguage>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TranslateLanguageSheet(
        initial: initial,
        seededFromAppLocale: seededFromAppLocale,
      ),
    );
  }

  @override
  State<TranslateLanguageSheet> createState() => _TranslateLanguageSheetState();
}

class _TranslateLanguageSheetState extends State<TranslateLanguageSheet> {
  late TranslationLanguage _selected = widget.initial;

  /// [TranslateLanguageSheet.initial] hoisted to the top, then the rest in
  /// catalogue order. Computed ONCE from `initial` rather than from
  /// [_selected] so the list never reorders under the user's finger while
  /// they are choosing.
  late final List<TranslationLanguage> _ordered = [
    widget.initial,
    for (final l in TranslationLanguage.all)
      if (l.code != widget.initial.code) l,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.translateSheetTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _ordered.length,
                itemBuilder: (context, i) {
                  final lang = _ordered[i];
                  final isSelected = lang.code == _selected.code;
                  final tile = ListTile(
                    dense: true,
                    onTap: () => setState(() => _selected = lang),
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 20,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                    title: Text(
                      lang.nativeName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    // Endonym alone isn't always enough to identify a row.
                    // The "from your app language" note is only honest on the
                    // first run, before the user has chosen for themselves.
                    subtitle: Text(
                      widget.seededFromAppLocale &&
                              lang.code == widget.initial.code
                          ? '${lang.englishName} · ${l10n.translateSheetSettingsHint}'
                          : lang.englishName,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                  // Rule under the pinned current language, separating it
                  // from the full catalogue below.
                  if (i != 0) return tile;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      tile,
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: UniunButton(
                  label: l10n.translateSheetAction,
                  onPressed: () => Navigator.pop(context, _selected),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
