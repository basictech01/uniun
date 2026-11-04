import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/features/groups/create/bloc/create_group_bloc.dart';
import 'package:uniun/common/atoms/uniun_back_button.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/advanced_section.dart';
import 'package:uniun/common/widgets/relay_selector_field.dart';
import 'package:uniun/features/settings/widgets/section_label.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';

class CreateGroupPage extends StatelessWidget {
  const CreateGroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CreateGroupBloc>()..add(LoadRelaysEvent()),
      child: const _CreateGroupView(),
    );
  }
}

class _CreateGroupView extends StatefulWidget {
  const _CreateGroupView();

  @override
  State<_CreateGroupView> createState() => _CreateGroupViewState();
}

class _CreateGroupViewState extends State<_CreateGroupView> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();

  final List<String> _selectedRelays = [];

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    context.read<CreateGroupBloc>().add(
      SubmitGroupEvent(
        name: _nameController.text,
        about: _aboutController.text,
        // Group image is not collected in v1 — created without a picture.
        picture: '',
        selectedRelays: _selectedRelays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<CreateGroupBloc, CreateGroupState>(
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
              content: Text(l10n.createGroupSuccess),
              backgroundColor: context.custom.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: UniunBackButton(
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            l10n.createGroupHeaderTitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(
                height: 1, thickness: 1, color: context.custom.borderSubtle),
          ),
        ),
        body: KeyboardDismissOnTap(
          child: BlocBuilder<CreateGroupBloc, CreateGroupState>(
            builder: (context, state) => _buildCreateForm(state, l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateForm(CreateGroupState state, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Group icon (decorative) ─────────────────────────────────────
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.tag_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Name ──────────────────────────────────────────────────────────
          SettingsSectionLabel(l10n.createGroupNameLabel),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            maxLength: 30,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: l10n.createGroupNamePlaceholder,
              counterText: '',
            ),
          ),
          const SizedBox(height: 20),

          // ── Description ───────────────────────────────────────────────────
          SettingsSectionLabel(l10n.createGroupDescriptionLabel),
          const SizedBox(height: 8),
          TextField(
            controller: _aboutController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.createGroupAboutPlaceholder,
            ),
          ),
          const SizedBox(height: 20),

          // ── Permanence note ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.custom.surfaceLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.custom.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.createGroupPermanenceNote,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Advanced · relays (collapsible) ───────────────────────────────
          const SizedBox(height: 16),
          AdvancedSection(
            label: l10n.createGroupAdvancedRelays,
            children: [
              Text(
                l10n.createGroupPublishRelaysBody,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: context.custom.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              RelaySelectorField(
                selected: _selectedRelays,
                onChanged: (next) => setState(() => _selectedRelays
                  ..clear()
                  ..addAll(next)),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // ── Create (bottom CTA) ───────────────────────────────────────────
          UniunButton(
            large: true,
            label: l10n.createGroupAction,
            loading: state.isSubmitting,
            onPressed: _onSubmit,
          ),
        ],
      ),
    );
  }
}
