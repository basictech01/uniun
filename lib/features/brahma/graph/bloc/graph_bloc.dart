import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/data/models/deleted_note_model.dart';
import 'package:uniun/data/models/manas_note_link_model.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/usecases/draft_usecases.dart';
import 'package:uniun/domain/usecases/manas_usecases.dart';
import 'package:uniun/domain/usecases/note_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/features/brahma/graph/models/graph_node_type.dart';

part 'graph_event.dart';
part 'graph_state.dart';

@injectable
class GraphBloc extends Bloc<GraphEvent, GraphState> {
  final GetAllSavedNotesUseCase _getAllSavedNotes;
  final GetOwnNotesUseCase _getOwnNotes;
  final GetDraftsUseCase _getDrafts;
  final GetActiveUserProfileUseCase _getActiveUserProfile;
  final DeleteDraftUseCase _deleteDraft;
  final GetProfileUseCase _getProfile;
  final GetNoteIdsForManasUseCase _getNoteIdsForManas;
  final GetManasByIdUseCase _getManasById;
  final GetNoteRelationCountsUseCase _getRelationCounts;
  final Isar _isar;

  StreamSubscription<void>? _deletedNoteWatcher;
  StreamSubscription<void>? _manasLinkWatcher;

  GraphBloc(
    this._getAllSavedNotes,
    this._getOwnNotes,
    this._getDrafts,
    this._getActiveUserProfile,
    this._deleteDraft,
    this._getProfile,
    this._getNoteIdsForManas,
    this._getManasById,
    this._getRelationCounts,
    this._isar,
  ) : super(const GraphState()) {
    on<LoadGraphEvent>(_onLoad);
    on<SelectGraphNodeEvent>(_onSelect);
    on<DeselectGraphNodeEvent>(_onDeselect);
    on<DeleteDraftNodeEvent>(_onDeleteDraft);
    on<SearchGraphEvent>(_onSearch);
    on<StepGraphMatchEvent>(_onStepMatch);
    on<StepConnectedNodeEvent>(_onStepConnection);

    // Deleting a note tombstones it in deletedNoteModels and removes its
    // NoteModel row. Rebuild the graph so the deleted node disappears —
    // preserve the current Manas scope across the reload.
    _deletedNoteWatcher = _isar.deletedNoteModels.watchLazy().listen((_) {
      if (!isClosed) {
        add(LoadGraphEvent(
          manasId: state.scopedManasId,
          manasName: state.scopedManasName,
        ));
      }
    });

    // Membership is written from ManasMembershipSheet, which is shared with
    // the feed and holds no GraphBloc — so the graph has to notice for itself.
    // Only a scoped graph derives its node set from membership; unscoped shows
    // everything regardless, so reloading it would be pure waste.
    _manasLinkWatcher = _isar.manasNoteLinkModels.watchLazy().listen((_) {
      if (!isClosed && state.scopedManasId != null) {
        add(LoadGraphEvent(
          manasId: state.scopedManasId,
          manasName: state.scopedManasName,
        ));
      }
    });
  }

  @override
  Future<void> close() {
    _deletedNoteWatcher?.cancel();
    _manasLinkWatcher?.cancel();
    return super.close();
  }

