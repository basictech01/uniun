import 'package:flutter/material.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/onboarding/widgets/field_label.dart';
import 'package:uniun/onboarding/widgets/generated_avatar.dart';
import 'package:uniun/onboarding/widgets/onboarding_app_bar.dart';

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

  String? _displayNameError;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _displayNameController.addListener(() => setState(() {}));
    _usernameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Map _args(BuildContext context) =>
      ModalRoute.of(context)?.settings.arguments as Map? ?? {};

  bool get _canContinue =>
      _displayNameController.text.trim().isNotEmpty &&
      _usernameController.text.trim().isNotEmpty;

  void _onContinue(BuildContext context) {
    final name = _displayNameController.text.trim();
    final username = _usernameController.text.trim();

    bool hasError = false;
    if (name.isEmpty) {
      setState(() => _displayNameError = 'Display name is required');
      hasError = true;
    } else {
      setState(() => _displayNameError = null);
    }
    if (username.isEmpty) {
      setState(() => _usernameError = 'Username is required');
      hasError = true;
    } else {
      setState(() => _usernameError = null);
    }
    if (hasError) return;

    final args = _args(context);
    Navigator.pushNamed(
      context,
      AppRoutes.yourIdentityKeys,
      arguments: {
        ...args,
        'displayName': name,
        'username': username,
        'bio': _bioController.text.trim(),
      },
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
    final args = _args(context);
    final npub = args['npub'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingAppBar(onBack: () => Navigator.pop(context)),
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
                        "Set up your profile. Display Name and Username are required.",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Avatar ────────────────────────────────────────
                    GeneratedAvatar(
                      seed: npub,
                      name: _displayNameController.text.trim(),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Auto-generated · Photo optional',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Display Name ──────────────────────────────────
                    const FieldLabel('Display Name *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _displayNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'What should we call you?',
                        errorText: _displayNameError,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Username ──────────────────────────────────────
                    const FieldLabel('Username *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'username',
                        errorText: _usernameError,
                        prefixIcon: const Padding(
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
                            const BoxConstraints(minWidth: 0, minHeight: 0),
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

                    // ── Bio (optional) ────────────────────────────────
                    const FieldLabel('Bio  (optional)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Tell the world a bit about yourself…',
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Continue button ───────────────────────────────
                    Builder(
                      builder: (ctx) => AnimatedOpacity(
                        opacity: _canContinue ? 1.0 : 0.45,
                        duration: const Duration(milliseconds: 150),
                        child: GestureDetector(
                          onTap: () => _onContinue(ctx),
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: _canContinue
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
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
