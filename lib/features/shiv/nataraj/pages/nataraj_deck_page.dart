import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uniun/common/atoms/uniun_button.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/domain/entities/llm/llm_task_kind.dart';
import 'package:uniun/domain/usecases/app_settings_usecases.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/domain/usecases/scheduler_usecases.dart';
import 'package:uniun/domain/entities/manas/manas_entity.dart';
import 'package:uniun/features/brahma/utils/manas_icons.dart';
import 'package:uniun/features/shiv/chat/bloc/shiv_ai_bloc.dart';
import 'package:uniun/features/shiv/chat/pages/shiv_chat_page.dart';
import 'package:uniun/features/shiv/nataraj/bloc/nataraj_bloc.dart';
import 'package:uniun/features/shiv/nataraj/widgets/nataraj_card_widget.dart';
import 'package:uniun/features/shiv/nataraj/widgets/nataraj_coach_overlay.dart';
import 'package:uniun/features/shiv/nataraj/widgets/nataraj_edge_labels.dart';
import 'package:uniun/features/shiv/nataraj/widgets/nataraj_drawer.dart';
import 'package:uniun/features/shiv/nataraj/widgets/nataraj_empty_state.dart';
import 'package:uniun/features/shiv/nataraj/widgets/nataraj_scope_sheet.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/core/theme/app_custom_colors.dart';

/// The Nataraj swipe-deck screen — Shiv tab's home in Task 15.
///
/// Provides its own [NatarajBloc] and dispatches [NatarajEvent.loadDeck] on
/// mount. Model gate: if no LLM is installed, redirects to AI model selection.
///
/// Header: back (left) + title + Manas selector (right).
/// Body: switches on [NatarajStatus]:
///   - loading   → spinner + [l10n.natarajGenerating]
///   - ready     → swipe deck (card + edge labels + buttons + coach overlay)
///   - needsMoreNotes / exhausted → [NatarajEmptyState]
///   - error     → retry button
///
/// Seed-chat: BlocListener on [state.seedChatParagraph] fires
/// [ShivAIEvent.createConversationSeeded] on the ambient [ShivAIBloc] (or
/// falls back to getIt when no ambient bloc is available).
class NatarajDeckPage extends StatelessWidget {
  const NatarajDeckPage({
    super.key,
    this.manasIds = const [],
    this.onDrawerChanged,
  });

  /// Optional initial scope filter (list of manas IDs).
  final List<String> manasIds;

  /// Called when the [NatarajDrawer] opens or closes. Wire this to
  /// [ShivPage]'s [_onDrawerChanged] so [FloatingNav] hides while the drawer
  /// is open — same pattern as [ShivChatPage.onDrawerChanged].
  final ValueChanged<bool>? onDrawerChanged;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NatarajBloc>()
        ..add(NatarajEvent.loadDeck(manasIds)),
      child: _NatarajDeckView(
        initialManasIds: manasIds,
        onDrawerChanged: onDrawerChanged,
      ),
    );
  }
}

// ── Inner stateful widget (model gate + coach dismiss) ────────────────────────

class _NatarajDeckView extends StatefulWidget {
  const _NatarajDeckView({
    required this.initialManasIds,
    this.onDrawerChanged,
  });
  final List<String> initialManasIds;
  final ValueChanged<bool>? onDrawerChanged;

  @override
  State<_NatarajDeckView> createState() => _NatarajDeckViewState();
}

class _NatarajDeckViewState extends State<_NatarajDeckView> {
  /// Local flag to suppress the coach overlay independently of bloc state
  /// (so dismissing it survives without a dedicated bloc event).
  bool _coachDismissed = false;

  /// Lets the fallback action buttons trigger the card's fly-off animation
  /// instead of advancing the deck instantly. Lives here (not in the rebuilt
  /// [_DeckBody]) so it survives bloc emissions and stays bound to the card.
  final NatarajCardController _cardController = NatarajCardController();

