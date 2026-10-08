import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/widgets/chat/bottom_read_mixin.dart';
import 'package:uniun/common/widgets/chat/boundary_chat_list.dart';
import 'package:uniun/common/widgets/chat/new_notes_divider.dart';
import 'package:uniun/common/widgets/chat/unread_count_cubit.dart';
import 'package:uniun/common/widgets/jump_to_bottom_button.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/data/models/followed_note_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';
import 'package:uniun/data/repositories/followed_note_repository_impl.dart';
import 'package:uniun/data/repositories/note_attachments_enricher.dart';
import 'package:uniun/data/repositories/note_relation_repository_impl.dart';
import 'package:uniun/data/repositories/note_resolver_repository_impl.dart';
import 'package:uniun/data/repositories/unread_repository_impl.dart';
import 'package:uniun/domain/usecases/followed_note_usecases.dart';
import 'package:uniun/domain/usecases/post_reply_usecase.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/domain/usecases/unread_usecases.dart';
import 'package:uniun/features/mesh/sync/mesh_event_signer.dart';
import 'package:uniun/features/thread/bloc/thread_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../_helpers/fixtures.dart';
import '../_helpers/isar_seeds.dart';
import '../_helpers/isar_test_harness.dart';
import '../_helpers/stub_user_repository.dart';

class _MockPostReply extends Mock implements PostReplyUseCase {}

class _MockGetProfile extends Mock implements GetProfileUseCase {}

class _MockGetAllSaved extends Mock implements GetAllSavedNotesUseCase {}

class _MockGetSavedReplies extends Mock implements GetSavedRepliesUseCase {}

class _MockGetSavedReferences extends Mock
    implements GetSavedReferencesUseCase {}

/// One group chat on screen: the real list, divider, jump button and read
/// marking, reading and writing the real unread table.
class _Chat extends StatefulWidget {
  const _Chat({
    required this.isar,
    required this.groupId,
    required this.boundary,
    required this.unread,
    this.allowMark = true,
    super.key,
  });
  final Isar isar;
  final String groupId;
  final DateTime? boundary;
  final bool allowMark;
  final UnreadCountCubit unread;

  @override
  State<_Chat> createState() => ChatState();
}

class ChatState extends State<_Chat> with BottomReadMixin {
  final controller = ScrollController();
  static ChatState? live;
  late final UnreadRepositoryImpl _repo;
  UnreadCountCubit get unread => widget.unread;
  List<NoteModel> notes = const [];
  bool showJump = false;
  int marks = 0;

  @override
  ScrollController get readScrollController => controller;
  @override
  bool get canMarkRead => widget.allowMark;

  @override
  void markContainerRead() {
    marks++;
    // Isar needs the real zone, not the widget test's fake-async one.
    Zone.root.run(() => MarkGroupSeenUseCase(_repo).call(widget.groupId));
  }

  @override
  void initState() {
    super.initState();
    _repo = UnreadRepositoryImpl(isar: widget.isar);
    live = this;
    controller.addListener(() {
      onReadScroll();
      final p = controller.position;
      final s = p.maxScrollExtent - p.pixels > kJumpToBottomTolerance;
      if (s != showJump) setState(() => showJump = s);
    });
  }

  /// Stands in for the bloc's database watch: reload the list from Isar.
  Future<void> reload() async {
    final all = await widget.isar.noteModels
        .filter()
        .groupIdEqualTo(widget.groupId)
        .sortByCreated()
        .findAll();
    if (mounted) setState(() => notes = all);
  }

  @override
  void dispose() {
    if (identical(live, this)) live = null;
    controller.dispose();
    super.dispose();
  }

  void jumpToLatest() {
    controller.jumpTo(controller.position.maxScrollExtent);
    markContainerRead();
  }

