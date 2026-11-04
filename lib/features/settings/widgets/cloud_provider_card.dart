import 'package:flutter/material.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/core/router/deep_link.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/domain/entities/llm/llm_model_info.dart';
import 'package:uniun/domain/usecases/ai_model_usecases.dart';
import 'package:uniun/domain/repositories/user_repository.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/features/settings/widgets/settings_card.dart';
import 'package:uniun/features/shiv/model_select/utils/ai_model_l10n.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings row for UNIUN Cloud. Lives inside the AI · Shiv group alongside
/// the on-device model row, so it renders as a single [SettingsRow].
///
/// Empty state: tapping the row runs the SILENT keypair login (challenge →
/// sign → login on the inference gateway) — no key to paste, the user's
/// UNIUN identity is the account.
/// Connected state: the row opens a manage sheet listing the plan-allowed
/// cloud models plus the on-device model. Picking a row IS the backend
/// switch — a cloud model activates the cloud backend, the on-device row
/// activates local. There is no separate backend toggle.
///
/// Self-contained — uses use cases directly rather than a cubit, since the
/// row has only a handful of states and lives in the slow-changing Settings
/// page. If multiple surfaces grow to share this state, lift to a cubit.
class CloudProviderCard extends StatefulWidget {
  const CloudProviderCard({super.key});

  @override
  State<CloudProviderCard> createState() => _CloudProviderCardState();
}

class _CloudProviderCardState extends State<CloudProviderCard> {
  bool _loading = true;
  bool _connecting = false;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final connected = await getIt<IsUniunCloudConnectedUseCase>().call();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _connected = connected;
    });
  }

  Future<void> _connect() async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _connecting = true);

    final result = await getIt<ConnectUniunCloudUseCase>().call();
    if (!mounted) return;
    setState(() => _connecting = false);
    result.fold(
      (_) => scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.cloudProviderConnectFailed)),
      ),
      (_) {},
    );
    await _load();
  }

  Future<void> _openManageSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ManageSheet(),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading || _connecting) {
      return SettingsRow(
        icon: Icons.cloud_outlined,
        label: l10n.cloudProviderTitle,
        subtitle: _connecting ? l10n.cloudProviderConnecting : null,
        showChevron: false,
        trailing: SizedBox(
          width: 18,
          height: 18,
          child: DropLoadingIndicator(
              size: 18, color: Theme.of(context).colorScheme.primary),
        ),
      );
    }

    if (!_connected) {
      // Empty state — tapping the row signs in silently with the user's keys.
      return SettingsRow(
        icon: Icons.cloud_outlined,
        label: l10n.cloudProviderTitle,
        subtitle: l10n.cloudProviderEmptySubtitle,
        onTap: _connect,
      );
    }

    // Connected — whole row opens the model / manage sheet.
    return SettingsRow(
      icon: Icons.cloud_done_outlined,
      label: l10n.cloudProviderTitle,
      subtitle: l10n.cloudProviderConnectedSubtitle,
      onTap: _openManageSheet,
    );
  }
}

/// Bottom sheet listing the plan-allowed cloud models and the on-device
/// model. Selecting a row activates both the model and its backend.
class _ManageSheet extends StatefulWidget {
  const _ManageSheet();

  @override
  State<_ManageSheet> createState() => _ManageSheetState();
}

class _ManageSheetState extends State<_ManageSheet> with WidgetsBindingObserver {
  bool _loading = true;
  List<LlmModelInfo> _cloudModels = const [];
  bool _cloudLoadFailed = false;
  LlmBackendType _activeBackend = LlmBackendType.localGemma;
  String? _activeCloudModelId;
  AIModelId? _localModelId;
  String? _switchingId; // row showing a spinner ('' = on-device row)
  ({String plan, num balance})? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Payment happens on the website (checkout there, not in-app, to avoid
    // store IAP cuts) — refresh plan/credits when the user comes back from
    // that browser tab so the new plan shows without reopening the sheet.
    if (state == AppLifecycleState.resumed) _load();
  }