  @override
  void initState() {
    super.initState();
    _loadCoachSeen();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkModel());
    // Hoist Nataraj jobs to T1 while this page is open — see
    // docs/SHIVA/scheduling.md §3 (foreground rule).
    getIt<SetForegroundKindUseCase>().call(LlmTaskKind.nataraj);
  }

  @override
  void dispose() {
    getIt<SetForegroundKindUseCase>().call(null);
    super.dispose();
  }

  /// Seed the coach gate from the persisted once-ever flag (via the settings
  /// repository) so it never reappears after dismissal, across app restarts.
  Future<void> _loadCoachSeen() async {
    final seen = (await getIt<GetNatarajCoachSeenUseCase>().call())
        .fold((_) => false, (v) => v);
    if (mounted && seen) setState(() => _coachDismissed = true);
  }

  Future<void> _checkModel() async {
    if (!mounted) return;
    final hasModel = await getIt<HasActiveLlmModelUseCase>().call();
    if (!mounted) return;
    if (!hasModel) {
      context.pushReplacementNamed(AppRoutes.aiModelSelection);
    }
  }

  /// Fires [ShivAIEvent.createConversationSeeded] on the ambient [ShivAIBloc]
  /// when available, or obtains one from getIt and pushes the chat page with
  /// a fresh BlocProvider in the standalone (non-Shiv-tab) case.
  void _openSeededChat(BuildContext context, String paragraph) {
    ShivAIBloc? ambientBloc;
    try {
      ambientBloc = context.read<ShivAIBloc>();
    } catch (_) {
      ambientBloc = null;
    }

    if (ambientBloc != null) {
      // In-Shiv case (Task 15): the ambient bloc drives the tab UI, so
      // just fire the event — ShivPage's BlocBuilder switches to ShivChatPage.
      ambientBloc.add(
        ShivAIEvent.createConversationSeeded(paragraph),
      );
    } else {
      // Standalone / Brahma-deep-link case: no ambient ShivAIBloc.
      // Spin up a fresh one from getIt and push the chat page with it.
      final freshBloc = getIt<ShivAIBloc>()
        ..add(ShivAIEvent.createConversationSeeded(paragraph));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BlocProvider<ShivAIBloc>.value(
            value: freshBloc,
            child: ShivChatPage(onDrawerChanged: (_) {}),
          ),
        ),
      );
    }
  }

  /// Leaves the Nataraj deck (a pushed route) and returns to the Shiv home.
  void _onBack(BuildContext context) {
    if (context.canPop()) context.pop();
  }

  /// Opens the Manas scope selector as a bottom sheet and, on pick, dispatches
  /// [NatarajEvent.changeScope] on the deck's [NatarajBloc] — the same event
  /// the drawer's scope list fires. Reads the Manas options + current scope
  /// straight off the bloc state.
  void _onPickManas(BuildContext context) {
    final bloc = context.read<NatarajBloc>();
    final state = bloc.state;
    showNatarajScopeSheet(
      context,
      options: state.manasOptions,
      selectedIds: state.manasIds,
      onSelect: (ids) => bloc.add(NatarajEvent.changeScope(ids)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final top = MediaQuery.of(context).padding.top;

    return BlocListener<NatarajBloc, NatarajState>(
      listenWhen: (prev, curr) =>
          curr.seedChatParagraph != null &&
          curr.seedChatParagraph != prev.seedChatParagraph,
      listener: (context, state) {
        final paragraph = state.seedChatParagraph;
        if (paragraph != null) {
          _openSeededChat(context, paragraph);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        drawer: const NatarajDrawer(),
        onDrawerChanged: widget.onDrawerChanged,
        body: Builder(
          builder: (ctx) => Column(
            children: [
              // ── Header ─────────────────────────────────────────────────────
              _NatarajHeader(
                top: top,
                onBack: () => _onBack(ctx),
                onPickManas: () => _onPickManas(ctx),
              ),

              // ── Revisiting banner ───────────────────────────────────────────
              BlocSelector<NatarajBloc, NatarajState, bool>(
                selector: (s) => s.resurfacing,
                builder: (_, resurfacing) {
                  if (!resurfacing) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color:
                        Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.45),
                    child: Text(
                      l10n.natarajRevisitingHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),

              // ── Body ────────────────────────────────────────────────────────
              Expanded(
                child: BlocConsumer<NatarajBloc, NatarajState>(
                  listenWhen: (prev, curr) =>
                      prev.status != curr.status,
                  listener: (context, state) {
                    if (state.status == NatarajStatus.error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.natarajGenerateErrorSnack),
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    return switch (state.status) {
                      NatarajStatus.loading =>
                        _LoadingBody(label: l10n.natarajGenerating),
                      // Defense-in-depth: `ready` should always carry a card,
                      // but if a transient emit leaves it null, show loading
                      // rather than crash on `currentCard!` in _DeckBody.
                      NatarajStatus.ready => state.currentCard == null
                          ? _LoadingBody(label: l10n.natarajGenerating)
                          : _DeckBody(
                              state: state,
                              cardController: _cardController,
                              coachDismissed: _coachDismissed,
                              onCoachDismiss: () {
                                getIt<SetNatarajCoachSeenUseCase>().call(true);
                                setState(() => _coachDismissed = true);
                              },
                            ),
                      NatarajStatus.needsMoreNotes ||
                      NatarajStatus.exhausted =>
                        NatarajEmptyState(
                          status: state.status,
                          onAddNotes: () {
                            context.pushNamed(AppRoutes.graph);
                          },
                        ),
                      NatarajStatus.error => _ErrorBody(
                          onRetry: () => context
                              .read<NatarajBloc>()
                              .add(NatarajEvent.loadDeck(state.manasIds)),
                          onChangeModel: () =>
                              context.pushNamed(AppRoutes.aiModelSelection),
                        ),
                      NatarajStatus.noIdea => _NoIdeaBody(
                          onRetry: () => context
                              .read<NatarajBloc>()
                              .add(NatarajEvent.loadDeck(state.manasIds)),
                        ),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// ── Header ────────────────────────────────────────────────────────────────────

class _NatarajHeader extends StatelessWidget {
  const _NatarajHeader({
    required this.top,
    required this.onBack,
    required this.onPickManas,
  });

  final double top;
  final VoidCallback onBack;
  final VoidCallback onPickManas;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(
        left: 4,
        right: 12,
        top: top + 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back — leaves the Nataraj deck (pushed route).
          IconButton(
            onPressed: onBack,
            tooltip: l10n.actionBack,
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 24,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          // Manas selector — opens the scope sheet.
          _ManasSelectorButton(onTap: onPickManas),
        ],
      ),
    );
  }
}

/// Header pill reflecting the current Nataraj scope and opening the Manas
/// selector. Reads `manasIds` + `manasOptions` from the ambient [NatarajBloc]
/// to render the active scope's icon + label.
class _ManasSelectorButton extends StatelessWidget {
  const _ManasSelectorButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocSelector<NatarajBloc, NatarajState,
        (List<String>, List<ManasEntity>)>(
      selector: (s) => (s.manasIds, s.manasOptions),
      builder: (context, data) {
        final ids = data.$1;
        final options = data.$2;

        IconData icon = kNatarajAllNotesIcon;
        String label = l10n.natarajScopeAllNotes;
        if (ids.isNotEmpty) {
          final selected = options.where((m) => ids.contains(m.manasId));
          if (selected.isNotEmpty) {
            icon = ManasIcons.byName(selected.first.iconName);
            label = ids.length == 1
                ? selected.first.name
                : l10n.natarajScopeManasCount(ids.length);
          }
        }

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 168),
            padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Loading body ──────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DropLoadingIndicator(),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Deck body (ready state) ───────────────────────────────────────────────────

class _DeckBody extends StatelessWidget {
  const _DeckBody({
    required this.state,
    required this.cardController,
    required this.coachDismissed,
    required this.onCoachDismiss,
  });

  final NatarajState state;
  final NatarajCardController cardController;
  final bool coachDismissed;
  final VoidCallback onCoachDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<NatarajBloc>();
    final card = state.currentCard!;
    final showCoach = state.showCoach && !coachDismissed;
    // Nataraj is a pushed full-screen route (no FloatingNav on top), so reserve
    // only the bottom safe-area inset plus a small gap under the action buttons.
    final bottomGap = MediaQuery.of(context).padding.bottom + 12;

    return Stack(
      children: [
        // Main card + edge labels
        Positioned.fill(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Edge labels — static (Offset.zero = no live-drag at page level;
                      // the card animates drag internally).
                      const NatarajEdgeLabels(drag: Offset.zero),
                      // Swipe card — capped to the available height so a long
                      // note can't hide behind the action buttons. The card
                      // scrolls its generated-note body internally (see
                      // NatarajCardWidget); a short card hugs its content and
                      // the outer Stack (alignment: center) keeps it centered.
                      LayoutBuilder(
                        builder: (context, constraints) => ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight,
                          ),
                          child: NatarajCardWidget(
                            card: card,
                            peek: state.nextCard,
                            controller: cardController,
                            onSwipe: (dir) =>
                                bloc.add(NatarajEvent.swipeCard(dir)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Fallback action buttons (4 swipe directions). Routed through the
              // card controller so a tap flies the card off in that direction —
              // identical to a swipe — instead of advancing the deck instantly.
              _FallbackButtons(
                onPublish: () => cardController.swipe(NatarajDirection.up),
                onDraft: () => cardController.swipe(NatarajDirection.right),
                onDiscard: () => cardController.swipe(NatarajDirection.left),
                onDiscuss: () => cardController.swipe(NatarajDirection.down),
                l10n: l10n,
              ),
              SizedBox(height: bottomGap),
            ],
          ),
        ),

        // Coach overlay (shown once on first open)
        if (showCoach)
          Positioned.fill(
            child: NatarajCoachOverlay(onDismiss: onCoachDismiss),
          ),
      ],
    );
  }
}

// ── Fallback action buttons ───────────────────────────────────────────────────

class _FallbackButtons extends StatelessWidget {
  const _FallbackButtons({
    required this.onPublish,
    required this.onDraft,
    required this.onDiscard,
    required this.onDiscuss,
    required this.l10n,
  });

  final VoidCallback onPublish;
  final VoidCallback onDraft;
  final VoidCallback onDiscard;
  final VoidCallback onDiscuss;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ActionButton(
            icon: Icons.close_rounded,
            label: l10n.natarajEdgeDiscard,
            onTap: onDiscard,
          ),
          const SizedBox(width: 20),
          _ActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: l10n.natarajEdgeDiscuss,
            onTap: onDiscuss,
          ),
          const SizedBox(width: 20),
          _ActionButton(
            icon: Icons.bookmark_border_rounded,
            label: l10n.natarajEdgeDraft,
            onTap: onDraft,
          ),
          const SizedBox(width: 20),
          // Publish — the headline action, rendered as the primary accent CTA.
          _ActionButton(
            icon: Icons.publish_rounded,
            label: l10n.natarajEdgePublish,
            onTap: onPublish,
            primary: true,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final double diameter = primary ? 62 : 52;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
              border:
                  primary ? null : Border.all(color: context.custom.border),
              boxShadow: [
                BoxShadow(
                  color: primary
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.30)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: primary ? 18 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: primary ? 28 : 23,
              color:
                  primary ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: primary ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ── Error body ────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry, required this.onChangeModel});
  final VoidCallback onRetry;
  final VoidCallback onChangeModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Generation failed — the dominant cause is the on-device model failing to
    // run (e.g. a model too heavy for this device). Point the user at model
    // selection rather than a bare retry, so it's never mistaken for the
    // "exhausted / add notes" state.
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '✦',
              style: TextStyle(fontSize: 40, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.natarajModelErrorTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.natarajModelErrorBody,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            UniunButton(
              expand: false,
              height: 48,
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              label: l10n.aiSelectModel,
              onPressed: onChangeModel,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.natarajRetry),
            ),
          ],
        ),
      ),
    );
  }
}

// ── No-idea body ─────────────────────────────────────────────────────────────

/// Generation succeeded but produced nothing usable this round (e.g. the
/// model's response for that note combination was a noop). Deliberately
/// separate from [_ErrorBody] — nothing failed here, so there is no
/// "change model" CTA, only retry.
class _NoIdeaBody extends StatelessWidget {
  const _NoIdeaBody({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '✦',
              style: TextStyle(fontSize: 40, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.natarajNoIdeaTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.natarajNoIdeaBody,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            UniunButton(
              expand: false,
              height: 48,
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              label: l10n.natarajRetry,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