  @override
  Widget build(BuildContext context) {
    contentChanged(notes.length);
    final b = widget.boundary;
    final index = b == null
        ? notes.length
        : notes.indexWhere((n) => !n.created.isBefore(b));
    return Stack(
      children: [
        BoundaryChatList<NoteModel>(
          controller: controller,
          notes: notes,
          boundaryIndex: index < 0 ? notes.length : index,
          openedAtBoundary: b != null,
          unreadDivider: const NewNotesDivider(),
          itemBuilder: (_, n) => SizedBox(
            height: 90,
            child: Text(n.eventId, key: ValueKey(n.eventId)),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: BlocBuilder<UnreadCountCubit, int>(
            bloc: unread,
            builder: (_, n) => JumpToBottomButton(
              visible: showJump,
              unreadCount: n,
              onPressed: jumpToLatest,
            ),
          ),
        ),
      ],
    );
  }
}

/// End-to-end unread lifecycle on one real Isar: notes arrive through the
/// same projection writer the Gateway uses, the chat widgets read and mark
/// through the real repositories, and followed-note threads resolve through
/// the real resolver and edge table.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  WidgetTester? ioTester;
  final openCubits = <UnreadCountCubit>[];
  late UnreadRepositoryImpl unreadRepo;
  late FollowedNoteRepositoryImpl followed;
  const gid = 'g1';
  final t0 = DateTime.utc(2026, 3, 1, 9);

  setUp(() async {
    isar = await openTestIsar();
    unreadRepo = UnreadRepositoryImpl(isar: isar);
    followed = FollowedNoteRepositoryImpl(
      isar: isar,
      signer: MeshEventSigner(StubUserRepository()..keys = null),
    );
  });

  tearDown(() async {
    if (isar.isOpen) await isar.close(deleteFromDisk: true);
  });

  /// Isar needs real async: inside a widget test it must run under runAsync.
  Future<R> io<R>(Future<R> Function() f) async {
    final t = ioTester;
    if (t == null) return f();
    return (await t.runAsync(f)) as R;
  }

  /// A widget test whose Isar calls go through [io].
  void chatTest(String name, Future<void> Function(WidgetTester t) body) {
    testWidgets(name, (t) async {
      ioTester = t;
      try {
        await body(t);
      } finally {
        // Closing Isar needs real async too; the shared tearDown then skips it.
        await t.pumpWidget(const SizedBox.shrink());
        await t.runAsync(() async {
          for (final c in openCubits) {
            await c.close();
          }
          await isar.close(deleteFromDisk: true);
        });
        openCubits.clear();
        ioTester = null;
      }
    });
  }

  /// A note from someone else arriving over the wire, like the inbound
  /// handlers do it: the note and its unread row in one transaction.
  Future<void> arrive(
    String id, {
    String? groupId,
    String? privateGroupId,
    int? conversationId,
    int kind = kGroupMessageKind,
    DateTime? created,
    String? replyTo,
    String? root,
  }) async {
    final m = noteRow(
      id,
      kind: kind,
      groupId: groupId,
      privateGroupId: privateGroupId,
      conversationId: conversationId,
      created: created,
      replyToEventId: replyTo,
      rootEventId: root,
    );
    await io(() async {
      await isar.writeTxn(() async {
        await isar.noteModels.put(m);
        await putUnreadRowInTxn(isar, m);
      });
      await ChatState.live?.reload();
    });
  }

  /// A note that is already read (my own, or opened before).
  Future<void> existing(String id, {String? groupId, DateTime? created}) => io(
    () => isar.writeTxn(
      () => isar.noteModels.put(
        noteRow(
          id,
          kind: kGroupMessageKind,
          groupId: groupId,
          created: created,
        ),
      ),
    ),
  );

  Future<int> unreadCount([String? g]) => io(
    () => g == null
        ? isar.unreadNoteModels.count()
        : isar.unreadNoteModels.filter().groupIdEqualTo(g).count(),
  );

