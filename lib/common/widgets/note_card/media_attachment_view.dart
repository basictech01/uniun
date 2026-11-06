import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/snackbar.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/common/widgets/media/file_type_style.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/domain/entities/media/media_blob_entity.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/usecases/media_usecases.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Renders the NIP-92 `imeta` attachments on a [NoteEntity]. Attachments
/// are pre-resolved by `NoteAttachmentsEnricher`; this widget never reads
/// Isar. Each tile owns its own download state so one blob arriving doesn't
/// re-render the feed.
///
/// [compact] caps image height tight for feeds / DMs / quotes; false gives
/// the thread parent more room.
class MediaAttachmentView extends StatelessWidget {
  /// Render from a [NoteEntity] (feed / DM / group cards have an enriched
  /// note in hand).
  const MediaAttachmentView({
    super.key,
    required NoteEntity note,
    this.compact = true,
  }) : _attachments = null,
       _note = note;

  /// Render from a raw blob list — used by surfaces that carry attachments
  /// outside a [NoteEntity] (Brahma graph panel, composers, previews).
  const MediaAttachmentView.fromBlobs({
    super.key,
    required List<MediaBlobEntity> attachments,
    this.compact = true,
  }) : _attachments = attachments,
       _note = null;

  final NoteEntity? _note;
  final List<MediaBlobEntity>? _attachments;
  final bool compact;

  List<MediaBlobEntity> get _blobs =>
      _attachments ?? _note?.attachments ?? const [];

