import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/domain/entities/manas/manas_entity.dart';
import 'package:uniun/domain/usecases/manas_usecases.dart';
import 'package:uniun/features/brahma/utils/manas_icons.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Bottom sheet that lets the user toggle the given note's membership
/// across all Manases. Membership writes are immediate (idempotent
/// add/remove); no explicit "Save" — closing the sheet is enough.
///
/// `show()` is fire-and-forget for the caller — the sheet handles its own
/// load/error/empty states.
class ManasMembershipSheet extends StatefulWidget {
  const ManasMembershipSheet({super.key, required this.noteId});

  final String noteId;

  static Future<void> show(BuildContext context, String noteId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ManasMembershipSheet(noteId: noteId),
    );
  }

  @override
  State<ManasMembershipSheet> createState() => _ManasMembershipSheetState();
}

class _ManasMembershipSheetState extends State<ManasMembershipSheet> {
  final _getList = getIt<GetManasListUseCase>();
  final _getMemberships = getIt<GetManasIdsForNoteUseCase>();
  final _add = getIt<AddNoteToManasUseCase>();
  final _remove = getIt<RemoveNoteFromManasUseCase>();

  bool _loading = true;
  List<ManasEntity> _all = const [];
  Set<String> _included = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final listRes = await _getList.call();
    final all = listRes.fold<List<ManasEntity>>((_) => const [], (l) => l);
    final memRes = await _getMemberships.call(widget.noteId);
    final included =
        memRes.fold<Set<String>>((_) => const <String>{}, (l) => l.toSet());
    if (!mounted) return;
    setState(() {
      _all = all;
      _included = included;
      _loading = false;
    });
  }

  Future<void> _toggle(ManasEntity manas) async {
    final wasIn = _included.contains(manas.manasId);
    setState(() {
      if (wasIn) {
        _included = {..._included}..remove(manas.manasId);
      } else {
        _included = {..._included, manas.manasId};
      }
    });
    final link = ManasNoteLink(manas.manasId, widget.noteId);
    if (wasIn) {
      await _remove.call(link);
    } else {
      await _add.call(link);
    }
    // Refresh the cached Manas list so each row's "N notes" subtitle reflects
    // the membership change immediately (without close/reopen).
    if (!mounted) return;
    final listRes = await _getList.call();
    final fresh =
        listRes.fold<List<ManasEntity>>((_) => _all, (l) => l);
    if (!mounted) return;
    setState(() => _all = fresh);
  }

  Future<void> _openCreateForm() async {
    final saved = await context.pushNamed<bool>(AppRoutes.brahmaManasForm);
    if (saved == true && mounted) {
      setState(() => _loading = true);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.man_3_rounded,
                        color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.manasMembershipSheetTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _loading
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: DropLoadingIndicator(
                              size: 22,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      )
                    : _all.isEmpty
                        ? _Empty(onCreate: _openCreateForm)
                        : ListView.builder(
                            shrinkWrap: true,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _all.length,
                            itemBuilder: (_, i) {
                              final m = _all[i];
                              final included =
                                  _included.contains(m.manasId);
                              return _Row(
                                manas: m,
                                included: included,
                                onTap: () => _toggle(m),
                              );
                            },
                          ),
              ),
              if (!_loading && _all.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: TextButton.icon(
                    onPressed: _openCreateForm,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.manasMembershipSheetCreate),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.manas,
    required this.included,
    required this.onTap,
  });

  final ManasEntity manas;
  final bool included;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: included
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                    : Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                ManasIcons.byName(manas.iconName),
                size: 18,
                color: included
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manas.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: included
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    manas.noteCount == 0
                        ? l10n.manasTileEmptyHint
                        : l10n.manasDrawerTileNoteCount(manas.noteCount),
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              included
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: included ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.manasMembershipSheetEmptyTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.manasMembershipSheetEmptyBody,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          UniunButton(
            expand: false,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: l10n.manasMembershipSheetEmptyCta,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}