  Future<void> _onLoad(LoadGraphEvent event, Emitter<GraphState> emit) async {
    emit(state.copyWith(status: GraphStatus.loading));

    // ── 1. Saved notes ────────────────────────────────────────────────────────
    final savedResult = await _getAllSavedNotes.call();
    final savedNotes = savedResult.fold((_) => [], (n) => n);
    final savedIds = {for (final n in savedNotes) n.eventId};

    // ── 2. Own published notes ────────────────────────────────────────────────
    final profileResult = await _getActiveUserProfile.call();
    final pubkeyHex = profileResult.fold((_) => null, (p) => p.pubkeyHex);

    final ownNotes = <GraphNodeData>[];
    if (pubkeyHex != null) {
      final ownResult = await _getOwnNotes.call(pubkeyHex);
      ownResult.fold((_) {}, (notes) {
        for (final n in notes) {
          // DMs (kind 14/15) are authored by this user too, but they are
          // private messages — never surface them in the Brahma graph.
          if (n.kind == kDmTextKind || n.kind == kDmFileKind) continue;
          if (!savedIds.contains(n.id)) {
            ownNotes.add(GraphNodeData(
              eventId: n.id,
              content: n.content,
              eTagRefs: n.eTagRefs,
              type: GraphNodeType.own,
              authorPubkey: n.authorPubkey,
              sig: n.sig,
              created: n.created,
              rootEventId: n.rootEventId,
              replyToEventId: n.replyToEventId,
              referenceCount: n.referenceCount,
              cachedReplyCount: n.cachedReplyCount,
              tTags: n.tTags,
              pTagRefs: n.pTagRefs,
              attachments: n.attachments,
            ));
          }
        }
      });
    }

    // ── 3. Draft notes ────────────────────────────────────────────────────────
    final draftResult = await _getDrafts.call();
    final draftNodes = <GraphNodeData>[];
    draftResult.fold((_) {}, (drafts) {
      for (final d in drafts) {
        draftNodes.add(GraphNodeData(
          eventId: d.draftId,
          content: d.content,
          eTagRefs: d.eTagRefs,
          type: GraphNodeType.draft,
          // Drafts are always the user's own — seed the author so the panel
          // renders the avatar/name and resolves the own profile.
          authorPubkey: pubkeyHex,
          created: d.updatedAt,
          rootEventId: d.rootEventId,
          replyToEventId: d.replyToEventId,
          tTags: d.tTags,
          pTagRefs: d.pTagRefs,
          attachments: d.attachments,
          draftRefIds: d.draftRefIds,
        ));
      }
    });

    // ── 4. Saved → GraphNodeData ──────────────────────────────────────────────
    final savedNodes = savedNotes
        .map((n) => GraphNodeData(
              eventId: n.eventId,
              content: n.content,
              eTagRefs: n.eTagRefs,
              type: GraphNodeType.saved,
              authorPubkey: n.authorPubkey,
              sig: n.sig,
              created: n.created,
              rootEventId: n.rootEventId,
              replyToEventId: n.replyToEventId,
              referenceCount: n.referenceCount,
              cachedReplyCount: n.cachedReplyCount,
              tTags: n.tTags,
              pTagRefs: n.pTagRefs,
              attachments: n.attachments,
            ))
        .toList();

    final fullNodes = [...savedNodes, ...ownNotes, ...draftNodes];

    // ── 5. Manas scoping ─────────────────────────────────────────────────────
    // When `event.manasId` is set, restrict the visible node set to that
    // Manas's membership. _buildAdjacency already drops refs that fall
    // outside the live id set, so cross-scope edges disappear naturally.
    // Nodes keep their fixed saved/own/draft colours in every view.
    List<GraphNodeData> allNodes = fullNodes;
    String? scopeName = event.manasName;
    String? scopeIcon;
    if (event.manasId != null) {
      final linkRes = await _getNoteIdsForManas.call(event.manasId!);
      final allowed = linkRes
          .fold<Set<String>>((_) => const <String>{}, (l) => l.toSet());
      final manasRes = await _getManasById.call(event.manasId!);
      scopeIcon = manasRes.fold((_) => null, (m) => m.iconName);
      scopeName ??= manasRes.fold((_) => null, (m) => m.name);
      allNodes = [
        for (final n in fullNodes)
          if (allowed.contains(n.eventId)) n,
      ];
    }

    // ── 6. Global counts ─────────────────────────────────────────────────────
    // Override each node's reference/comment counts with the GLOBAL edge-table
    // counts. Saved nodes otherwise carry saved-scoped counts that miss the
    // user's own (unsaved) notes — so a referenced note wouldn't show a freshly
    // created note as a comment. Drafts have no edges → 0, which is correct.
    final countsRes =
        await _getRelationCounts.call([for (final n in allNodes) n.eventId]);
    final counts = countsRes.fold(
      (f) {
        // Graceful degrade: nodes fall back to their saved-scoped counts below.
        // Log so "counts look wrong" reports are diagnosable.
        log('Graph global relation counts failed: ${f.message}',
            name: 'GraphBloc');
        return const <String, RelationCounts>{};
      },
      (m) => m,
    );
    allNodes = [
      for (final n in allNodes)
        n.withCounts(
          referenceCount: counts[n.eventId]?.references ?? n.referenceCount,
          cachedReplyCount: counts[n.eventId]?.comments ?? n.cachedReplyCount,
        ),
    ];

    // Keep the active search consistent with the freshly-loaded node set.
    final matches = state.searchQuery.isEmpty
        ? const <String>[]
        : _matchNodes(state.searchQuery, allNodes);

    emit(state.copyWith(
      status: GraphStatus.loaded,
      nodes: allNodes,
      adjacency: buildAdjacency(allNodes),
      scopedManasId: event.manasId,
      scopedManasName: scopeName,
      scopedManasIconName: scopeIcon,
      clearScope: event.manasId == null,
      matchedNodeIds: matches.toSet(),
      matchOrder: matches,
      // A reload can drop or reorder matches and connections, so the old
      // cursors no longer point at the nodes the camera is on.
      matchIndex: -1,
      connectionIndex: -1,
      clearConnections: !allNodes.any((n) => n.eventId == state.connectionAnchorId),
    ));
  }

  Future<void> _onSelect(
      SelectGraphNodeEvent event, Emitter<GraphState> emit) async {
    if (state.selectedNodeId == event.nodeId) {
      emit(state.copyWith(clearSelection: true, clearConnections: true));
      return;
    }

    emit(state.copyWith(
      selectedNodeId: event.nodeId,
      connectionAnchorId: event.nodeId,
      connectionIndex: -1,
    ));
    await _loadProfileForSelection(emit);
  }

