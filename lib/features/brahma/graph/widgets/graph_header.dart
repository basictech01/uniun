import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uniun/features/brahma/graph/bloc/graph_bloc.dart';
import 'package:uniun/features/brahma/graph/models/graph_node_type.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_stepper.dart';
import 'package:uniun/features/brahma/utils/brahma_scaffold_key.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';

// Mono-blue knowledge-graph palette (DESIGN.md §1.1) — one hue, sources by
// shade. Function (not const map) so both themes resolve at build time.
Map<GraphNodeType, Color> graphNodeTypeColorsOf(BuildContext context) => {
      GraphNodeType.saved: context.custom.graphNodeSaved,
      GraphNodeType.own: context.custom.graphNodeOwn,
      GraphNodeType.draft: context.custom.graphNodeDraft,
    };

/// Brahma graph app bar: a solid `logo · Brahma · search` header. The Brahma
/// logo opens the Manas drawer (where scope is changed); the search icon
/// reveals an inline field that highlights matching nodes (via
/// [SearchGraphEvent]).
class GraphHeader extends StatefulWidget {
  const GraphHeader({super.key});

  @override
  State<GraphHeader> createState() => _GraphHeaderState();
}

class _GraphHeaderState extends State<GraphHeader> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() => setState(() => _searchOpen = true);

  void _closeSearch() {
    _searchController.clear();
    context.read<GraphBloc>().add(const SearchGraphEvent(''));
    setState(() => _searchOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: context.custom.borderSubtle)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── App bar: menu · Brahma / search · search-toggle ──────────────
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/images/tabs/brahma.svg',
                      width: 32,
                      height: 32,
                      theme: SvgTheme(
                        currentColor: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    tooltip: l10n.graphMenuTooltip,
                    onPressed: () =>
                        brahmaScaffoldKey.currentState?.openDrawer(),
                  ),
                  Expanded(
                    child: _searchOpen
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            textInputAction: TextInputAction.search,
                            onChanged: (v) => context
                                .read<GraphBloc>()
                                .add(SearchGraphEvent(v)),
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: false,
                              border: InputBorder.none,
                              hintText: l10n.graphSearchHint,
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: context.custom.textMuted,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (_searchOpen) const _SearchMatchStepper(),
                  IconButton(
                    icon: Icon(
                      _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                    ),
                    color: Theme.of(context).colorScheme.onSurface,
                    tooltip: _searchOpen
                        ? l10n.graphSearchClear
                        : l10n.graphSearchTooltip,
                    onPressed: _searchOpen ? _closeSearch : _openSearch,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The header's [GraphStepper]: walks the search matches. Hidden until the
/// query matches something; `0/7` means the matches are lit but the camera has
/// not moved to any of them yet.
class _SearchMatchStepper extends StatelessWidget {
  const _SearchMatchStepper();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<GraphBloc, GraphState>(
      buildWhen: (prev, curr) =>
          prev.matchOrder.length != curr.matchOrder.length ||
          prev.matchIndex != curr.matchIndex,
      builder: (context, state) {
        final total = state.matchOrder.length;
        if (total == 0) return const SizedBox.shrink();
        return GraphStepper(
          current: state.matchIndex + 1,
          total: total,
          positionLabel:
              l10n.graphStepPosition(state.matchIndex + 1, total),
          prevTooltip: l10n.graphSearchPrevMatch,
          nextTooltip: l10n.graphSearchNextMatch,
          onStep: (delta) =>
              context.read<GraphBloc>().add(StepGraphMatchEvent(delta)),
        );
      },
    );
  }
}

/// Source-shade legend — a design-system glass pill (DESIGN.md §2.2) overlaid
/// on the graph canvas. Nodes are always coloured by type, so it is fixed
/// regardless of Manas scope.
class GraphLegend extends StatelessWidget {
  const GraphLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = graphNodeTypeColorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.custom.glassFill,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: context.custom.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(
              color: palette[GraphNodeType.saved]!,
              label: l10n.graphLegendSaved),
          const SizedBox(width: 12),
          _LegendDot(
              color: palette[GraphNodeType.own]!,
              label: l10n.graphLegendOwn),
          const SizedBox(width: 12),
          _LegendDot(
              color: palette[GraphNodeType.draft]!,
              label: l10n.graphLegendDraft),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