  @override
  Widget build(BuildContext context) {
    final blobs = _blobs;
    if (blobs.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final b in blobs) ...[
            _AttachmentTile(
              key: ValueKey(b.sha256),
              initial: b,
              compact: compact,
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatefulWidget {
  const _AttachmentTile({
    super.key,
    required this.initial,
    required this.compact,
  });
  final MediaBlobEntity initial;
  final bool compact;

  @override
  State<_AttachmentTile> createState() => _AttachmentTileState();
}

class _AttachmentTileState extends State<_AttachmentTile> {
  late MediaBlobEntity _blob = widget.initial;
  bool _downloading = false;

  /// Compact: feed / DM / quote card. Expanded: thread parent.
  /// Excess height is cropped via `BoxFit.cover`; full aspect lives on the
  /// detail page.
  static const double _compactMaxHeight = 200.0;
  static const double _expandedMaxHeight = 360.0;

  bool get _cached => _blob.localPath != null;
  bool get _isImage => _blob.mime.startsWith('image/');
  bool get _isVideo => _blob.mime.startsWith('video/');

  /// Visual media (image or video) renders as a preview tile with a blurhash
  /// placeholder until downloaded; everything else uses the file-row card.
  bool get _isVisual => _isImage || _isVideo;

  Future<void> _download() async {
    if (_blob.serverUrls.isEmpty) return;
    setState(() => _downloading = true);
    final res = await getIt<DownloadMediaUseCase>().call(DownloadMediaInput(
      sha256: _blob.sha256,
      url: _blob.serverUrls.first,
      mime: _blob.mime,
    ));
    if (!mounted) return;
    setState(() {
      _downloading = false;
      res.fold((_) {}, (newBlob) => _blob = newBlob);
    });
    res.fold(
      (f) => AppSnackbar.error(context, f.toMessage()),
      (_) {},
    );
  }

  /// Image → detail page. Everything else → download if needed, then hand
  /// the local file to the OS via `OpenFilex`.
  Future<void> _onTap() async {
    if (_isImage) {
      context.pushNamed(
        AppRoutes.mediaDetail,
        pathParameters: {'sha256': _blob.sha256},
      );
      return;
    }
    if (!_cached) {
      await _download();
      if (!mounted) return;
    }
    final path = _blob.localPath;
    if (path == null) return;
    await OpenFilex.open(path);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisual) {
      return _FileCard(blob: _blob, busy: _downloading, onTap: _onTap);
    }

    final l10n = AppLocalizations.of(context)!;
    final maxH = widget.compact ? _compactMaxHeight : _expandedMaxHeight;

    return GestureDetector(
      onTap: _onTap,
      child: LayoutBuilder(
        builder: (context, c) {
          final width = c.maxWidth;
          final aspect = _blob.dim == null
              ? 16 / 9
              : _blob.dim!.width / _blob.dim!.height;
          // Natural height for full-width display, then clamp so portraits
          // don't push the rest of the card off-screen.
          final naturalH = width / aspect;
          final height = naturalH.clamp(0.0, maxH);

          return SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _background(),
                  if (_isVideo)
                    _videoOverlay()
                  else if (!_cached)
                    _downloadOverlay(l10n),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _downloadOverlay(AppLocalizations l10n) {
    return Container(
      color: Colors.black.withValues(alpha: 0.25),
      alignment: Alignment.center,
      child: _downloading
          ? const SizedBox(
              width: 32,
              height: 32,
              child: DropLoadingIndicator(size: 32),
            )
          : UniunButton(
            expand: false,
            size: UniunButtonSize.compact,
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).colorScheme.primary,
            borderRadius: 999,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            icon: const Icon(Icons.cloud_download_outlined, size: 18),
            label: l10n.noteCardDownloadMedia,
            onPressed: _download,
          ),
    );
  }

  Widget _background() {
    if (_cached && _isImage) {
      return Image.file(
        File(_blob.localPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    // Non-downloaded image, or a video (which has no inline player) — show the
    // blurhash placeholder when we have one, else a type icon.
    if (_blob.blurhash != null) {
      return BlurHash(hash: _blob.blurhash!);
    }
    return _placeholder();
  }

  /// Centered play affordance over a video tile (the blurhash shows behind).
  /// Tapping the tile downloads if needed, then hands off to the OS player.
  Widget _videoOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.25),
      alignment: Alignment.center,
      child: _downloading
          ? const SizedBox(
              width: 32,
              height: 32,
              child: DropLoadingIndicator(size: 32),
            )
          : const Icon(Icons.play_circle_outline,
              size: 48, color: Colors.white),
    );
  }

  Widget _placeholder() {
    final icon = _blob.mime.startsWith('video/')
        ? Icons.movie_outlined
        : _blob.mime.startsWith('audio/')
            ? Icons.audiotrack_outlined
            : Icons.insert_drive_file_outlined;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
    );
  }
}

/// Horizontal card for non-image attachments: type chip, filename + meta,
/// trailing download/open icon. Tap → download (if needed) then OS handoff.
class _FileCard extends StatelessWidget {
  const _FileCard({required this.blob, required this.busy, required this.onTap});

  final MediaBlobEntity blob;
  final bool busy;
  final VoidCallback onTap;

  bool get _cached => blob.localPath != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final style = FileTypeStyle.fromMime(blob.mime, blob.filename);
    final title = (blob.filename != null && blob.filename!.trim().isNotEmpty)
        ? blob.filename!
        : l10n.noteCardFileFallbackName;
    final subtitle = _buildSubtitle(l10n, style);

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _typeChip(context, style),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _trailing(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(BuildContext context, FileTypeStyle style) {
    final c = style.colorFor(context);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(style.icon, color: c, size: 22),
          const SizedBox(height: 2),
          Text(
            style.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: c,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trailing(ColorScheme colorScheme) {
    if (busy) {
      return SizedBox(
        width: 20,
        height: 20,
        child: DropLoadingIndicator(
          size: 20,
          color: colorScheme.primary,
        ),
      );
    }
    return Icon(
      _cached ? Icons.open_in_new_rounded : Icons.cloud_download_outlined,
      size: 20,
      color: colorScheme.onSurfaceVariant,
    );
  }

  String _buildSubtitle(AppLocalizations l10n, FileTypeStyle style) {
    final parts = <String>[style.readableType];
    if (blob.sizeBytes > 0) parts.add(_humanBytes(blob.sizeBytes));
    parts.add(_cached ? l10n.noteCardFileTapToOpen : l10n.noteCardFileTapToDownload);
    return parts.join(' · ');
  }

  static String _humanBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }
}

