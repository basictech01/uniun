import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/composer/cubit/reference_picker_cubit.dart';
import 'package:uniun/common/widgets/composer/uniun_composer.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/common/widgets/markdown/strip_markdown.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/utils/formatters.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';

/// Full-screen picker for attaching note/message references to a composer.
///
/// Self-contained: queries the unified `Note` collection via
/// [ReferencePickerCubit] (recent + search), the saved-note table, the user's
/// own notes, and local drafts, with an All / Saved / My notes / Drafts filter.
/// Rows render thread-style (avatar + name·time + faded content). The page
/// maintains the working selection and returns the final
/// `List<ComposerReference>` via `Navigator.pop`.
class ReferencePickerPage extends StatelessWidget {
  const ReferencePickerPage({
    super.key,
    required this.title,
    required this.searchHint,
    required this.emptyLabel,
    this.initialSelected = const [],
  });

  final String title;
  final String searchHint;
  final String emptyLabel;
  final List<ComposerReference> initialSelected;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReferencePickerCubit>(),
      child: _ReferencePickerView(
        title: title,
        searchHint: searchHint,
        emptyLabel: emptyLabel,
        initialSelected: initialSelected,
      ),
    );
  }
}

class _ReferencePickerView extends StatefulWidget {
  const _ReferencePickerView({
    required this.title,
    required this.searchHint,
    required this.emptyLabel,
    required this.initialSelected,
  });

  final String title;
  final String searchHint;
  final String emptyLabel;
  final List<ComposerReference> initialSelected;

  @override
  State<_ReferencePickerView> createState() => _ReferencePickerViewState();
}

class _ReferencePickerViewState extends State<_ReferencePickerView> {
  final _searchController = TextEditingController();
  late final List<ComposerReference> _selected =
      List.of(widget.initialSelected);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(ComposerReference ref) {
    setState(() {
      final idx = _selected.indexWhere((r) => r.id == ref.id);
      if (idx >= 0) {
        _selected.removeAt(idx);
      } else {
        _selected.add(ref);
      }
    });
  }

  void _onTabChanged(ReferenceTab tab) {
    _searchController.clear();
    context.read<ReferencePickerCubit>().setTab(tab);
  }

  String _tabLabel(ReferenceTab tab, AppLocalizations l10n) {
    switch (tab) {
      case ReferenceTab.all:
        return l10n.composerReferenceTabAll;
      case ReferenceTab.saved:
        return l10n.composerReferenceTabSaved;
      case ReferenceTab.own:
        return l10n.composerReferenceTabOwn;
      case ReferenceTab.drafts:
        return l10n.composerReferenceTabDrafts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pickerState = context.watch<ReferencePickerCubit>().state;

    // Mono-blue source dots (matches the Brahma graph) — null for "All".
    final dots = <ReferenceTab, Color?>{
      ReferenceTab.all: null,
      ReferenceTab.saved: context.custom.graphNodeSaved,
      ReferenceTab.own: context.custom.graphNodeOwn,
      ReferenceTab.drafts: context.custom.graphNodeDraft,
    };

    // Enrich the held selection with profile/time metadata when the active tab
    // surfaces the same note, then show selected-first.
    final byId = {for (final r in pickerState.results) r.id: r};
    final rows = <ComposerReference>[
      ..._selected.map((s) => byId[s.id] ?? s),
      ...pickerState.results.where((r) => !_selected.any((s) => s.id == r.id)),
    ];
    final count = _selected.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _selected);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface),
            tooltip: l10n.actionBack,
            onPressed: () => Navigator.pop(context, _selected),
          ),
          title: Text(
            widget.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: UniunButton(
                expand: false,
                size: UniunButtonSize.compact,
                borderRadius: 999,
                label: count > 0
                    ? '${l10n.composerReferenceAdd} ($count)'
                    : l10n.composerReferenceAdd,
                onPressed: () => Navigator.pop(context, _selected),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: context.custom.borderSubtle),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (q) => context.read<ReferencePickerCubit>().search(q),
                style:
                    TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ReferenceTab.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final tab = ReferenceTab.values[i];
                    return _FilterChip(
                      label: _tabLabel(tab, l10n),
                      dot: dots[tab],
                      active: pickerState.tab == tab,
                      onTap: () => _onTabChanged(tab),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: pickerState.loading
                          ? DropLoadingIndicator(
                              color: Theme.of(context).colorScheme.primary)
                          : Text(
                              widget.emptyLabel,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 14),
                            ),
                    )
                  : ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (_, i) {
                        final ref = rows[i];
                        final isSelected =
                            _selected.any((s) => s.id == ref.id);
                        final pubkey = ref.authorPubkey;
                        return _ResultTile(
                          reference: ref,
                          profile: pubkey == null
                              ? null
                              : pickerState.profiles[pubkey],
                          isSelected: isSelected,
                          onTap: () => _toggle(ref),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.dot,
    required this.active,
    required this.onTap,
  });

  final String label;
  final Color? dot;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active ? Theme.of(context).colorScheme.onPrimary : dot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    active ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.reference,
    required this.profile,
    required this.isSelected,
    required this.onTap,
  });

  final ComposerReference reference;
  final ProfileEntity? profile;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pubkey = reference.authorPubkey;
    final fromProfile = profile?.name ?? profile?.username;
    final displayName = (fromProfile != null && fromProfile.trim().isNotEmpty)
        ? fromProfile
        : (pubkey != null && pubkey.isNotEmpty)
            ? formatShortPubkey(pubkey)
            : '';
    final seed = (pubkey != null && pubkey.isNotEmpty) ? pubkey : reference.id;
    final preview = stripMarkdownPreview(reference.label).trim();

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: context.custom.borderSubtle),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(
              seed: seed,
              photoUrl: profile?.avatarUrl,
              size: 38,
              borderRadius: 19,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (displayName.isNotEmpty)
                        Flexible(
                          child: Text(
                            displayName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (displayName.isNotEmpty && reference.created != null)
                        const SizedBox(width: 6),
                      if (reference.created != null)
                        Text(
                          '· ${formatTimeAgo(reference.created!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.custom.textMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preview.isEmpty ? '…' : preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  border: isSelected
                      ? null
                      : Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 2),
                ),
                child: isSelected
                    ? Icon(Icons.check_rounded,
                        size: 16, color: Theme.of(context).colorScheme.onPrimary)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