  /// Lazily load the selected node's author profile — profiles are only
  /// needed by the node panel, which only renders on selection.
  Future<void> _loadProfileForSelection(Emitter<GraphState> emit) async {
    final pubkey = state.selectedNode?.authorPubkey;
    if (pubkey == null || pubkey.isEmpty || state.profiles.containsKey(pubkey)) {
      return;
    }
    final r = await _getProfile.call(pubkey);
    r.fold((_) {}, (p) {
      emit(state.copyWith(profiles: {...state.profiles, p.pubkey: p}));
    });
  }

  void _onDeselect(DeselectGraphNodeEvent event, Emitter<GraphState> emit) {
    emit(state.copyWith(clearSelection: true, clearConnections: true));
  }

  void _onSearch(SearchGraphEvent event, Emitter<GraphState> emit) {
    final q = event.query.trim();
    final matches = q.isEmpty ? const <String>[] : _matchNodes(q, state.nodes);
    // The cursor starts off the list: every keystroke changes the match set, and
    // auto-focusing would fly the camera on each one. The stepper moves it.
    emit(state.copyWith(
      searchQuery: q,
      matchedNodeIds: matches.toSet(),
      matchOrder: matches,
      matchIndex: -1,
    ));
  }

  Future<void> _onStepMatch(
      StepGraphMatchEvent event, Emitter<GraphState> emit) async {
    final total = state.matchOrder.length;
    if (total == 0) return;
    final index = _stepCursor(state.matchIndex, event.delta, total);
    if (index < 0) {
      // Back out to the overview: the camera returns to the view held before
      // the first flight and the panel closes, with the matches still lit.
      emit(state.copyWith(
        matchIndex: -1,
        clearSelection: true,
        clearConnections: true,
      ));
      return;
    }
    emit(state.copyWith(
      matchIndex: index,
      selectedNodeId: state.matchOrder[index],
      // The match becomes the node on screen, so its connections are what the
      // panel's stepper should walk once the search closes.
      connectionAnchorId: state.matchOrder[index],
      connectionIndex: -1,
    ));
    await _loadProfileForSelection(emit);
  }

  Future<void> _onStepConnection(
      StepConnectedNodeEvent event, Emitter<GraphState> emit) async {
    final order = state.connectionOrder;
    if (order.isEmpty) return;
    final index = _stepCursor(state.connectionIndex, event.delta, order.length);
    // The anchor deliberately survives every step: the walk stays in orbit
    // around the node whose connections these are. Slot 0 of that orbit is the
    // anchor itself — stepping out of the ring comes home to it rather than
    // deselecting, which would take the stepper off screen with the panel.
    emit(state.copyWith(
      connectionIndex: index,
      selectedNodeId: index < 0 ? state.connectionAnchorId : order[index],
    ));
    await _loadProfileForSelection(emit);
  }

  /// Advances a stepper cursor by [delta] over [total] items plus the unfocused
  /// slot the walk starts in, wrapping through it at both ends. Returns -1 for
  /// that slot: the camera has flown to nothing and belongs back where it was.
  static int _stepCursor(int index, int delta, int total) =>
      ((index + 1 + delta) % (total + 1)) - 1;

  /// Node ids whose content or hashtags contain [query] (case-insensitive),
  /// newest note first so stepping runs in a stable, meaningful order.
  static List<String> _matchNodes(String query, List<GraphNodeData> nodes) {
    final q = query.toLowerCase();
    final matched = [
      for (final n in nodes)
        if (n.content.toLowerCase().contains(q) ||
            n.tTags.any((t) => t.toLowerCase().contains(q)))
          n,
    ]..sort((a, b) => (b.created ?? DateTime(0)).compareTo(
        a.created ?? DateTime(0)));
    return [for (final n in matched) n.eventId];
  }

  Future<void> _onDeleteDraft(
      DeleteDraftNodeEvent event, Emitter<GraphState> emit) async {
    await _deleteDraft.call(event.draftId);
    add(LoadGraphEvent(
      manasId: state.scopedManasId,
      manasName: state.scopedManasName,
    ));
  }

  /// Builds the undirected adjacency map from each node's [GraphNodeData.refEdges]
  /// (the canonical reference/reply parents — NIP-10 root excluded), so a graph
  /// edge is exactly one comment↔reference pair and matches the counts.
  /// Public so the edge rule can be unit-tested without driving the full bloc.
  static Map<String, Set<String>> buildAdjacency(List<GraphNodeData> nodes) {
    final allIds = {for (final n in nodes) n.eventId};
    final adj = <String, Set<String>>{
      for (final n in nodes) n.eventId: <String>{},
    };
    for (final node in nodes) {
      for (final ref in node.refEdges) {
        if (ref != node.eventId && allIds.contains(ref)) {
          adj[node.eventId]!.add(ref);
          adj[ref]!.add(node.eventId);
        }
      }
    }
    return adj;
  }
}
