import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  String? _loadedNoteId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ManasMembershipSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noteId != widget.noteId) {
      setState(() {
        _loading = true;
        _included = <String>{};
      });
      _load();
    }
  }

  Future<void> _load() async {
    final currentNoteId = widget.noteId;
    final listRes = await _getList.call();
    final all = listRes.fold<List<ManasEntity>>((_) => const [], (l) => l);
    final memRes = await _getMemberships.call(currentNoteId);
    final included =
        memRes.fold<Set<String>>((_) => const <String>{}, (l) => l.toSet());
    if (!mounted || widget.noteId != currentNoteId) return;
    setState(() {
      _all = all;
      _included = included;
      _loading = false;
      _loadedNoteId = currentNoteId;
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.addToManas,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: DropLoadingIndicator()),
              )
            else if (_all.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    l10n.noManasYet,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _all.length,
                  itemBuilder: (context, index) {
                    final manas = _all[index];
                    final included = _included.contains(manas.manasId);
                    final iconData = ManasIcons.resolve(manas.iconName);

                    return CheckboxListTile(
                      value: included,
                      onChanged: (_) => _toggle(manas),
                      secondary: Icon(iconData, color: colorScheme.primary),
                      title: Text(
                        manas.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: manas.description.isNotEmpty
                          ? Text(
                              manas.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
