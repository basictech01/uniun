import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/features/brahma/bloc/brahma_create_bloc.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/common/widgets/floating_nav.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/features/brahma/graph/bloc/graph_bloc.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_canvas.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_fab.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_header.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_node_panel.dart';
import 'package:uniun/features/brahma/utils/brahma_scaffold_key.dart';
import 'package:uniun/features/brahma/utils/publish_chain_dialog.dart';
import 'package:uniun/features/brahma/manas/widgets/brahma_drawer.dart';
import 'package:uniun/l10n/app_localizations.dart';

class GraphPage extends StatelessWidget {
  const GraphPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<GraphBloc>()..add(const LoadGraphEvent()),
        ),
        BlocProvider(
          create: (_) =>
              getIt<BrahmaCreateBloc>()..add(const LoadDraftsEvent()),
        ),
      ],
      child: const _GraphView(),
    );
  }
}

class _GraphView extends StatefulWidget {
  const _GraphView();

  @override
  State<_GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<_GraphView> {
  bool _isGraphInteracting = false;
  bool _hasSelectedNode = false;

  bool get _navVisible => !_isGraphInteracting && !_hasSelectedNode;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BrahmaCreateBloc, BrahmaCreateState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, state) {
            final l10n = AppLocalizations.of(context)!;
            if (state.status == BrahmaCreateStatus.success) {
              // Draft published — confirm and refresh so the draft drops out of
              // the graph (which closes the node panel with it). Stay on the
              // graph rather than jumping back to Vishnu.
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l10n.brahmaDraftPublished),
                behavior: SnackBarBehavior.floating,
              ));
              final graph = context.read<GraphBloc>();
              graph.add(LoadGraphEvent(
                manasId: graph.state.scopedManasId,
                manasName: graph.state.scopedManasName,
              ));
            } else if (state.status == BrahmaCreateStatus.error &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ));
            }
          },
        ),
        BlocListener<GraphBloc, GraphState>(
          listenWhen: (prev, curr) =>
              (prev.selectedNode == null) != (curr.selectedNode == null),
          listener: (context, state) {
            final has = state.selectedNode != null;
            if (_hasSelectedNode != has) setState(() => _hasSelectedNode = has);
          },
        ),
      ],
      child: Scaffold(
        key: brahmaScaffoldKey,
        backgroundColor: Theme.of(context).colorScheme.surface,
        drawer: BlocBuilder<GraphBloc, GraphState>(
          buildWhen: (prev, curr) => prev.scopedManasId != curr.scopedManasId,
          builder: (context, state) =>
              BrahmaDrawer(activeManasId: state.scopedManasId),
        ),
        // Any tap no child claims puts the search keyboard away — the
        // package's own dismisser, as used elsewhere in the app.
        body: KeyboardDismissOnTap(
          child: Stack(
            children: [
              // Positioned.fill gives _GraphBody tight constraints so GraphCanvas
              // LayoutBuilder gets the full screen size (without this, the inner
              // Stack with only Positioned children would have zero size).
              Positioned.fill(
                child: _GraphBody(
                  onInteractingChanged: (v) {
                    if (_isGraphInteracting != v) {
                      setState(() => _isGraphInteracting = v);
                    }
                  },
                ),
              ),

              // FloatingNav — hides while the graph is being touched, the node
              // panel is open, or the search keyboard is up (it would sit on
              // top of the keyboard otherwise, as it does on Shiv).
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: KeyboardVisibilityBuilder(
                  builder: (context, isKeyboardVisible) => AnimatedSlide(
                    offset: (_navVisible && !isKeyboardVisible)
                        ? Offset.zero
                        : const Offset(0, 1.5),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    child: FloatingNav(
                      currentIndex: 1,
                      onTap: (i) async {
                        // Tap on the Brahma icon while already on Brahma →
                        // open the side drawer. Edge-swipe also works.
                        if (i == 1) {
                          brahmaScaffoldKey.currentState?.openDrawer();
                          return;
                        }
                        Navigator.pop(context, i);
                      },
                    ),
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

// ── Graph body ─────────────────────────────────────────────────────────────────

class _GraphBody extends StatelessWidget {
  const _GraphBody({required this.onInteractingChanged});
  final ValueChanged<bool> onInteractingChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GraphBloc, GraphState>(
      builder: (context, state) {
        if (state.status == GraphStatus.initial ||
            state.status == GraphStatus.loading) {
          return Column(
            children: [
              GraphHeader(),
              Expanded(
                child: Center(
                  child: DropLoadingIndicator(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          );
        }

        if (state.status == GraphStatus.error) {
          return Column(
            children: [
              const GraphHeader(),
              Expanded(
                child: Center(
                  child: Text(
                    state.errorMessage ?? 'Failed to load graph',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
            ],
          );
        }

        // Solid app bar on top (DESIGN.md §3.3) pushes the canvas down; the
        // legend overlays the canvas top-left, the node panel + FAB anchor to
        // the screen bottom.
        return Column(
          children: [
            const GraphHeader(),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GraphCanvas(
                      nodes: state.nodes,
                      adjacency: state.adjacency,
                      selectedNodeId: state.selectedNodeId,
                      isSearching: state.isSearching,
                      matchedNodeIds: state.matchedNodeIds,
                      focusedNodeId: state.focusedNodeId,
                      onNodeTap: (id) => context
                          .read<GraphBloc>()
                          .add(SelectGraphNodeEvent(id)),
                      onCanvasTap: () {
                        // The canvas claims its own taps, so the page-level
                        // KeyboardDismissOnTap never sees them — put the
                        // search keyboard away here instead.
                        FocusScope.of(context).unfocus();
                        context
                            .read<GraphBloc>()
                            .add(const DeselectGraphNodeEvent());
                      },
                      onInteractingChanged: onInteractingChanged,
                    ),
                  ),

                  const Positioned(top: 12, left: 12, child: GraphLegend()),

                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: _NodePanelSlider(state: state),
                  ),

                  if (state.selectedNode == null)
                    Positioned(
                      // Clear the floating nav, whose height grows by the
                      // home-indicator safe area — add that inset so the FAB
                      // doesn't touch the nav on devices with a home indicator.
                      right: 20,
                      bottom: 96 + MediaQuery.of(context).padding.bottom,
                      child: const GraphFab(),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Animated panel wrapper ─────────────────────────────────────────────────────
class _NodePanelSlider extends StatelessWidget {
  const _NodePanelSlider({required this.state});
  final GraphState state;

  @override
  Widget build(BuildContext context) {
    final node = state.selectedNode;
    return AnimatedSlide(
      offset: node != null ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: IgnorePointer(
        ignoring: node == null,
        child: node != null
            ? GraphNodePanel(
                node: node,
                profile: node.authorPubkey != null
                    ? state.profiles[node.authorPubkey]
                    : null,
                onClose: () => context
                    .read<GraphBloc>()
                    .add(const DeselectGraphNodeEvent()),
                onEditTap: (draftId) async {
                  final bloc = context.read<GraphBloc>();
                  await context.pushNamed(
                    AppRoutes.brahmaCreate,
                    extra: {'draftId': draftId, 'autoPublish': false},
                  );
                  // A bare LoadGraphEvent() means "unscope" (manasId == null
                  // ⇒ clearScope), so the active Manas has to ride along.
                  bloc.add(LoadGraphEvent(
                    manasId: bloc.state.scopedManasId,
                    manasName: bloc.state.scopedManasName,
                  ));
                  bloc.add(SelectGraphNodeEvent(draftId));
                },
                onPublishTap: (draftId) async {
                  // If this draft links to other unpublished drafts, ask
                  // first — refs to UUIDs can't ride into the published
                  // Kind-1's `e` tags unless we chain-publish them now.
                  var chain = false;
                  if (node.draftRefIds.isNotEmpty) {
                    final choice = await showPublishChainSheet(
                      context,
                      draftCount: node.draftRefIds.length,
                    );
                    if (choice == PublishChainChoice.cancel) return;
                    chain = choice == PublishChainChoice.chain;
                  }
                  if (!context.mounted) return;
                  // BlocListener<BrahmaCreateBloc> in GraphPage handles
                  // popping to home on success.
                  context.read<BrahmaCreateBloc>().add(
                        PublishDraftEvent(
                          draftId: draftId,
                          content: node.content,
                          publishChain: chain,
                        ),
                      );
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