  /// Opens the website's pricing page. Payment is attributed by pubkey —
  /// public by definition, so it's safe in a URL — not by any key, so there
  /// is nothing to mint, nothing that can leak, nothing that expires
  /// mid-checkout.
  Future<void> _openPricing() async {
    final keys = await getIt<UserRepository>().getActiveKeysHex();
    if (keys == null) return;

    final uri = Uri(
      scheme: kDeepLinkScheme,
      host: kDeepLinkHost,
      path: 'pricing',
      queryParameters: {'pubkey': keys.pubkeyHex},
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _load() async {
    final backendResult = await getIt<GetActiveLlmBackendUseCase>().call();
    final backend =
        backendResult.fold((_) => LlmBackendType.localGemma, (b) => b);
    final modelResult = await getIt<GetActiveLlmModelUseCase>().call();
    final activeCloudId = modelResult.fold(
      (_) => null,
      (m) => m?.backend == LlmBackendType.uniunCloud ? m?.id : null,
    );
    final localResult = await getIt<GetActiveAIModelUseCase>().call();
    final localId = localResult.fold((_) => null, (m) => m?.modelId);
    final cloudResult = await getIt<ListCloudLlmModelsUseCase>().call();
    final statusResult = await getIt<GetUniunCloudStatusUseCase>().call();

    if (!mounted) return;
    setState(() {
      _loading = false;
      _activeBackend = backend;
      _activeCloudModelId = activeCloudId;
      _localModelId = localId;
      _status = statusResult.fold((_) => null, (s) => s);
      cloudResult.fold(
        (_) => _cloudLoadFailed = true,
        (list) => _cloudModels = list,
      );
    });
  }

  Future<void> _selectCloud(LlmModelInfo model) async {
    if (_switchingId != null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _switchingId = model.id);

    final switched = await getIt<SetActiveLlmBackendUseCase>()
        .call(LlmBackendType.uniunCloud);
    final failure = await switched.fold(
      (f) async => f,
      (_) async {
        final set = await getIt<SetActiveLlmModelUseCase>().call(model.id);
        return set.fold((f) => f, (_) => null);
      },
    );
    if (!mounted) return;
    if (failure != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(failure.toMessage())),
      );
      setState(() => _switchingId = null);
      return;
    }
    setState(() {
      _switchingId = null;
      _activeBackend = LlmBackendType.uniunCloud;
      _activeCloudModelId = model.id;
    });
  }

  Future<void> _selectOnDevice() async {
    if (_switchingId != null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _switchingId = '');

    final result = await getIt<SetActiveLlmBackendUseCase>()
        .call(LlmBackendType.localGemma);
    if (!mounted) return;
    result.fold(
      (f) => scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(f.toMessage())),
      ),
      (_) {},
    );
    setState(() {
      _switchingId = null;
      _activeBackend = LlmBackendType.localGemma;
    });
  }

  Future<void> _disconnect({bool confirm = false}) async {
    final result = await getIt<DisconnectUniunCloudUseCase>().call(confirm);
    final needsConfirm =
        result.fold((f) => f.toMessage() == 'last_active_key', (_) => false);
    if (needsConfirm) {
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.cloudProviderLastKeyTitle),
          content:
              Text(AppLocalizations.of(context)!.cloudProviderLastKeyMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(AppLocalizations.of(context)!.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(AppLocalizations.of(context)!.cloudProviderDisconnect),
            ),
          ],
        ),
      );
      if (proceed == true) await _disconnect(confirm: true);
      return;
    }
    // If cloud was active, fall back to local so the next chat send doesn't
    // hit an empty-credentials state.
    if (_activeBackend == LlmBackendType.uniunCloud) {
      await getIt<SetActiveLlmBackendUseCase>()
          .call(LlmBackendType.localGemma);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.cloudProviderTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            if (_status != null) ...[
              const SizedBox(height: 6),
              Text(
                '${l10n.cloudProviderPlanLabel}: ${_status!.plan} · '
                '${l10n.cloudProviderCreditsLabel}: ${_formatBalance(_status!.balance)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              UniunButton(
                variant: UniunButtonVariant.outlined,
                borderColor: scheme.primary.withValues(alpha: 0.4),
                height: 40,
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: l10n.cloudProviderUpgrade,
                onPressed: _openPricing,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.cloudProviderUpgradeHint,
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              l10n.cloudProviderModelsHeader,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            if (_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child:
                      DropLoadingIndicator(size: 20, color: scheme.primary),
                ),
              )
            else if (_cloudLoadFailed || _cloudModels.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.cloudProviderNoCloudModels,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              )
            else
              ..._cloudModels.map((m) => _ModelRow(
                    icon: Icons.cloud_outlined,
                    label: m.displayName,
                    isActive: _activeBackend == LlmBackendType.uniunCloud &&
                        _activeCloudModelId == m.id,
                    isSwitching: _switchingId == m.id,
                    onTap: () => _selectCloud(m),
                  )),
            const SizedBox(height: 4),
            Divider(color: scheme.outlineVariant, height: 1),
            const SizedBox(height: 4),
            _ModelRow(
              icon: Icons.phone_iphone_rounded,
              label: _localModelId != null
                  ? '${l10n.cloudProviderOnDevice} · ${_localModelId!.displayName(l10n)}'
                  : '${l10n.cloudProviderOnDevice} · ${l10n.cloudProviderOnDeviceNotSet}',
              isActive: _activeBackend == LlmBackendType.localGemma,
              isSwitching: _switchingId == '',
              onTap: _selectOnDevice,
            ),
            const SizedBox(height: 4),
            Divider(color: scheme.outlineVariant, height: 1),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _disconnect,
                icon: const Icon(Icons.link_off_rounded, size: 18),
                label: Text(l10n.cloudProviderDisconnect),
                style: TextButton.styleFrom(foregroundColor: scheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatBalance(num balance) => balance.toStringAsFixed(2);

class _ModelRow extends StatelessWidget {
  const _ModelRow({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isSwitching,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final bool isSwitching;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: isSwitching ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isActive ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? scheme.primary : scheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSwitching)
              DropLoadingIndicator(size: 16, color: scheme.primary)
            else if (isActive)
              Icon(Icons.check_circle_rounded, size: 20, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}
