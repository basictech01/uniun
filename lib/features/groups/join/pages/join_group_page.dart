import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/atoms/uniun_back_button.dart';
import 'package:uniun/common/qr/uniun_qr_payload.dart';
import 'package:uniun/common/widgets/advanced_section.dart';
import 'package:uniun/common/widgets/relay_selector_field.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/router/nav_extensions.dart';
import 'package:uniun/features/groups/join/bloc/join_group_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/l10n/app_localizations.dart';

class JoinGroupPage extends StatelessWidget {
  const JoinGroupPage({super.key, this.payload});

  /// Pre-fill data from a QR scan or a `/group/<id>` deep link that fell
  /// back here because the group isn't joined yet.
  final UniunQrPayload? payload;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<JoinGroupBloc>(),
      child: _JoinGroupView(payload: payload),
    );
  }
}

class _JoinGroupView extends StatefulWidget {
  const _JoinGroupView({this.payload});

  final UniunQrPayload? payload;

  @override
  State<_JoinGroupView> createState() => _JoinGroupViewState();
}

class _JoinGroupViewState extends State<_JoinGroupView> {
  final _groupIdController = TextEditingController();
  final List<String> _selectedRelays = [];
  String _prefilledName = '';

  @override
  void initState() {
    super.initState();
    final args = widget.payload;
    if (args != null && args.kind == UniunQrKind.publicGroup) {
      _groupIdController.text = args.id;
      _prefilledName = args.name ?? '';
      _selectedRelays
        ..clear()
        ..addAll(args.relays);
    }
  }

  @override
  void dispose() {
    _groupIdController.dispose();
    super.dispose();
  }

  void _submitJoin() {
    context.read<JoinGroupBloc>().add(
      SubmitJoinGroupEvent(
        groupId: _groupIdController.text,
        selectedRelays: _selectedRelays,
        groupName: _prefilledName,
      ),
    );
  }

  Future<void> _joinByQr() async {
    // The unified scanner replaces this page with the right destination, so
    // we just push and let it take over.
    context.pushNamed(AppRoutes.scanQr);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<JoinGroupBloc, JoinGroupState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorText(state.error!, l10n)),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.joinGroupSuccess),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // In-app join → pop back where we came from. A deep-link join lands
          // here as the navigator root, so there's nothing to pop to — open the
          // group we just joined instead.
          context.popOr(() => context.goNamed(
                AppRoutes.groupDetail,
                pathParameters: {'groupId': _groupIdController.text.trim()},
              ));
        }
      },
      child: KeyboardDismissOnTap(
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            centerTitle: true,
            shape: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            leading: UniunBackButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              l10n.joinGroupTitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
          body: BlocBuilder<JoinGroupBloc, JoinGroupState>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scan a group QR — the primary affordance.
                    _ScanQrCard(
                      title: l10n.joinGroupScanCardTitle,
                      subtitle: l10n.joinGroupScanCardSubtitle,
                      onTap: state.isSubmitting ? null : _joinByQr,
                    ),
                    const SizedBox(height: 20),
                    _OrDivider(label: l10n.joinGroupOr),
                    const SizedBox(height: 20),
                    // Paste group id (hex — mono).
                    TextField(
                      controller: _groupIdController,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.joinGroupIdHint,
                        hintStyle: TextStyle(
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        prefixIcon: Icon(
                          Icons.tag_rounded,
                          size: 20,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AdvancedSection(
                      children: [
                        Text(
                          l10n.joinGroupRelaysBody,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
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
                    const SizedBox(height: 24),
                    UniunButton(
                      size: UniunButtonSize.large,
                      label: l10n.joinGroupAction,
                      loading: state.isSubmitting,
                      onPressed: _submitJoin,
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

/// Maps a [JoinGroupError] from the bloc to a localized message.
String _errorText(JoinGroupError error, AppLocalizations l10n) {
  return switch (error) {
    JoinGroupError.invalidId => l10n.joinGroupErrorInvalidId,
    JoinGroupError.noRelay => l10n.joinGroupErrorNoRelay,
    JoinGroupError.relaySaveFailed => l10n.joinGroupErrorRelaySaveFailed,
    JoinGroupError.saveFailed => l10n.joinGroupErrorSaveFailed,
  };
}

// Prominent tap-to-scan card at the top of the join flow. A null [onTap]
// renders it disabled (while a join is submitting).
class _ScanQrCard extends StatelessWidget {
  const _ScanQrCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.20),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 34,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Hairline "or" divider between the scan card and the paste-id input.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
      ),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
          ),
        ),
        line,
      ],
    );
  }
}
