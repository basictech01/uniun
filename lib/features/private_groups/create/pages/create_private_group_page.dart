import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/atoms/uniun_back_button.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/advanced_section.dart';
import 'package:uniun/common/widgets/relay_selector_field.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/features/private_groups/create/bloc/create_private_group_bloc.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';

class CreatePrivateGroupPage extends StatelessWidget {
  const CreatePrivateGroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CreatePrivateGroupBloc>(),
      child: const _CreatePrivateGroupView(),
    );
  }
}

class _CreatePrivateGroupView extends StatefulWidget {
  const _CreatePrivateGroupView();

  @override
  State<_CreatePrivateGroupView> createState() => _CreatePrivateGroupViewState();
}

class _CreatePrivateGroupViewState extends State<_CreatePrivateGroupView> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final List<String> _selectedRelays = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    context.read<CreatePrivateGroupBloc>().add(
      SubmitCreatePrivateGroupEvent(
        name: name,
        description: _descController.text.trim(),
        relays: _selectedRelays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<CreatePrivateGroupBloc, CreatePrivateGroupState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state.isSuccess) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.createPrivateGroupSuccess),
              backgroundColor: context.custom.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        }
      },
      child: KeyboardDismissOnTap(
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: UniunBackButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              l10n.createPrivateGroupTitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            bottom: const _HairlineBorder(),
          ),
          body: BlocBuilder<CreatePrivateGroupBloc, CreatePrivateGroupState>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encrypted eyebrow — green, matching the DS SectionLabel.
                    _Eyebrow(
                      icon: Icons.lock_rounded,
                      label: l10n.createPrivateGroupEncrypted,
                      color: context.custom.success,
                    ),
                    const SizedBox(height: 20),

                    // Decorative encrypted emblem.
                    const Center(child: _LockEmblem()),
                    const SizedBox(height: 28),

                    // Name
                    _Eyebrow(label: l10n.createPrivateGroupNameLabel),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: l10n.createPrivateGroupNameHint,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _Eyebrow(label: l10n.createPrivateGroupDescLabel),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: l10n.createPrivateGroupDescHint,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Relays (advanced — defaulted, hidden from normal users)
                    AdvancedSection(
                      children: [
                        RelaySelectorField(
                          selected: _selectedRelays,
                          onChanged: (next) => setState(() => _selectedRelays
                            ..clear()
                            ..addAll(next)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Encrypted info — success tint.
                    _EncryptedInfoCard(
                      text: l10n.createPrivateGroupDescription,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.createPrivateGroupAdminNote,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.55,
                        color: context.custom.textMuted,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Primary action.
                    UniunButton(
                      large: true,
                      label: l10n.createPrivateGroupAction,
                      loading: state.isSubmitting,
                      onPressed: _submit,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 1px hairline under the app bar (DS `border-subtle`).
class _HairlineBorder extends StatelessWidget implements PreferredSizeWidget {
  const _HairlineBorder();

  @override
  Size get preferredSize => const Size.fromHeight(1);

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: context.custom.borderSubtle);
}

/// UPPERCASE wide-tracked eyebrow (DS `SectionLabel`): optional leading icon +
/// a tracked label. Defaults to the muted field-label treatment.
class _Eyebrow extends StatelessWidget {
  const _Eyebrow({
    required this.label,
    this.icon,
    this.color,
  });

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: resolved),
          const SizedBox(width: 6),
        ],
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: resolved,
          ),
        ),
      ],
    );
  }
}

/// Decorative 80×80 lock tile — the group's encrypted identity.
class _LockEmblem extends StatelessWidget {
  const _LockEmblem();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.lock_rounded,
        size: 38,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Success-tinted info card explaining the encryption guarantee.
class _EncryptedInfoCard extends StatelessWidget {
  const _EncryptedInfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.custom.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_rounded, size: 20, color: context.custom.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.55,
                color: context.custom.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
