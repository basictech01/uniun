import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/onboarding/widgets/onboarding_app_bar.dart';

/// Login screen — "I Already Have a Key".
class ImportIdentityPage extends StatefulWidget {
  const ImportIdentityPage({super.key});

  @override
  State<ImportIdentityPage> createState() => _ImportIdentityPageState();
}

class _ImportIdentityPageState extends State<ImportIdentityPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canContinue => _controller.text.trim().isNotEmpty;

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() => _controller.text = data!.text!);
    }
  }

  Future<void> _onContinue() async {
    final l10n = AppLocalizations.of(context)!;
    final input = _controller.text.trim();
    if (input.isEmpty) {
      _showError(l10n.importPasteFirst);
      return;
    }

    try {
      final String hexPriv;
      if (input.startsWith('nsec1')) {
        hexPriv = Nip19.decodePrivkey(input);
        if (hexPriv.isEmpty) throw Exception('Invalid nsec');
      } else if (input.length == 64) {
        hexPriv = input;
      } else {
        throw Exception('Unrecognised key format');
      }

      final result = await getIt<ImportKeyUseCase>().call(input);
      if (!mounted) return;
      result.fold(
        (failure) => _showError(l10n.importFailed),
        (_) => Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        ),
      );
      return;
    } catch (_) {
      _showError(l10n.importInvalidKey);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final topGap = h < 680 ? 8.0 : 16.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OnboardingAppBar(onBack: () => Navigator.pop(context)),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: topGap),

                        Text(
                          l10n.importTitle,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.importSubtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),

                        SizedBox(height: topGap + 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.importPrivateKeyLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.3,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            GestureDetector(
                              onTap: _pasteFromClipboard,
                              child: Row(
                                children: [
                                  const Icon(Icons.content_paste_rounded,
                                      size: 13, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.importPasteFromClipboard,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: _controller,
                          maxLines: 4,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: AppColors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.importKeyHint,
                            fillColor: AppColors.surfaceContainerLow,
                          ),
                        ),

                        const Spacer(),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.security_rounded,
                                  color: AppColors.primary, size: 16),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.importSecurityNote,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        AnimatedOpacity(
                          opacity: _canContinue ? 1.0 : 0.45,
                          duration: const Duration(milliseconds: 150),
                          child: GestureDetector(
                            onTap: _canContinue ? _onContinue : null,
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _canContinue
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.22),
                                          blurRadius: 20,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  l10n.importContinue,
                                  style: const TextStyle(
                                    color: AppColors.onPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
