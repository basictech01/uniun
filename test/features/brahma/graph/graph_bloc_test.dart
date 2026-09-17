
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/domain/entities/draft/draft_entity.dart';
import 'package:uniun/data/models/manas_note_link_model.dart';
import 'package:uniun/domain/entities/manas/manas_entity.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';
import 'package:uniun/domain/usecases/draft_usecases.dart';
import 'package:uniun/domain/usecases/manas_usecases.dart';
import 'package:uniun/domain/usecases/note_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/features/brahma/graph/bloc/graph_bloc.dart';
import 'package:uniun/features/brahma/graph/models/graph_node_type.dart';

import '../../../_helpers/isar_seeds.dart';
import '../../../_helpers/isar_test_harness.dart';

/// Full BLoC tests for [GraphBloc] — the load orchestrator behind the
/// Brahma graph view. The adjacency math is pure-tested in
/// `graph_edges_test.dart`; this file drives the BLoC end-to-end:
///
///   - `LoadGraphEvent` (initial, scoped to a Manas, with relation counts)
///   - `SelectGraphNodeEvent` (lazy profile load, toggle deselect)
///   - `DeselectGraphNodeEvent`
///   - `DeleteDraftNodeEvent` → deletes via use case + reloads graph
///   - `SearchGraphEvent` (case-insensitive content + hashtag match)
///   - `StepGraphMatchEvent` (camera cursor over the matches, #208)
///   - `StepConnectedNodeEvent` (same walk over a node's edges, no search)
///   - `deletedNoteModels.watchLazy()` triggers a reload
///
/// The 10 use case dependencies are stubbed via `implements` + `noSuchMethod`;
/// only [Isar] is real (so the deleted-note watcher actually fires).
void main() {
  late Isar isar;
  late _GetAllSaved getAllSaved;
  late _GetOwn getOwn;
  late _GetDrafts getDrafts;
  late _GetActiveUserProfile getProfile;
  late _DeleteDraft deleteDraft;
  late _GetProfile profileLookup;
  late _GetNoteIdsForManas noteIdsForManas;
  late _GetManasById manasById;
  late _GetRelationCounts relationCounts;

  GraphBloc build() => GraphBloc(
        getAllSaved,
        getOwn,
        getDrafts,
        getProfile,
        deleteDraft,
        profileLookup,
        noteIdsForManas,
        manasById,
        relationCounts,
        isar,
      );

  setUp(() async {
    isar = await openTestIsar();
    getAllSaved = _GetAllSaved();
    getOwn = _GetOwn();
    getDrafts = _GetDrafts();
    getProfile = _GetActiveUserProfile();
    deleteDraft = _DeleteDraft();
    profileLookup = _GetProfile();
    noteIdsForManas = _GetNoteIdsForManas();
    manasById = _GetManasById();
    relationCounts = _GetRelationCounts();
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  NoteEntity ownNote(String id,
          {String? pubkey = 'me',
          List<String> eTagRefs = const [],
          String? root,
          String? reply,
          int kind = 1}) =>
      NoteEntity(
        id: id,
        sig: 's',
        authorPubkey: pubkey!,
        content: 'own-$id',
        type: NoteType.text,
        eTagRefs: eTagRefs,
        pTagRefs: const [],
        tTags: const [],
        created: DateTime(2026, 1, 1),
        rootEventId: root,
        replyToEventId: reply,
        kind: kind,
      );

  SavedNoteEntity savedNote(String id) => SavedNoteEntity(
        eventId: id,
        sig: 's',
        authorPubkey: 'other',
        content: 'saved-$id',
        type: NoteType.text,
        eTagRefs: const [],
        pTagRefs: const [],
        tTags: const [],
        created: DateTime(2026, 1, 1),
        savedAt: DateTime(2026, 1, 1),
      );

  DraftEntity draftNote(String draftId, {List<String> draftRefIds = const []}) =>
      DraftEntity(
        draftId: draftId,
        content: 'd-$draftId',
        eTagRefs: const [],
        pTagRefs: const [],
        tTags: const [],
        draftRefIds: draftRefIds,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  Future<GraphState> waitFor(
    GraphBloc bloc,
    bool Function(GraphState) predicate, {
    Duration timeout = const Duration(seconds: 3),
  }) =>
      bloc.stream
          .firstWhere(predicate)
          .timeout(timeout, onTimeout: () => bloc.state);

  // ── LoadGraphEvent ───────────────────────────────────────────────────────

  group('LoadGraphEvent', () {
    test('empty repository → loaded state with empty nodes + adjacency', () async {
      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      expect(bloc.state.nodes, isEmpty);
      expect(bloc.state.adjacency, isEmpty);
      await bloc.close();
    });

    test('mixes own notes + saved notes + drafts into one node set', () async {
      getOwn.notes = [ownNote('own-1')];
      getAllSaved.saved = [savedNote('saved-1')];
      getDrafts.drafts = [draftNote('draft-1')];

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      final ids = bloc.state.nodes.map((n) => n.eventId).toSet();
      expect(ids, {'own-1', 'saved-1', 'draft-1'});
      // Each node carries its type for colouring.
      final byId = {for (final n in bloc.state.nodes) n.eventId: n.type};
      expect(byId['own-1'], GraphNodeType.own);
      expect(byId['saved-1'], GraphNodeType.saved);
      expect(byId['draft-1'], GraphNodeType.draft);
      await bloc.close();
    });

    test('an own note that is ALSO saved is de-duplicated (saved wins)', () async {
      // getAllSaved returns one node; getOwn returns a note with the SAME id.
      // The BLoC's `_onLoad` filters `ownNotes` to exclude saved ids.
      getAllSaved.saved = [savedNote('dup-id')];
      getOwn.notes = [ownNote('dup-id')];

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      final nodes = bloc.state.nodes.where((n) => n.eventId == 'dup-id').toList();
      expect(nodes, hasLength(1));
      expect(nodes.single.type, GraphNodeType.saved);
      await bloc.close();
    });

    test('Manas scope restricts visible nodes; off-scope edges silently disappear', () async {
      getOwn.notes = [ownNote('in-scope'), ownNote('out-of-scope')];
      noteIdsForManas.allowed = {'manas-1': ['in-scope']};
      manasById.bySid = {
        'manas-1': ManasEntity(
          manasId: 'manas-1',
          name: 'work',
          iconName: 'folder',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      };

      final bloc = build();
      bloc.add(const LoadGraphEvent(manasId: 'manas-1'));
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      expect(bloc.state.nodes.map((n) => n.eventId), ['in-scope']);
      expect(bloc.state.scopedManasId, 'manas-1');
      expect(bloc.state.scopedManasName, 'work');
      await bloc.close();
    });

    test('a bare LoadGraphEvent CLEARS an existing Manas scope — a null '
        'manasId is an explicit unscope, not "leave it alone"', () async {
      getOwn.notes = [ownNote('in-scope'), ownNote('out-of-scope')];
      noteIdsForManas.allowed = {'manas-1': ['in-scope']};
      manasById.bySid = {
        'manas-1': ManasEntity(
          manasId: 'manas-1',
          name: 'work',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      };

      final bloc = build();
      bloc.add(const LoadGraphEvent(manasId: 'manas-1'));
      await waitFor(bloc, (s) => s.scopedManasId == 'manas-1');

      // This is the trap behind #204: callers that reload with a bare event
      // silently drop the user out of their scoped view.
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.scopedManasId == null);
      expect(bloc.state.nodes, hasLength(2));
      expect(bloc.state.scopedManasName, isNull);
      await bloc.close();
    });

    test('DMs authored by this user are never surfaced as graph nodes',
        () async {
      getOwn.notes = [
        ownNote('note'),
        ownNote('dm-text', kind: kDmTextKind),
        ownNote('dm-file', kind: kDmFileKind),
      ];

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      expect(bloc.state.nodes.map((n) => n.eventId), ['note']);
      await bloc.close();
    });

    test('an active search is re-matched against the freshly-loaded node set',
        () async {
      getOwn.notes = [ownNote('A')];

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      bloc.add(const SearchGraphEvent('own-B'));
      await waitFor(bloc, (s) => s.searchQuery == 'own-B');
      expect(bloc.state.matchedNodeIds, isEmpty);

      // B arrives on the next load — the still-active query must now match it.
      getOwn.notes = [ownNote('A'), ownNote('B')];
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.nodes.length == 2);
      expect(bloc.state.matchedNodeIds, {'B'});
      await bloc.close();
    });

    test('stitches global relation counts onto every node', () async {
      getOwn.notes = [ownNote('A'), ownNote('B')];
      relationCounts.counts = {
        'A': const RelationCounts(comments: 3, references: 1),
        'B': const RelationCounts(comments: 0, references: 5),
      };

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      final a = bloc.state.nodes.firstWhere((n) => n.eventId == 'A');
      final b = bloc.state.nodes.firstWhere((n) => n.eventId == 'B');
      expect(a.cachedReplyCount, 3);
      expect(a.referenceCount, 1);
      expect(b.cachedReplyCount, 0);
      expect(b.referenceCount, 5);
      await bloc.close();
    });

    test('relation-count fetch failure → nodes fall back to their own counts (graceful degrade)', () async {
      getOwn.notes = [ownNote('A')];
      relationCounts.fail = true;

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      // Graceful degrade: the load succeeds, the node just carries its
      // pre-stitched (zero) counts instead of the global ones.
      expect(bloc.state.nodes, hasLength(1));
      await bloc.close();
    });

    test('builds correct adjacency from a mention edge between own notes', () async {
      // B mentions A. Bidirectional graph edge expected.
      getOwn.notes = [
        ownNote('A'),
        ownNote('B', eTagRefs: ['A']),
      ];

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      expect(bloc.state.adjacency['A'], {'B'});
      expect(bloc.state.adjacency['B'], {'A'});
      await bloc.close();
    });

    test('draft→draft ref forms an edge in the loaded adjacency', () async {
      getDrafts.drafts = [
        draftNote('parent', draftRefIds: ['child']),
        draftNote('child'),
      ];

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      expect(bloc.state.adjacency['parent'], {'child'});
      expect(bloc.state.adjacency['child'], {'parent'});
      await bloc.close();
    });
  });

  // ── SelectGraphNodeEvent ─────────────────────────────────────────────────

  group('SelectGraphNodeEvent', () {
    test('selecting a node sets selectedNodeId; lazily loads the author profile', () async {
      getOwn.notes = [ownNote('A', pubkey: 'me-pub')];
      profileLookup.profiles = {
        'me-pub': ProfileEntity(
          pubkey: 'me-pub',
          name: 'Me',
          updatedAt: DateTime(2026, 1, 1),
        ),
      };

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);

      bloc.add(const SelectGraphNodeEvent('A'));
      await waitFor(bloc, (s) => s.profiles.containsKey('me-pub'));
      expect(bloc.state.selectedNodeId, 'A');
      expect(bloc.state.profiles['me-pub']?.name, 'Me');
      // One lookup only — selecting again must hit the cache.
      expect(profileLookup.calls, 1);

      bloc.add(const DeselectGraphNodeEvent());
      await waitFor(bloc, (s) => s.selectedNodeId == null);

      bloc.add(const SelectGraphNodeEvent('A'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(profileLookup.calls, 1,
          reason: 'profile already cached — no second lookup');
      await bloc.close();
    });

    test('selecting the SAME node twice toggles to deselected', () async {
      getOwn.notes = [ownNote('A')];

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);

      bloc.add(const SelectGraphNodeEvent('A'));
      await waitFor(bloc, (s) => s.selectedNodeId == 'A');
      bloc.add(const SelectGraphNodeEvent('A'));
      await waitFor(bloc, (s) => s.selectedNodeId == null);
      await bloc.close();
    });
  });

  // ── DeleteDraftNodeEvent ────────────────────────────────────────────────

  group('DeleteDraftNodeEvent', () {
    test('deletes via use case + reloads the graph minus the draft', () async {
      // Initial load contains the draft.
      getDrafts.drafts = [draftNote('d-1'), draftNote('d-2')];

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.nodes.length == 2);

      // After deletion the BLoC reloads via add(LoadGraphEvent(...)). Wire
      // the fake to drop d-1 on the next read.
      deleteDraft.onCall = (id) {
        getDrafts.drafts = getDrafts.drafts.where((d) => d.draftId != id).toList();
      };
      bloc.add(const DeleteDraftNodeEvent('d-1'));
      await waitFor(bloc, (s) => s.nodes.length == 1);
      expect(bloc.state.nodes.single.eventId, 'd-2');
      expect(deleteDraft.calls, ['d-1']);
      await bloc.close();
    });

    test('preserves Manas scope across the reload', () async {
      getDrafts.drafts = [draftNote('d-1')];
      noteIdsForManas.allowed = {'manas-1': ['d-1']};
      manasById.bySid = {
        'manas-1': ManasEntity(
          manasId: 'manas-1',
          name: 'work',
          iconName: 'f',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      };

      final bloc = build();
      bloc.add(const LoadGraphEvent(manasId: 'manas-1'));
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      expect(bloc.state.scopedManasId, 'manas-1');

      deleteDraft.onCall = (id) {
        getDrafts.drafts = const [];
      };
      bloc.add(const DeleteDraftNodeEvent('d-1'));
      await waitFor(bloc, (s) => s.nodes.isEmpty);
      // Scope SURVIVED the reload — the BLoC threads it through.
      expect(bloc.state.scopedManasId, 'manas-1');
      await bloc.close();
    });
  });

  // ── SearchGraphEvent ────────────────────────────────────────────────────

  group('SearchGraphEvent', () {
    test('matches by content (case-insensitive substring)', () async {
      getOwn.notes = [
        ownNote('A').copyWith(content: 'Hello WORLD'),
        ownNote('B').copyWith(content: 'goodbye'),
      ];

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);

      bloc.add(const SearchGraphEvent('world'));
      await waitFor(bloc, (s) => s.matchedNodeIds.isNotEmpty);
      expect(bloc.state.matchedNodeIds, {'A'});
      await bloc.close();
    });

    test('matches by hashtag', () async {
      getOwn.notes = [
        ownNote('A').copyWith(tTags: const ['nostr']),
        ownNote('B').copyWith(tTags: const ['flutter']),
      ];

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      bloc.add(const SearchGraphEvent('nostr'));
      await waitFor(bloc, (s) => s.matchedNodeIds.isNotEmpty);
      expect(bloc.state.matchedNodeIds, {'A'});
      await bloc.close();
    });

    test('empty query → matchedNodeIds reset to empty', () async {
      getOwn.notes = [ownNote('A').copyWith(content: 'pizza')];

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      bloc.add(const SearchGraphEvent('pizza'));
      await waitFor(bloc, (s) => s.matchedNodeIds.isNotEmpty);
      bloc.add(const SearchGraphEvent('   '));
      await waitFor(bloc, (s) => s.matchedNodeIds.isEmpty);
      expect(bloc.state.matchOrder, isEmpty);
      expect(bloc.state.matchIndex, -1);
      await bloc.close();
    });

    test('matchOrder runs newest note first', () async {
      getOwn.notes = [
        ownNote('old').copyWith(content: 'hit', created: DateTime(2026, 1, 1)),
        ownNote('new').copyWith(content: 'hit', created: DateTime(2026, 3, 1)),
        ownNote('mid').copyWith(content: 'hit', created: DateTime(2026, 2, 1)),
      ];

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      bloc.add(const SearchGraphEvent('hit'));
      await waitFor(bloc, (s) => s.matchOrder.isNotEmpty);
      expect(bloc.state.matchOrder, ['new', 'mid', 'old']);
      await bloc.close();
    });

    test('typing lights the matches but moves neither cursor nor selection — '
        'the camera must not chase every keystroke', () async {
      getOwn.notes = [ownNote('A').copyWith(content: 'hit')];

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      bloc.add(const SearchGraphEvent('hit'));
      await waitFor(bloc, (s) => s.matchOrder.isNotEmpty);
      expect(bloc.state.matchedNodeIds, {'A'});
      expect(bloc.state.matchIndex, -1);
      expect(bloc.state.focusedMatchId, isNull);
      expect(bloc.state.selectedNodeId, isNull);
      await bloc.close();
    });
  });

  // ── StepGraphMatchEvent ─────────────────────────────────────────────────

  group('StepGraphMatchEvent', () {
    /// Three matching notes, newest first: n3, n2, n1.
    Future<GraphBloc> searched() async {
      getOwn.notes = [
        ownNote('n1').copyWith(content: 'hit', created: DateTime(2026, 1, 1)),
        ownNote('n2').copyWith(content: 'hit', created: DateTime(2026, 2, 1)),
        ownNote('n3').copyWith(content: 'hit', created: DateTime(2026, 3, 1)),
        ownNote('miss').copyWith(content: 'nope'),
      ];
      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      bloc.add(const SearchGraphEvent('hit'));
      await waitFor(bloc, (s) => s.matchOrder.isNotEmpty);
      return bloc;
    }

    test('first forward step focuses and selects the newest match', () async {
      final bloc = await searched();
      bloc.add(const StepGraphMatchEvent(1));
      await waitFor(bloc, (s) => s.matchIndex == 0);
      expect(bloc.state.focusedMatchId, 'n3');
      expect(bloc.state.selectedNodeId, 'n3');
      await bloc.close();
    });

    test('first backward step wraps to the last match', () async {
      final bloc = await searched();
      bloc.add(const StepGraphMatchEvent(-1));
      await waitFor(bloc, (s) => s.matchIndex >= 0);
      expect(bloc.state.matchIndex, 2);
      expect(bloc.state.focusedMatchId, 'n1');
      await bloc.close();
    });

    test('stepping past the last match lands on the overview slot, not back '
        'on the first — the camera can return to the wide view', () async {
      final bloc = await searched();
      for (var i = 0; i < 3; i++) {
        bloc.add(const StepGraphMatchEvent(1));
        await waitFor(bloc, (s) => s.matchIndex == i);
      }
      bloc.add(const StepGraphMatchEvent(1));
      await waitFor(bloc, (s) => s.matchIndex == -1);
      expect(bloc.state.focusedMatchId, isNull, reason: 'nothing to fly to');
      expect(bloc.state.selectedNodeId, isNull, reason: 'the panel closes');
      // The matches stay lit — only the camera and the panel step out.
      expect(bloc.state.matchedNodeIds, {'n1', 'n2', 'n3'});
      await bloc.close();
    });

    test('a step on from the overview slot re-enters at the first match',
        () async {
      final bloc = await searched();
      for (var i = 0; i < 4; i++) {
        bloc.add(const StepGraphMatchEvent(1));
        await waitFor(bloc, (s) => s.matchIndex == (i == 3 ? -1 : i));
      }
      bloc.add(const StepGraphMatchEvent(1));
      await waitFor(bloc, (s) => s.matchIndex == 0);
      expect(bloc.state.focusedMatchId, 'n3');
      await bloc.close();
    });

    test('stepping back from the first match lands on the overview slot',
        () async {
      final bloc = await searched();
      bloc.add(const StepGraphMatchEvent(1));
      await waitFor(bloc, (s) => s.matchIndex == 0);
      bloc.add(const StepGraphMatchEvent(-1));
      await waitFor(bloc, (s) => s.matchIndex == -1);
      expect(bloc.state.selectedNodeId, isNull);
      await bloc.close();
    });

    test('stepping with no matches changes nothing', () async {
      getOwn.notes = [ownNote('A').copyWith(content: 'nope')];

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      bloc.add(const SearchGraphEvent('hit'));
      await waitFor(bloc, (s) => s.searchQuery == 'hit');

      bloc.add(const StepGraphMatchEvent(1));
      await pumpEventQueue();
      expect(bloc.state.matchIndex, -1);
      expect(bloc.state.selectedNodeId, isNull);
      await bloc.close();
    });

    test('stepping onto a node loads its author profile, like tapping it',
        () async {
      getOwn.notes = [ownNote('A', pubkey: 'me-pub').copyWith(content: 'hit')];
      profileLookup.profiles = {
        'me-pub': ProfileEntity(
          pubkey: 'me-pub',
          name: 'Me',
          updatedAt: DateTime(2026, 1, 1),
        ),
      };

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      bloc.add(const SearchGraphEvent('hit'));
      await waitFor(bloc, (s) => s.matchOrder.isNotEmpty);
      bloc.add(const StepGraphMatchEvent(1));
      await waitFor(bloc, (s) => s.profiles.containsKey('me-pub'));
      expect(bloc.state.profiles['me-pub']?.name, 'Me');
      await bloc.close();
    });

    test('a reload drops the cursor — the old index may point at a node that '
        'is gone or has moved in the order', () async {
      final bloc = await searched();
      bloc.add(const StepGraphMatchEvent(1));
      await waitFor(bloc, (s) => s.matchIndex == 0);

      getOwn.notes = [ownNote('n2').copyWith(content: 'hit')];
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.nodes.length == 1);
      expect(bloc.state.matchOrder, ['n2']);
      expect(bloc.state.matchIndex, -1);
      await bloc.close();
    });
  });

  // ── StepConnectedNodeEvent ──────────────────────────────────────────────

  group('StepConnectedNodeEvent', () {
    /// `hub` references three notes, newest first: c, b, a. `lone` references
    /// nothing.
    Future<GraphBloc> withHub() async {
      getOwn.notes = [
        ownNote('hub', eTagRefs: ['a', 'b', 'c']),
        ownNote('a').copyWith(created: DateTime(2026, 1, 1)),
        ownNote('b').copyWith(created: DateTime(2026, 2, 1)),
        ownNote('c').copyWith(created: DateTime(2026, 3, 1)),
        ownNote('lone'),
      ];
      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      return bloc;
    }

    test('selecting a node anchors the walk on its connections', () async {
      final bloc = await withHub();
      bloc.add(const SelectGraphNodeEvent('hub'));
      await waitFor(bloc, (s) => s.selectedNodeId == 'hub');
      expect(bloc.state.connectionAnchorId, 'hub');
      expect(bloc.state.connectionOrder, ['c', 'b', 'a']);
      expect(bloc.state.connectionIndex, -1);
      await bloc.close();
    });

    test('stepping selects each connection in turn, wrapping at the end',
        () async {
      final bloc = await withHub();
      bloc.add(const SelectGraphNodeEvent('hub'));
      await waitFor(bloc, (s) => s.selectedNodeId == 'hub');

      // Slot 0 of the orbit is the anchor itself, so the ring is c, b, a, hub.
      for (final expected in ['c', 'b', 'a', 'hub', 'c']) {
        bloc.add(const StepConnectedNodeEvent(1));
        await waitFor(bloc, (s) => s.selectedNodeId == expected);
        expect(bloc.state.selectedNodeId, expected);
      }
      await bloc.close();
    });

    test('stepping out of the ring comes home to the anchor with the panel '
        'still open, so the walk can continue', () async {
      final bloc = await withHub();
      bloc.add(const SelectGraphNodeEvent('hub'));
      await waitFor(bloc, (s) => s.selectedNodeId == 'hub');
      for (var i = 0; i < 3; i++) {
        bloc.add(const StepConnectedNodeEvent(1));
        await waitFor(bloc, (s) => s.connectionIndex == i);
      }

      bloc.add(const StepConnectedNodeEvent(1));
      await waitFor(bloc, (s) => s.connectionIndex == -1);
      expect(bloc.state.selectedNodeId, 'hub');
      expect(bloc.state.connectionAnchorId, 'hub');
      expect(bloc.state.focusedConnectionId, isNull, reason: 'camera goes back');
      await bloc.close();
    });

    test('the walk stays in orbit — the anchor does not follow the selection, '
        'so stepping back returns to the previous connection', () async {
      final bloc = await withHub();
      bloc.add(const SelectGraphNodeEvent('hub'));
      await waitFor(bloc, (s) => s.selectedNodeId == 'hub');
      bloc.add(const StepConnectedNodeEvent(1));
      await waitFor(bloc, (s) => s.connectionIndex == 0);
      bloc.add(const StepConnectedNodeEvent(1));
      await waitFor(bloc, (s) => s.connectionIndex == 1);

      expect(bloc.state.connectionAnchorId, 'hub');
      bloc.add(const StepConnectedNodeEvent(-1));
      await waitFor(bloc, (s) => s.connectionIndex == 0);
      expect(bloc.state.selectedNodeId, 'c');
      await bloc.close();
    });

    test('a first backward step wraps to the last connection', () async {
      final bloc = await withHub();
      bloc.add(const SelectGraphNodeEvent('hub'));
      await waitFor(bloc, (s) => s.selectedNodeId == 'hub');
      bloc.add(const StepConnectedNodeEvent(-1));
      await waitFor(bloc, (s) => s.connectionIndex >= 0);
      expect(bloc.state.connectionIndex, 2);
      expect(bloc.state.selectedNodeId, 'a');
      await bloc.close();
    });

    test('tapping a node re-anchors the walk on that node', () async {
      final bloc = await withHub();
      bloc.add(const SelectGraphNodeEvent('hub'));
      await waitFor(bloc, (s) => s.selectedNodeId == 'hub');
      bloc.add(const StepConnectedNodeEvent(1));
      await waitFor(bloc, (s) => s.connectionIndex == 0);

      bloc.add(const SelectGraphNodeEvent('b'));
      await waitFor(bloc, (s) => s.selectedNodeId == 'b');
      expect(bloc.state.connectionAnchorId, 'b');
      expect(bloc.state.connectionOrder, ['hub']);
      expect(bloc.state.connectionIndex, -1);
      await bloc.close();
    });

    test('a node with no connections has nothing to step', () async {
      final bloc = await withHub();
      bloc.add(const SelectGraphNodeEvent('lone'));
      await waitFor(bloc, (s) => s.selectedNodeId == 'lone');
      expect(bloc.state.connectionOrder, isEmpty);

      bloc.add(const StepConnectedNodeEvent(1));
      await pumpEventQueue();
      expect(bloc.state.selectedNodeId, 'lone');
      expect(bloc.state.connectionIndex, -1);
      await bloc.close();
    });

    test('deselecting drops the anchor', () async {
      final bloc = await withHub();
      bloc.add(const SelectGraphNodeEvent('hub'));
      await waitFor(bloc, (s) => s.connectionAnchorId == 'hub');
      bloc.add(const DeselectGraphNodeEvent());
      await waitFor(bloc, (s) => s.selectedNodeId == null);
      expect(bloc.state.connectionAnchorId, isNull);
      expect(bloc.state.connectionOrder, isEmpty);
      await bloc.close();
    });

    test('a reload keeps a surviving anchor but drops one whose node is gone',
        () async {
      final bloc = await withHub();
      bloc.add(const SelectGraphNodeEvent('hub'));
      await waitFor(bloc, (s) => s.connectionAnchorId == 'hub');

      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      expect(bloc.state.connectionAnchorId, 'hub');

      getOwn.notes = [ownNote('other')];
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.nodes.length == 1);
      expect(bloc.state.connectionAnchorId, isNull);
      await bloc.close();
    });

    test('stepping a match anchors the walk on that match, so the panel can '
        'follow its edges once the search closes', () async {
      getOwn.notes = [
        ownNote('hub', eTagRefs: ['a']).copyWith(content: 'hit'),
        ownNote('a'),
      ];
      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      bloc.add(const SearchGraphEvent('hit'));
      await waitFor(bloc, (s) => s.matchOrder.isNotEmpty);
      bloc.add(const StepGraphMatchEvent(1));
      await waitFor(bloc, (s) => s.matchIndex == 0);

      expect(bloc.state.connectionAnchorId, 'hub');
      expect(bloc.state.connectionOrder, ['a']);
      await bloc.close();
    });
  });

  // ── focusedNodeId (which cursor owns the camera) ────────────────────────

  group('focusedNodeId', () {
    test('an open search owns the camera; the connection walk takes it back '
        'when the search closes', () async {
      getOwn.notes = [
        ownNote('hub', eTagRefs: ['a']).copyWith(content: 'hit'),
        ownNote('a'),
      ];
      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);

      bloc.add(const SelectGraphNodeEvent('hub'));
      await waitFor(bloc, (s) => s.selectedNodeId == 'hub');
      bloc.add(const StepConnectedNodeEvent(1));
      await waitFor(bloc, (s) => s.connectionIndex == 0);
      expect(bloc.state.focusedNodeId, 'a');

      bloc.add(const SearchGraphEvent('hit'));
      await waitFor(bloc, (s) => s.isSearching);
      expect(bloc.state.focusedNodeId, isNull, reason: 'search owns it, unstepped');

      bloc.add(const SearchGraphEvent(''));
      await waitFor(bloc, (s) => !s.isSearching);
      expect(bloc.state.focusedNodeId, 'a');
      await bloc.close();
    });
  });

  // ── deletedNoteModels watcher ───────────────────────────────────────────

  group('deletedNoteModels watcher', () {
    test('tombstoning a note via Isar triggers an automatic graph reload', () async {
      getOwn.notes = [ownNote('A')];

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      expect(bloc.state.nodes, hasLength(1));

      // Wire the next reload to a smaller note set.
      getOwn.notes = const [];

      // Insert a tombstone row directly into Isar. The bloc's
      // `watchLazy` subscription should fire `LoadGraphEvent`.
      await seedDeletedNote(isar, 'A', deletedAt: DateTime.now());
      await waitFor(
        bloc,
        (s) => s.status == GraphStatus.loaded && s.nodes.isEmpty,
        timeout: const Duration(seconds: 2),
      );
      await bloc.close();
    });
  });

  // ── manasNoteLinkModels watcher (#205) ──────────────────────────────────

  group('manasNoteLinkModels watcher', () {
    Future<void> writeLink(String manasId, String noteId) =>
        isar.writeTxn(() async {
          await isar.manasNoteLinkModels.put(
            ManasNoteLinkModel()
              ..manasId = manasId
              ..noteId = noteId
              ..addedAt = DateTime(2026, 1, 1),
          );
        });

    test('a membership write reloads a SCOPED graph, preserving the scope',
        () async {
      getOwn.notes = [ownNote('A'), ownNote('B')];
      noteIdsForManas.allowed = {'m1': ['A']};
      manasById.bySid = {
        'm1': ManasEntity(
          manasId: 'm1',
          name: 'work',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      };

      final bloc = build();
      bloc.add(const LoadGraphEvent(manasId: 'm1'));
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      expect(bloc.state.nodes.map((n) => n.eventId), ['A']);

      // B joins the Manas — the sheet writes the link and tells nobody.
      noteIdsForManas.allowed = {'m1': ['A', 'B']};
      await writeLink('m1', 'B');

      await waitFor(
        bloc,
        (s) => s.nodes.length == 2,
        timeout: const Duration(seconds: 2),
      );
      // waitFor returns the current state on timeout rather than throwing, so
      // the reload has to be asserted, not merely awaited.
      expect(bloc.state.nodes.map((n) => n.eventId), containsAll(['A', 'B']));
      expect(bloc.state.scopedManasId, 'm1');
      expect(bloc.state.scopedManasName, 'work');
      await bloc.close();
    });

    test('a removal is picked up too — the node leaves the scoped graph',
        () async {
      getOwn.notes = [ownNote('A'), ownNote('B')];
      noteIdsForManas.allowed = {'m1': ['A', 'B']};

      final bloc = build();
      bloc.add(const LoadGraphEvent(manasId: 'm1'));
      await waitFor(bloc, (s) => s.nodes.length == 2);

      noteIdsForManas.allowed = {'m1': ['A']};
      await writeLink('m1', 'B'); // any write to the table fires the watcher

      await waitFor(
        bloc,
        (s) => s.nodes.length == 1,
        timeout: const Duration(seconds: 2),
      );
      expect(bloc.state.nodes.single.eventId, 'A');
      await bloc.close();
    });

    test('an UNSCOPED graph is not reloaded — its node set cannot depend on '
        'membership, so the rebuild would be pure waste', () async {
      getOwn.notes = [ownNote('A')];

      final bloc = build();
      bloc.add(const LoadGraphEvent());
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);

      // If the watcher fired regardless of scope, this would be picked up.
      getOwn.notes = [ownNote('A'), ownNote('B')];
      await writeLink('m1', 'B');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(bloc.state.nodes, hasLength(1));
      await bloc.close();
    });

    test('the watcher is cancelled on close — no reload after dispose',
        () async {
      getOwn.notes = [ownNote('A')];
      noteIdsForManas.allowed = {'m1': ['A']};

      final bloc = build();
      bloc.add(const LoadGraphEvent(manasId: 'm1'));
      await waitFor(bloc, (s) => s.status == GraphStatus.loaded);
      await bloc.close();

      // Must not throw "add called after close".
      await writeLink('m1', 'B');
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
  });
}

// ── Fakes ────────────────────────────────────────────────────────────────

class _GetAllSaved implements GetAllSavedNotesUseCase {
  List<SavedNoteEntity> saved = const [];
  @override
  Future<Either<Failure, List<SavedNoteEntity>>> call({bool cached = false}) async =>
      Right(saved);
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _GetOwn implements GetOwnNotesUseCase {
  List<NoteEntity> notes = const [];
  @override
  Future<Either<Failure, List<NoteEntity>>> call(String pubkey, {bool cached = false}) async =>
      Right(notes);
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _GetDrafts implements GetDraftsUseCase {
  List<DraftEntity> drafts = const [];
  @override
  Future<Either<Failure, List<DraftEntity>>> call({bool cached = false}) async =>
      Right(drafts);
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _GetActiveUserProfile implements GetActiveUserProfileUseCase {
  @override
  Future<Either<Failure, ActiveUserProfile>> call({bool cached = false}) async =>
      const Right(ActiveUserProfile(pubkeyHex: 'me'));
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _DeleteDraft implements DeleteDraftUseCase {
  final List<String> calls = [];
  void Function(String)? onCall;
  @override
  Future<Either<Failure, Unit>> call(String input, {bool cached = false}) async {
    calls.add(input);
    onCall?.call(input);
    return const Right(unit);
  }
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _GetProfile implements GetProfileUseCase {
  Map<String, ProfileEntity> profiles = {};
  int calls = 0;
  @override
  Future<Either<Failure, ProfileEntity>> call(String pubkey, {bool cached = false}) async {
    calls++;
    final p = profiles[pubkey];
    if (p == null) return const Left(Failure.notFoundFailure('no profile'));
    return Right(p);
  }
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _GetNoteIdsForManas implements GetNoteIdsForManasUseCase {
  Map<String, List<String>> allowed = {};
  @override
  Future<Either<Failure, List<String>>> call(String manasId, {bool cached = false}) async =>
      Right(allowed[manasId] ?? const []);
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _GetManasById implements GetManasByIdUseCase {
  Map<String, ManasEntity> bySid = {};
  @override
  Future<Either<Failure, ManasEntity>> call(String manasId, {bool cached = false}) async {
    final m = bySid[manasId];
    if (m == null) return const Left(Failure.notFoundFailure('no manas'));
    return Right(m);
  }
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _GetRelationCounts implements GetNoteRelationCountsUseCase {
  Map<String, RelationCounts> counts = {};
  bool fail = false;
  @override
  Future<Either<Failure, Map<String, RelationCounts>>> call(List<String> ids, {bool cached = false}) async {
    if (fail) return const Left(Failure.errorFailure('boom'));
    return Right(counts);
  }
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
