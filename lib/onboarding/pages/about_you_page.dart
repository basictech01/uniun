import 'package:flutter/material.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';

/// Profile setup — shown after key generation on Create New Identity flow.
/// Route args: Map{'npub': String, 'nsec': String}
class AboutYouPage extends StatefulWidget {
  const AboutYouPage({super.key});

  @override
  State<AboutYouPage> createState() => _AboutYouPageState();
}

class _AboutYouPageState extends State<AboutYouPage> {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Map _args(BuildContext context) =>
      ModalRoute.of(context)?.settings.arguments as Map? ?? {};

  void _onContinue(BuildContext context) {
    final args = _args(context);
    // TODO: save Kind 0 profile event via BLoC
    Navigator.pushNamed(
      context,
      AppRoutes.yourIdentityKeys,
      arguments: args, // passes npub + nsec through
    );
  }

  void _goHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _OnboardingAppBar(onBack: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    // ── Heading ─────────────────────────────────────────
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'About You',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Let's set up your profile. This is how the community will see you.",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Avatar picker ────────────────────────────────────
                    GestureDetector(
                      onTap: () {
                        // TODO: image_picker → Blossom upload
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceContainer,
                              border:
                                  Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_a_photo_rounded,
                              size: 26,
                              color: AppColors.outlineVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Upload Photo',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Display Name ─────────────────────────────────────
                    _FieldLabel('Display Name'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _displayNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'What should we call you?',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Username ─────────────────────────────────────────
                    _FieldLabel('Username'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        hintText: 'username',
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 20, right: 0),
                          child: Text(
                            '@',
                            style: TextStyle(
                              color: AppColors.outline,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              height: 2.6,
                            ),
                          ),
                        ),
                        prefixIconConstraints:
                            BoxConstraints(minWidth: 0, minHeight: 0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Unique handle for mentions and search.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Bio ──────────────────────────────────────────────
                    _FieldLabel('Bio (Optional)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Tell us a bit about yourself...',
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Continue ─────────────────────────────────────────
                    Builder(
                      builder: (ctx) => GestureDetector(
                        onTap: () => _onContinue(ctx),
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPrimary,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Continue',
                              style: TextStyle(
                                color: AppColors.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: _goHome,
                      child: const Text(
                        'SET UP LATER',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_rounded,
                              size: 13, color: AppColors.primary),
                          SizedBox(width: 5),
                          Text(
                            'Your data is encrypted and private.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.onSurfaceVariant,
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
