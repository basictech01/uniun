import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/domain/repositories/user_repository.dart';
import 'package:uniun/core/theme/app_theme.dart';

/// Login screen — "I Already Have a Key".
/// Compact one-page layout matching signup style.
class ImportIdentityPage extends StatefulWidget {
  const ImportIdentityPage({super.key});

  @override
  State<ImportIdentityPage> createState() => _ImportIdentityPageState();
}

class _ImportIdentityPageState extends State<ImportIdentityPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() => _controller.text = data!.text!);
    }
  }

  Future<void> _onContinue() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      _showError('Please paste your private key first.');
      return;
    }

    try {
      // Resolve hex private key — accept both nsec1 bech32 and raw hex
      final String hexPriv;
      if (input.startsWith('nsec1')) {
        hexPriv = Nip19.decodePrivkey(input);
        if (hexPriv.isEmpty) throw Exception('Invalid nsec');
      } else if (input.length == 64) {
        hexPriv = input; // raw 32-byte hex
      } else {
        throw Exception('Unrecognised key format');
      }

      final result = await getIt<UserRepository>().importKey(input);
      if (!mounted) return;
      result.fold(
        (failure) => _showError('Failed to import key. Please try again.'),
        (_) => Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        ),
      );
      return;
    } catch (_) {
      _showError('Invalid key. Please check and try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
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
                _OnboardingAppBar(onBack: () => Navigator.pop(context)),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: topGap),

                        // ── Heading ────────────────────────────────────
                        const Text(
                          'Import Your Identity',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Paste your private key to recover your existing profile.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),

                        SizedBox(height: topGap + 8),

                        // ── Label + paste ──────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'PRIVATE KEY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.3,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            GestureDetector(
                              onTap: _pasteFromClipboard,
                              child: const Row(
                                children: [
                                  Icon(Icons.content_paste_rounded,
                                      size: 13, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Paste from Clipboard',
                                    style: TextStyle(
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

                        // ── nsec textarea ──────────────────────────────
                        TextField(
                          controller: _controller,
                          maxLines: 4,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: AppColors.onSurface,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'nsec1... or 64-character hex key',
                            fillColor: AppColors.surfaceContainerLow,
                          ),
                        ),

                        const Spacer(),

                        // ── Security note ──────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.security_rounded,
                                  color: AppColors.primary, size: 16),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Your private key is processed locally and never sent to any server.',
                                  style: TextStyle(
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

                        // ── Continue button ────────────────────────────
                        GestureDetector(
                          onTap: _onContinue,
                          child: Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.22),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Import & Continue',
                                style: TextStyle(
                                  color: AppColors.onPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
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

class _OnboardingAppBar extends StatelessWidget {
  const _OnboardingAppBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.primary),
            onPressed: onBack,
          ),
          const Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image(
                    image: AssetImage('assets/images/uniun-logo.png'),
                    height: 24,
                    width: 24,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'UNIUN',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
