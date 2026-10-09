import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uniun/common/qr/uniun_qr_payload.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/router/deep_link.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Near-black QR ink. Kept independent of the theme — a QR must stay
/// dark-on-white to scan reliably (the app is light-only in v1).
const Color _kQrInk = Color(0xFF15181C);

/// Small leading-icon widget used by the group/private-group cards. Pulls its
/// tint from the active `ColorScheme.primary` at build time so it works in
/// dark mode; kept const-constructible so the factory constructors above can
/// still be `const`.
class _PrimaryTintedIcon extends StatelessWidget {
  const _PrimaryTintedIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: 26, color: Theme.of(context).colorScheme.primary);
}

/// Shared QR display sheet used for all four sharing kinds. Present via
/// [UniunQrCard.show]. Always copies the FULL underlying id to the clipboard —
/// never a truncated display string.
class UniunQrCard extends StatefulWidget {
  const UniunQrCard._({required this.entries});

  /// Tabs/entries shown in the card. Single-entry cards render without a
  /// toggle; multi-entry cards (DM) show a segmented header.
  // ignore: library_private_types_in_public_api
  final List<_QrEntry> entries;

  /// Presents [card] as a modal bottom sheet with the app's standard chrome
  /// (rounded top, drag handle, scrollable body). Centralized so every call
  /// site stays a one-liner and shares identical styling.
  static Future<void> show(BuildContext context, {required UniunQrCard card}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => card,
    );
  }

  /// User identity card (own or anyone else's). [avatarSeed] should be the hex
  /// pubkey so the avatar matches the user's glyph elsewhere in the app; it
  /// falls back to [npub] when omitted.
  factory UniunQrCard.user({
    required String npub,
    String? name,
    List<String> relays = const [],
    String? avatarSeed,
    String? avatarUrl,
  }) {
    return UniunQrCard._(
      entries: [
        _QrEntry(
          label: name ?? 'User',
          copyValue: npub,
          payload: UniunQrPayload(
            kind: UniunQrKind.user,
            id: npub,
            name: name,
            relays: relays,
          ),
          copyLabel: 'Copy npub',
          caption: (l10n) => l10n.qrCaptionUser,
          avatarSeed: avatarSeed ?? npub,
          avatarUrl: avatarUrl,
        ),
      ],
    );
  }

  /// Public group card.
  factory UniunQrCard.publicGroup({
    required String name,
    required String groupId,
    required List<String> relays,
  }) {
    return UniunQrCard._(
      entries: [
        _QrEntry(
          label: name,
          copyValue: groupId,
          payload: UniunQrPayload(
            kind: UniunQrKind.publicGroup,
            id: groupId,
            name: name,
            relays: relays,
          ),
          copyLabel: 'Copy group ID',
          caption: (l10n) => l10n.qrCaptionPublicGroup,
          iconLeading: const _PrimaryTintedIcon(icon: Icons.tag_rounded),
        ),
      ],
    );
  }

  /// Private group card.
  factory UniunQrCard.privateGroup({
    required String name,
    required String groupId,
    required List<String> relays,
  }) {
    return UniunQrCard._(
      entries: [
        _QrEntry(
          label: name,
          copyValue: groupId,
          payload: UniunQrPayload(
            kind: UniunQrKind.privateGroup,
            id: groupId,
            name: name,
            relays: relays,
          ),
          copyLabel: 'Copy group ID',
          caption: (l10n) => l10n.qrCaptionPrivateGroup,
          iconLeading: const _PrimaryTintedIcon(icon: Icons.lock_outline),
        ),
      ],
    );
  }

  /// DM-chat card with a "Their key | My key" toggle. Both branches encode
  /// a [UniunQrKind.user] payload. [conversationRelays] are the relays this DM
  /// is configured to use; they ride along in the QR so the scanner can
  /// auto-add them on the receiver's device. The `*Seed` args should be hex
  /// pubkeys so each side's avatar matches the app's; they fall back to the
  /// corresponding npub when omitted.
  factory UniunQrCard.dmConversation({
    required String partnerNpub,
    String? partnerName,
    String? partnerSeed,
    String? partnerAvatarUrl,
    required String myNpub,
    String? myName,
    String? mySeed,
    String? myAvatarUrl,
    List<String> conversationRelays = const [],
  }) {
    return UniunQrCard._(
      entries: [
        _QrEntry(
          label: partnerName ?? 'Their key',
          copyValue: partnerNpub,
          payload: UniunQrPayload(
            kind: UniunQrKind.user,
            id: partnerNpub,
            name: partnerName,
            relays: conversationRelays,
          ),
          copyLabel: 'Copy npub',
          caption: (l10n) => l10n.qrCaptionDm,
          tabLabel: 'Their key',
          avatarSeed: partnerSeed ?? partnerNpub,
          avatarUrl: partnerAvatarUrl,
        ),
        _QrEntry(
          label: myName ?? 'Your key',
          copyValue: myNpub,
          payload: UniunQrPayload(
            kind: UniunQrKind.user,
            id: myNpub,
            name: myName,
            relays: conversationRelays,
          ),
          copyLabel: 'Copy npub',
          caption: (l10n) => l10n.qrCaptionDm,
          tabLabel: 'My key',
          avatarSeed: mySeed ?? myNpub,
          avatarUrl: myAvatarUrl,
        ),
      ],
    );
  }

  @override
  // ignore: library_private_types_in_public_api
  State<UniunQrCard> createState() => _UniunQrCardState();
}

