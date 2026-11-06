import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/atoms/uniun_back_button.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/qr/uniun_qr_payload.dart';
import 'package:uniun/common/widgets/advanced_section.dart';
import 'package:uniun/common/widgets/relay_selector_field.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/router/nav_extensions.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/features/private_groups/join/bloc/join_private_group_bloc.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';

class JoinPrivateGroupPage extends StatelessWidget {
  const JoinPrivateGroupPage({super.key, this.payload});

  /// Pre-fill data from a QR scan or a `/private/<id>` deep link that fell
  /// back here because the group isn't joined yet.
  final UniunQrPayload? payload;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<JoinPrivateGroupBloc>(),
      child: _JoinPrivateGroupView(payload: payload),
    );
  }
}

class _JoinPrivateGroupView extends StatefulWidget {
  const _JoinPrivateGroupView({this.payload});

  final UniunQrPayload? payload;

  @override
  State<_JoinPrivateGroupView> createState() => _JoinPrivateGroupViewState();
}

class _JoinPrivateGroupViewState extends State<_JoinPrivateGroupView> {
  final _groupIdController = TextEditingController();
  final List<String> _selectedRelays = [];

  @override
  void initState() {
    super.initState();
    final args = widget.payload;
    if (args != null && args.kind == UniunQrKind.privateGroup) {
      _groupIdController.text = args.id;
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

  void _submit() {
    final groupId = _groupIdController.text.trim();
    if (groupId.isEmpty) return;

    context.read<JoinPrivateGroupBloc>().add(
      SubmitJoinPrivateGroupEvent(groupId: groupId, relays: _selectedRelays),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<JoinPrivateGroupBloc, JoinPrivateGroupState>(
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
              content: Text(l10n.joinPrivateGroupSuccess),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // In-app join → pop back where we came from. A deep-link join lands
          // here as the navigator root, so there's nothing to pop to — open the
          // group we just joined instead.
          context.popOr(() => context.goNamed(
                AppRoutes.privateGroupDetail,
                pathParameters: {'groupId': _groupIdController.text.trim()},
              ));
        }
      },
      child: KeyboardDismissOnTap(
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            shape: Border(
              bottom: BorderSide(color: context.custom.borderSubtle),
            ),
            leading: UniunBackButton(
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              l10n.joinPrivateGroupTitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
          body: BlocBuilder<JoinPrivateGroupBloc, JoinPrivateGroupState>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Encrypted eyebrow ──────────────────────────────────
                    Row(
                      children: [
                        Icon(Icons.lock_rounded,
                            size: 14, color: context.custom.success),
                        const SizedBox(width: 6),
                        Text(
                          l10n.joinPrivateGroupEncrypted.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: context.custom.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Scan a private group QR (prominent card) ─────────
                    _ScanQrCard(
                      title: l10n.joinPrivateGroupScanCardTitle,
                      subtitle: l10n.joinPrivateGroupScanCardSubtitle,
                      onTap: state.isSubmitting
                          ? null
                          : () => context.pushNamed(AppRoutes.scanQr),
                    ),

                    // ── or ─────────────────────────────────────────────────
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: _OrDivider(),
                    ),

                    // ── Group ID ───────────────────────────────────────────
                    TextField(
                      controller: _groupIdController,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: context.custom.surfaceLow,
                        hintText: l10n.joinPrivateGroupGroupIdHint,
                        hintStyle: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: context.custom.textMuted,
                        ),
                        prefixIcon: Icon(Icons.key_rounded,
                            size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.joinPrivateGroupGroupIdHelper,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: context.custom.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Relay (advanced — defaulted, hidden from normal users)
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

                    // ── Approval info ──────────────────────────────────────
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.custom.surfaceLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.custom.borderSubtle),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.how_to_reg_rounded,
                              size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.joinPrivateGroupApprovalInfo,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Request to join ────────────────────────────────────
                    const SizedBox(height: 24),
                    UniunButton(
                      size: UniunButtonSize.large,
                      label: l10n.joinPrivateGroupAction,
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

/// Prominent tappable card for opening the QR scanner — a tint circle + icon
/// above a title/subtitle. Same action as the old "Scan QR" button.
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.custom.border),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.qr_code_scanner_rounded,
                    size: 34, color: Theme.of(context).colorScheme.primary),
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
                  height: 1.45,
                  color: context.custom.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A centered "or" between two hairline rules.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(height: 1, child: ColoredBox(color: context.custom.borderSubtle)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            AppLocalizations.of(context)!.commonOr,
            style: TextStyle(fontSize: 12, color: context.custom.textMuted),
          ),
        ),
        Expanded(
          child: SizedBox(height: 1, child: ColoredBox(color: context.custom.borderSubtle)),
        ),
      ],
    );
  }
}