  Widget host(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(height: 600, child: child)),
  );

  /// One frame (marking runs inside it), real time for Isar and streams to
  /// answer, then frames to show the result.
  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await t.pump();
    await t.pump();
  }

  Future<ChatState> openChat(
    WidgetTester t, {
    bool allowMark = true,
    Key? key,
  }) async {
    final boundary = (await io(
      () => unreadRepo.oldestUnreadTimeForGroup(gid),
    )).getOrElse(() => null);
    final k = key ?? GlobalKey<ChatState>();
    final counter = await io(
      () async =>
          UnreadCountCubit(WatchGroupUnreadCountUseCase(unreadRepo).call(gid)),
    );
    openCubits.add(counter);
    await t.pumpWidget(
      host(
        _Chat(
          key: k,
          isar: isar,
          groupId: gid,
          boundary: boundary,
          unread: counter,
          allowMark: allowMark,
        ),
      ),
    );
    final chat = (k as GlobalKey<ChatState>).currentState!;
    await io(chat.reload);
    await settle(t);
    await settle(t);
    return chat;
  }

  // ── chat: group ───────────────────────────────────────────────────────────

  group('chat: opening and reading', () {
    chatTest('everything already read: opens at the newest, no dot, no '
        'divider, no badge', (t) async {
      for (var i = 0; i < 30; i++) {
        await existing(
          'n$i',
          groupId: gid,
          created: t0.add(Duration(minutes: i)),
        );
      }

      final chat = await openChat(t);

      expect(find.text('n29'), findsOneWidget);
      expect(find.byType(NewNotesDivider), findsNothing);
      expect(chat.unread.state, 0);
      expect(await unreadCount(), 0);
    });

    chatTest('unread in the middle: opens at the divider, dot stays until '
        'the user reaches the bottom, then clears', (t) async {
      for (var i = 0; i < 20; i++) {
        await existing(
          'old$i',
          groupId: gid,
          created: t0.add(Duration(minutes: i)),
        );
      }
      for (var i = 0; i < 12; i++) {
        await arrive(
          'new$i',
          groupId: gid,
          created: t0.add(Duration(hours: 1, minutes: i)),
        );
      }

      final chat = await openChat(t);

      expect(find.byType(NewNotesDivider), findsOneWidget);
      expect(
        find.text('new0'),
        findsOneWidget,
        reason: 'opens at first unread',
      );
      expect(chat.unread.state, 12);
      expect(chat.marks, 0, reason: 'not at the bottom yet');
      expect(await unreadCount(gid), 12);

      chat.controller.jumpTo(chat.controller.position.maxScrollExtent);
      await settle(t);

      expect(chat.marks, 1);
      expect(await unreadCount(gid), 0);
      expect(chat.unread.state, 0);
    });

    chatTest('a short chat that is all unread and fits the screen is read '
        'on open', (t) async {
      await arrive('a', groupId: gid, created: t0);
      await arrive(
        'b',
        groupId: gid,
        created: t0.add(const Duration(minutes: 1)),
      );

      final chat = await openChat(t);
      await settle(t);

      expect(await unreadCount(gid), 0);
      expect(chat.marks, greaterThanOrEqualTo(1));
    });

    chatTest('reading one group leaves other groups unread', (t) async {
      await arrive('a', groupId: gid, created: t0);
      await arrive('x', groupId: 'g2', created: t0);
      await arrive(
        'p',
        privateGroupId: 'pg',
        kind: kPrivateGroupKind,
        created: t0,
      );

      await openChat(t);
      await settle(t);

      expect(await unreadCount(gid), 0);
      expect(await unreadCount('g2'), 1);
      expect(
        await io(
          () => isar.unreadNoteModels
              .filter()
              .privateGroupIdEqualTo('pg')
              .count(),
        ),
        1,
      );
    });

    test('the same note delivered twice counts once', () async {
      final m = noteRow(
        'dup',
        kind: kGroupMessageKind,
        groupId: gid,
        created: t0,
      );
      for (var i = 0; i < 3; i++) {
        await isar.writeTxn(() async {
          await isar.noteModels.put(m);
          await putUnreadRowInTxn(isar, m);
        });
      }

      expect(await unreadCount(gid), 1);
    });

    chatTest('a note arriving while at the bottom is read at once', (t) async {
      for (var i = 0; i < 25; i++) {
        await existing(
          'n$i',
          groupId: gid,
          created: t0.add(Duration(minutes: i)),
        );
      }
      final chat = await openChat(t);
      chat.controller.jumpTo(chat.controller.position.maxScrollExtent);
      await settle(t);

      await arrive(
        'fresh',
        groupId: gid,
        created: t0.add(const Duration(days: 1)),
      );
      await settle(t);
      await settle(t);

      expect(await unreadCount(gid), 0);
      expect(chat.unread.state, 0);
    });

    chatTest('a note arriving while scrolled up stays unread and counts on '
        'the button; jumping clears it', (t) async {
      for (var i = 0; i < 40; i++) {
        await existing(
          'n$i',
          groupId: gid,
          created: t0.add(Duration(minutes: i)),
        );
      }
      final chat = await openChat(t);
      chat.controller.jumpTo(chat.controller.position.minScrollExtent);
      await settle(t);

      await arrive(
        'fresh1',
        groupId: gid,
        created: t0.add(const Duration(days: 1)),
      );
      await arrive(
        'fresh2',
        groupId: gid,
        created: t0.add(const Duration(days: 1, minutes: 1)),
      );
      await settle(t);

      expect(await unreadCount(gid), 2);
      expect(chat.unread.state, 2);
      expect(find.text('2'), findsOneWidget);

      chat.jumpToLatest();
      await settle(t);

      expect(await unreadCount(gid), 0);
      expect(chat.unread.state, 0);
    });

    chatTest('a note arriving while another page covers the chat is read '
        'only after the chat is back on top', (t) async {
      for (var i = 0; i < 25; i++) {
        await existing(
          'n$i',
          groupId: gid,
          created: t0.add(Duration(minutes: i)),
        );
      }
      final key = GlobalKey<ChatState>();
      final nav = GlobalKey<NavigatorState>();
      final counter = await io(
        () async => UnreadCountCubit(
          WatchGroupUnreadCountUseCase(unreadRepo).call(gid),
        ),
      );
      openCubits.add(counter);
      final boundary = (await io(
        () => unreadRepo.oldestUnreadTimeForGroup(gid),
      )).getOrElse(() => null);
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: _Chat(
                key: key,
                isar: isar,
                groupId: gid,
                boundary: boundary,
                unread: counter,
              ),
            ),
          ),
        ),
      );
      final chat = key.currentState!;
      await io(chat.reload);
      await settle(t);
      chat.controller.jumpTo(chat.controller.position.maxScrollExtent);
      await settle(t);
      expect(await unreadCount(gid), 0);

      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('thread')),
        ),
      );
      await t.pumpAndSettle();
      await arrive(
        'while-away',
        groupId: gid,
        created: t0.add(const Duration(days: 1)),
      );
      await settle(t);
      expect(await unreadCount(gid), 1, reason: 'covered: not read');

      nav.currentState!.pop();
      await t.pumpAndSettle();
      chat.scheduleBottomCheck();
      await settle(t);

      expect(await unreadCount(gid), 0);
    });

    chatTest('a chat not allowed to mark (newer unread still loading) keeps '
        'its dot', (t) async {
      await arrive('a', groupId: gid, created: t0);

      final chat = await openChat(t, allowMark: false);
      await settle(t);

      expect(chat.marks, 0);
      expect(await unreadCount(gid), 1);
    });

    chatTest('an empty chat opens without error', (t) async {
      final chat = await openChat(t);

      expect(chat.unread.state, 0);
      expect(t.takeException(), isNull);
    });

    chatTest('unicode and very long ids do not break marking', (t) async {
      final long = 'é😀' * 200;
      await arrive(long, groupId: gid, created: t0);
      await arrive(
        'مرحبا',
        groupId: gid,
        created: t0.add(const Duration(minutes: 1)),
      );

      await openChat(t);
      await settle(t);

      expect(await unreadCount(gid), 0);
    });
  });

  // ── counts and boundaries for DMs and private groups ─────────────────────

  group('counts and open position for DMs and private groups', () {
    test('a DM boundary and count follow reading', () async {
      await seedDmConversation(isar, kAlicePub);
      final conv = DmId.of(kAlicePub);
      await arrive('d1', conversationId: conv, kind: kDmTextKind, created: t0);
      await arrive(
        'd2',
        conversationId: conv,
        kind: kDmTextKind,
        created: t0.add(const Duration(hours: 1)),
      );

      expect(await unreadRepo.watchDmUnreadCount(kAlicePub).first, 2);
      expect(
        (await unreadRepo.oldestUnreadTimeForDm(
          kAlicePub,
        )).getOrElse(() => null)!.toUtc(),
        t0,
      );

      await unreadRepo.markConversationSeen(conv);

      expect(await unreadRepo.watchDmUnreadCount(kAlicePub).first, 0);
      expect(
        (await unreadRepo.oldestUnreadTimeForDm(
          kAlicePub,
        )).getOrElse(() => DateTime(1)),
        isNull,
      );
    });

    test('a private group boundary and count follow reading', () async {
      await arrive(
        'p1',
        privateGroupId: 'pg',
        kind: kPrivateGroupKind,
        created: t0,
      );
      await arrive(
        'p2',
        privateGroupId: 'pg',
        kind: kPrivateGroupKind,
        created: t0.add(const Duration(hours: 2)),
      );

      expect(await unreadRepo.watchPrivateGroupUnreadCount('pg').first, 2);

      await unreadRepo.markPrivateGroupSeen('pg');

      expect(await unreadRepo.watchPrivateGroupUnreadCount('pg').first, 0);
    });

    test(
      'a DM from a stranger with no conversation row yet counts as 0',
      () async {
        expect(await unreadRepo.watchDmUnreadCount('nobody').first, 0);
        expect(
          (await unreadRepo.oldestUnreadTimeForDm(
            'nobody',
          )).getOrElse(() => DateTime(1)),
          isNull,
        );
      },
    );
  });

  // ── followed note: nested replies ────────────────────────────────────────

  group('followed note: nested reply trail', () {
    late ThreadBloc Function() buildThread;

    setUp(() {
      final relations = NoteRelationRepositoryImpl(isar: isar);
      final resolver = NoteResolverRepositoryImpl(
        isar: isar,
        relations: relations,
        attachments: NoteAttachmentsEnricher(isar: isar),
      );
      final getProfile = _MockGetProfile();
      when(
        () => getProfile.call(any()),
      ).thenAnswer((_) async => const Left(Failure.errorFailure('none')));
      final getAllSaved = _MockGetAllSaved();
      when(() => getAllSaved.call()).thenAnswer((_) async => const Right([]));
      final replies = _MockGetSavedReplies();
      when(() => replies.call(any())).thenAnswer((_) async => const Right([]));
      final refs = _MockGetSavedReferences();
      when(() => refs.call(any())).thenAnswer((_) async => const Right([]));
      buildThread = () => ThreadBloc(
        resolver,
        _MockPostReply(),
        getProfile,
        getAllSaved,
        replies,
        refs,
        MarkUnreadSeenUseCase(unreadRepo),
        WatchThreadUnreadMarkersUseCase(followed),
      );
    });

    /// root → r1 → r2 → r3, all from others; only r3 is new.
    Future<void> story({bool follow = true}) async {
      if (follow) await followed.followNote('root', 'Launch checklist');
      await existing('root', created: t0);
      await existing('r1', created: t0.add(const Duration(minutes: 1)));
      await existing('r2', created: t0.add(const Duration(minutes: 2)));
      await arrive(
        'r3',
        replyTo: 'r2',
        root: 'root',
        kind: kNoteKind,
        created: t0.add(const Duration(minutes: 3)),
      );
      await seedRelationEdge(isar, 'root', 'r1');
      await seedRelationEdge(isar, 'r1', 'r2');
      await seedRelationEdge(isar, 'r2', 'r3');
    }

    Future<ThreadBloc> open(String id) async {
      final bloc = buildThread()..add(LoadThreadEvent(id));
      await bloc.stream.firstWhere((s) => s.status == ThreadStatus.loaded);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      return bloc;
    }

    test('SCENARIO: a new reply three levels deep leaves a trail from the '
        'followed note down to it, and is read only when opened', () async {
      await story();

      // Drawer badge counts the nested reply.
      var list = (await followed.getAll()).getOrElse(() => throw 'x');
      expect(list.single.newReferenceCount, 1);

      // Followed note's thread: r1 shows "new reply inside". r3 is NOT read
      // just because the parent was viewed.
      var bloc = await open('root');
      expect(bloc.state.unreadMarkers['r1']!.unreadInside, isTrue);
      expect(bloc.state.unreadMarkers['r1']!.unread, isFalse);
      await bloc.close();
      expect(
        await isar.unreadNoteModels.filter().eventIdEqualTo('r3').count(),
        1,
      );

      // r1's thread: r2 shows the trail.
      bloc = await open('r1');
      expect(bloc.state.unreadMarkers['r2']!.unreadInside, isTrue);
      await bloc.close();
      expect(
        await isar.unreadNoteModels.filter().eventIdEqualTo('r3').count(),
        1,
      );

      // r2's thread: r3 itself carries the dot.
      bloc = await open('r2');
      expect(bloc.state.unreadMarkers['r3']!.unread, isTrue);
      await bloc.close();
      expect(
        await isar.unreadNoteModels.filter().eventIdEqualTo('r3').count(),
        1,
      );

      // Opening r3 reads it; every trail and the drawer badge clear.
      bloc = await open('r3');
      await bloc.close();
      expect(await unreadCount(), 0);
      list = (await followed.getAll()).getOrElse(() => throw 'x');
      expect(list.single.newReferenceCount, 0);
      bloc = await open('root');
      expect(bloc.state.unreadMarkers, isEmpty);
      await bloc.close();
    });

    test('a thread outside any followed note shows no dots', () async {
      await story(follow: false);

      final bloc = await open('root');

      expect(bloc.state.unreadMarkers, isEmpty);
      await bloc.close();
    });

    test('unfollowing removes the trail but keeps the note unread', () async {
      await story();
      await followed.unfollowNote('root');

      final bloc = await open('root');

      expect(bloc.state.unreadMarkers, isEmpty);
      await bloc.close();
      expect(await unreadCount(), 1);
    });

    test(
      'a new reply arriving while the thread is open appears live',
      () async {
        await story();
        final bloc = await open('r2');
        expect(bloc.state.unreadMarkers.keys, contains('r3'));

        await arrive(
          'r4',
          replyTo: 'r2',
          root: 'root',
          kind: kNoteKind,
          created: t0.add(const Duration(minutes: 9)),
        );
        await seedRelationEdge(isar, 'r2', 'r4');
        // The thread list itself reloads on a new load; markers are live.
        bloc.add(const LoadThreadEvent('r2'));
        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(bloc.state.unreadMarkers.keys, containsAll(['r3', 'r4']));
        await bloc.close();
      },
    );

    test('opening a note that was never unread is harmless', () async {
      await story();
      await existing('plain', created: t0);

      final bloc = await open('plain');
      await bloc.close();

      expect(await unreadCount(), 1);
    });

    test('a 300-deep reply chain is counted without blowing up', () async {
      await followed.followNote('c0', 'deep');
      for (var i = 0; i < 300; i++) {
        await seedRelationEdge(isar, 'c$i', 'c${i + 1}');
      }
      await arrive('c300', kind: kNoteKind, created: t0);

      final sw = Stopwatch()..start();
      final list = (await followed.getAll()).getOrElse(() => throw 'x');

      expect(list.single.newReferenceCount, 1);
      expect(sw.elapsed, lessThan(const Duration(seconds: 10)));
    });

    test('300 siblings are all counted', () async {
      await followed.followNote('root', 'wide');
      for (var i = 0; i < 300; i++) {
        await seedRelationEdge(isar, 'root', 's$i');
        await arrive(
          's$i',
          kind: kNoteKind,
          created: t0.add(Duration(seconds: i)),
        );
      }

      final list = (await followed.getAll()).getOrElse(() => throw 'x');

      expect(list.single.newReferenceCount, 300);
    });

    test('two followed notes sharing a reply both count it, and one read '
        'clears both', () async {
      await followed.followNote('a', 'a');
      await followed.followNote('b', 'b');
      await seedRelationEdge(isar, 'a', 'shared');
      await seedRelationEdge(isar, 'b', 'shared');
      await arrive('shared', kind: kNoteKind, created: t0);

      var list = (await followed.getAll()).getOrElse(() => throw 'x');
      expect(list.map((f) => f.newReferenceCount), [1, 1]);

      await unreadRepo.markSeen('shared');

      list = (await followed.getAll()).getOrElse(() => throw 'x');
      expect(list.map((f) => f.newReferenceCount), [0, 0]);
    });

    test('a removed (unfollowed) note row is not tracked', () async {
      await followed.followNote('root', 'x');
      await followed.unfollowNote('root');
      await seedRelationEdge(isar, 'root', 'r1');
      await arrive('r1', kind: kNoteKind, created: t0);

      final markers = await followed.watchThreadUnreadMarkers([
        'root',
        'r1',
      ]).first;

      expect(markers, isEmpty);
      expect(await isar.followedNoteModels.count(), greaterThanOrEqualTo(0));
    });
  });
}

/// Same hashing the DM conversation row uses for its id.
class DmId {
  static int of(String otherPubkey) => dmConversationRow(otherPubkey).id;
}
