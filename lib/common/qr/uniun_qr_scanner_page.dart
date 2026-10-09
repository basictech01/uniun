import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uniun/common/atoms/uniun_back_button.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/qr/uniun_qr_payload.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/router/deep_link.dart';
import 'package:uniun/core/utils/pubkey_normalizer.dart';
import 'package:uniun/domain/repositories/uniun_repository.dart';
import 'package:uniun/domain/usecases/followed_user_usecases.dart';
import 'package:uniun/features/profile/pages/user_profile_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Universal QR scanner. Decodes any [UniunQrPayload] and dispatches:
///   - user           → see [UniunQrScanIntent] (profile / auto-follow / auto-dm)
///   - publicGroup  → JoinGroupPage (UniunQrPayload argument)
///   - privateGroup → JoinPrivateGroupPage (UniunQrPayload argument)
///   - loginSession → approves the browser's UNIUN Cloud QR-login session
///                       directly (no destination page) — requires this
///                       device to already be connected to UNIUN Cloud.
///
/// Intent is read from the route argument and only affects user QRs:
///   - [generic]: open the user's profile page.
///   - [follow]:  run Follow directly, snackbar + pop.
///   - [dm]:      open CreateDmPage prefilled.
enum UniunQrScanIntent { generic, follow, dm }

class UniunQrScannerPage extends StatefulWidget {
  const UniunQrScannerPage({
    super.key,
    this.intent = UniunQrScanIntent.generic,
  });

  /// What to do once a user QR is decoded. Set by the launching route via
  /// `extra` — see [appRouter]'s scanQr route.
  final UniunQrScanIntent intent;

  @override
  State<UniunQrScannerPage> createState() => _UniunQrScannerPageState();
}

class _UniunQrScannerPageState extends State<UniunQrScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _handled = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleRaw(String raw) async {
    if (_handled) return;
    final UniunQrPayload payload;
    try {
      payload = UniunQrPayload.decode(raw);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.qrScannerInvalidCode('${e is FormatException ? e.message : e}'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _handled = true;

    await ensureRelays(payload.relays);
    if (!mounted) return;

    if (payload.kind == UniunQrKind.user) {
      await _dispatchUser(payload, widget.intent);
      return;
    }

    if (payload.kind == UniunQrKind.loginSession) {
      await _approveQrLogin(payload);
      return;
    }

    final route = switch (payload.kind) {
      UniunQrKind.user => AppRoutes.userProfile, // unreachable, handled above
      UniunQrKind.loginSession =>
        AppRoutes.userProfile, // unreachable, handled above
      UniunQrKind.publicGroup => AppRoutes.joinGroup,
      UniunQrKind.privateGroup => AppRoutes.joinPrivateGroup,
    };
    context.pushReplacementNamed(route, extra: payload);
  }

  /// Approves a browser's UNIUN Cloud QR-login session. The device must
  /// already be connected — this never signs in silently on the user's
  /// behalf, since approving would hand the browser this account's key.
  Future<void> _approveQrLogin(UniunQrPayload payload) async {
    final l10n = AppLocalizations.of(context)!;
    final uniun = getIt<UniunRepository>();

    final connected = await uniun.isConnected();
    if (!mounted) return;
    if (!connected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.qrLoginNotConnected)));
      Navigator.of(context).pop();
      return;
    }

    final result = await uniun.approveQrLogin(payload.id);
    if (!mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.qrLoginFailed(f.toString())))),
      (_) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.qrLoginApproved))),
    );
    Navigator.of(context).pop();
  }

  Future<void> _dispatchUser(
    UniunQrPayload payload,
    UniunQrScanIntent intent,
  ) async {
    if (intent == UniunQrScanIntent.dm) {
      context.pushReplacementNamed(AppRoutes.createDm, extra: payload);
      return;
    }

    final String hex;
    try {
      hex = normalizeNostrPubkey(payload.id);
    } on FormatException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.followActionInvalidKey),
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    if (intent == UniunQrScanIntent.follow) {
      final result = await getIt<FollowUserUseCase>().call(
        FollowUserInput(pubkeyHex: hex, petname: payload.name),
      );
      if (!mounted) return;
      result.fold(
        (f) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(f.toString()))),
        (_) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.followActionSuccess),
          ),
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    context.pushReplacementNamed(
      AppRoutes.userProfile,
      extra: UserProfileArgs(pubkeyHex: hex, hintName: payload.name),
    );
  }

  Future<void> _pickFromGallery() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;
    final capture = await _scannerController.analyzeImage(image.path);
    if (!mounted) return;
    final raw = capture?.barcodes.isEmpty ?? true
        ? null
        : capture!.barcodes.first.rawValue?.trim();
    if (raw == null || raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.joinGroupQrGalleryError),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _handleRaw(raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: const UniunBackButton(color: Colors.white),
        title: Text(AppLocalizations.of(context)!.joinPrivateGroupScanQr),
        actions: [
          IconButton(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: AppLocalizations.of(context)!.joinGroupQrFromGallery,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_handled) return;
              final raw = capture.barcodes.isEmpty
                  ? null
                  : capture.barcodes.first.rawValue?.trim();
              if (raw == null || raw.isEmpty) return;
              _handleRaw(raw);
            },
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppLocalizations.of(context)!.qrScannerInstruction,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
