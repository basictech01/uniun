import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/atoms/uniun_back_button.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/qr/uniun_qr_payload.dart';
import 'package:uniun/common/qr/uniun_qr_scanner_page.dart';
import 'package:uniun/common/widgets/advanced_section.dart';
import 'package:uniun/common/widgets/relay_selector_field.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/features/dm/create/bloc/create_dm_bloc.dart';
import 'package:uniun/features/settings/widgets/section_label.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';

class CreateDmPage extends StatelessWidget {
  const CreateDmPage({super.key, this.initialPubkey, this.payload});

  /// Pre-filled recipient (npub/hex) — e.g. from a QR scan.
  final String? initialPubkey;
  final UniunQrPayload? payload;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CreateDmBloc>()..add(LoadRelaysEvent()),
      child: _CreateDmView(initialPubkey: initialPubkey, payload: payload),
    );
  }
}

class _CreateDmView extends StatefulWidget {
  const _CreateDmView({this.initialPubkey, this.payload});

  final String? initialPubkey;
  final UniunQrPayload? payload;

  @override
  State<_CreateDmView> createState() => _CreateDmViewState();
}

class _CreateDmViewState extends State<_CreateDmView> {
  final _pubkeyController = TextEditingController();
  final List<String> _selectedRelays = [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPubkey;
    final payload = widget.payload;
    if (initial != null && initial.isNotEmpty) {
      _pubkeyController.text = initial;
    } else if (payload != null && payload.kind == UniunQrKind.user) {
      _pubkeyController.text = payload.id;
      _selectedRelays
        ..clear()
        ..addAll(payload.relays);
    }
  }

  @override
  void dispose() {
    _pubkeyController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    context.read<CreateDmBloc>().add(
      SubmitDmEvent(
        otherPubkey: _pubkeyController.text,
        selectedRelays: _selectedRelays,
      ),
    );
  }

  void _scanByQr() {
    // The unified scanner replaces this page with a fresh CreateDmPage
    // pre-filled from the scanned user payload.
    context.pushNamed(AppRoutes.scanQr, extra: UniunQrScanIntent.dm);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<CreateDmBloc, CreateDmState>(
      listener: (context, state) {
        // Relay pre-selection is handled by [RelaySelectorField], which
        // auto-selects the UNIUN backend relay when none is picked yet. A QR
        // payload that already carried relays is left untouched.
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
          final pubkey = _pubkeyController.text.trim();
          // Replace the creation screen with the chat (route id may be hex
          // or npub — the chatDm route normalises it).
          context.pushReplacementNamed(
            AppRoutes.chatDm,
            pathParameters: {'id': pubkey},
          );
        }
      },
      child: KeyboardDismissOnTap(
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
              l10n.createDmTitle,
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
          body: BlocBuilder<CreateDmBloc, CreateDmState>(
            builder: (context, state) => _buildForm(state, l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(CreateDmState state, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Decorative DM emblem ──────────────────────────────────────────
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.mail_rounded,
                size: 38,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Recipient ─────────────────────────────────────────────────────
          SettingsSectionLabel(l10n.createDmRecipientLabel),
          const SizedBox(height: 8),
          TextField(
            controller: _pubkeyController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: l10n.createDmRecipientHint,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: UniunButton(
              variant: UniunButtonVariant.outlined,
              height: 50,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: l10n.createDmScanQr,
              onPressed: state.isSubmitting ? null : _scanByQr,
            ),
          ),
          const SizedBox(height: 24),

          // ── Relays ────────────────────────────────────────────────────────
          AdvancedSection(
            children: [
              Text(
                l10n.createDmRelaysNote,
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
          const SizedBox(height: 24),

          // ── Encrypted note (NIP-17) ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.custom.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_rounded,
                    size: 20, color: context.custom.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.createDmEncryptedNote,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: context.custom.textBody,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // ── Start chat (bottom CTA) ───────────────────────────────────────
          UniunButton(
            size: UniunButtonSize.large,
            label: l10n.createDmAction,
            loading: state.isSubmitting,
            onPressed: _onSubmit,
          ),
        ],
      ),
    );
  }
}