class _UniunQrCardState extends State<UniunQrCard> {
  int _selected = 0;

  /// Wraps the white QR box so it can be captured to a PNG for sharing. Only
  /// the selected entry's QR is in the tree at a time, so one key suffices.
  final GlobalKey _qrBoundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entry = widget.entries[_selected];
    final hasToggle = widget.entries.length > 1;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (hasToggle) ...[
                _ToggleHeader(
                  labels: [
                    for (final e in widget.entries) e.tabLabel ?? e.label,
                  ],
                  selectedIndex: _selected,
                  onChanged: (i) => setState(() => _selected = i),
                ),
                const SizedBox(height: 20),
              ],
              Center(child: _AvatarSlot(entry: entry)),
              const SizedBox(height: 12),
              Text(
                entry.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _IdRow(entry: entry, onCopy: () => _copy(entry)),
              const SizedBox(height: 20),
              Center(
                child: RepaintBoundary(
                  key: _qrBoundaryKey,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: QrImageView(
                      data: entry.payload.encode(),
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      // qr_flutter only offers square|circle; circular finders
                      // give the reference's "rounded" feel, square data
                      // modules keep the code crisp and scannable.
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.circle,
                        color: _kQrInk,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: _kQrInk,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                entry.caption(l10n),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _shareEntry(entry),
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(l10n.qrShareAction),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copy(_QrEntry entry) {
    // Always copy the FULL id — never the truncated display.
    Clipboard.setData(ClipboardData(text: entry.copyValue));
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.qrCopiedToClipboard(entry.copyLabel),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Captures the on-screen QR box as a PNG and opens the native share sheet
  /// with the image + the entity's deep link as text. Works for every card
  /// kind (user / public / private group / DM) via [_deepLinkFor].
  Future<void> _shareEntry(_QrEntry entry) async {
    // Anchor the iPad share popover to this card — read before any await.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    File? file;
    try {
      final boundary =
          _qrBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      // 2.0 keeps the QR crisp and scannable while rasterising ~4x fewer
      // pixels than 3.0.
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      // Fixed filename — overwritten each share, so temp files never pile up.
      file = await File(
        '${dir.path}/uniun_qr_share.png',
      ).writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: _deepLinkFor(entry.payload).toString(),
        sharePositionOrigin: origin,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.qrShareFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      // Best-effort cleanup once the share sheet has taken the bytes.
      try {
        if (file != null && await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  /// Maps a QR payload to its shareable `https://www.uniun.in/...` deep link.
  Uri _deepLinkFor(UniunQrPayload p) => switch (p.kind) {
    UniunQrKind.user => DeepLink.user(p.id, relays: p.relays),
    UniunQrKind.publicGroup => DeepLink.group(
      p.id,
      name: p.name,
      relays: p.relays,
    ),
    UniunQrKind.privateGroup => DeepLink.privateGroup(
      p.id,
      name: p.name,
      relays: p.relays,
    ),
    // The app only ever decodes a loginSession QR (rendered by the web
    // login page) — it never generates one to share, so this card is
    // never built for that kind.
    UniunQrKind.loginSession => throw UnsupportedError(
      'loginSession QR codes are not shareable',
    ),
  };
}

class _QrEntry {
  const _QrEntry({
    required this.label,
    required this.copyValue,
    required this.payload,
    required this.copyLabel,
    required this.caption,
    this.tabLabel,
    this.avatarSeed,
    this.avatarUrl,
    this.iconLeading,
  });

  /// Name shown under the avatar.
  final String label;

  /// FULL id (npub / group id / group id) — shown verbatim and copied.
  final String copyValue;
  final UniunQrPayload payload;
  final String copyLabel;

  /// Per-kind caption resolved against l10n at build time (factories have no
  /// [BuildContext]).
  final String Function(AppLocalizations l10n) caption;

  /// DM toggle label.
  final String? tabLabel;

  /// Avatar seed (hex pubkey) for person kinds; null for groups.
  final String? avatarSeed;
  final String? avatarUrl;

  /// Icon shown in the avatar slot for group kinds; null for person kinds.
  final Widget? iconLeading;
}

/// 56px header glyph: the user's avatar for person kinds, or a tinted rounded
/// square holding the group icon for group kinds.
class _AvatarSlot extends StatelessWidget {
  const _AvatarSlot({required this.entry});
  final _QrEntry entry;

  @override
  Widget build(BuildContext context) {
    final icon = entry.iconLeading;
    if (icon != null) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: icon,
      );
    }
    return UserAvatar(
      seed: entry.avatarSeed ?? entry.copyValue,
      photoUrl: entry.avatarUrl,
      size: 56,
    );
  }
}

/// The full id in mono text with a trailing inline copy button.
class _IdRow extends StatelessWidget {
  const _IdRow({required this.entry, required this.onCopy});
  final _QrEntry entry;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            entry.copyValue,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 2),
        IconButton(
          onPressed: onCopy,
          icon: Icon(
            Icons.copy_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: entry.copyLabel,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}

class _ToggleHeader extends StatelessWidget {
  const _ToggleHeader({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selectedIndex == i
                        ? Theme.of(context).colorScheme.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: selectedIndex == i
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selectedIndex == i
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: selectedIndex == i
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
