import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:uniun/common/widgets/chat/new_notes_divider.dart';
import 'package:uniun/common/widgets/drop_loading_indicator.dart';
import 'package:uniun/common/widgets/jump_to_bottom_button.dart';
import 'package:uniun/common/widgets/note_card/cubit/note_card_cubit.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/common/widgets/note_card/note_card.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/repositories/dm_conversation_repository.dart';
import 'package:uniun/domain/usecases/unread_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/features/dm/chat/bloc/dm_chat_bloc.dart';
import 'package:uniun/features/dm/chat/pages/dm_chat_page.dart';
import 'package:uniun/features/shiv/composer_chat/cubit/composer_chat_cubit.dart';
import 'package:uniun/features/shiv/composer_chat/cubit/composer_chat_state.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../../../../_helpers/fixtures.dart';

class _MockDmBloc extends MockBloc<DmChatEvent, DmChatState>
    implements DmChatBloc {}

class _MockNoteCardCubit extends MockCubit<NoteCardState>
    implements NoteCardCubit {}

class _MockComposerChat extends MockCubit<ComposerChatState>
    implements ComposerChatCubit {}

class _MockActiveProfile extends Mock implements GetActiveUserProfileUseCase {}

class _MockWatchCount extends Mock implements WatchDmUnreadCountUseCase {}

class _MockOldest extends Mock implements GetDmOldestUnreadTimeUseCase {}

class _MockDmRepo extends Mock implements DmConversationRepository {}

/// Covers: the DM page marking the conversation read at the newest note,
/// opening at the first unread under the New notes divider, the unread count
/// on the jump button, and waiting for the boundary before drawing.
void main() {
  const pub = 'ab';
  late _MockDmBloc bloc;
  late _MockOldest oldest;
  late StreamController<int> counts;
  final t0 = DateTime.utc(2026, 3, 1, 9);

  List<NoteEntity> notes(int n) => [
    // Newest first, like the bloc delivers them.
    for (var i = n - 1; i >= 0; i--)
      aNote(
        id: 'm$i',
        content: 'message $i',
        created: t0.add(Duration(minutes: i)),
      ),
  ];

  setUpAll(() {
    registerFallbackValue(DmChatMarkAllSeenEvent());
    // No 500 ms visibility timer left pending at the end of a test.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  setUp(() async {
    bloc = _MockDmBloc();
    oldest = _MockOldest();
    counts = StreamController<int>.broadcast();
    when(
      () => oldest.call(any()),
    ).thenAnswer((_) async => const Right<Failure, DateTime?>(null));
    final card = _MockNoteCardCubit();
    when(() => card.state).thenReturn(const NoteCardState());
    when(() => card.note).thenReturn(aNote(id: 'x'));
    final chat = _MockComposerChat();
    when(() => chat.state).thenReturn(const ComposerChatState());
    when(() => chat.close()).thenAnswer((_) async {});
    final profile = _MockActiveProfile();
    when(
      () => profile.call(),
    ).thenAnswer((_) async => const Left(Failure.errorFailure('none')));
    final watch = _MockWatchCount();
    when(() => watch.call(any())).thenAnswer((_) => counts.stream);
    final repo = _MockDmRepo();
    when(
      () => repo.getConversationByOtherPubkey(any()),
    ).thenAnswer((_) async => const Left(Failure.errorFailure('none')));
    await GetIt.instance.reset();
    GetIt.instance
      ..registerFactory<DmChatBloc>(() => bloc)
      ..registerFactoryParam<NoteCardCubit, NoteEntity, void>((_, __) => card)
      ..registerFactory<ComposerChatCubit>(() => chat)
      ..registerFactory<GetActiveUserProfileUseCase>(() => profile)
      ..registerFactory<WatchDmUnreadCountUseCase>(() => watch)
      ..registerFactory<GetDmOldestUnreadTimeUseCase>(() => oldest)
      ..registerFactory<DmConversationRepository>(() => repo);
  });

  tearDown(() async {
    await counts.close();
    await GetIt.instance.reset();
  });

  Future<void> open(WidgetTester t, List<NoteEntity> messages) async {
    when(
      () => bloc.state,
    ).thenReturn(DmChatState(otherPubkey: pub, messages: messages));
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DmChatPage(otherPubkey: pub),
      ),
    );
    await t.pump();
    await t.pump();
    await t.pump();
  }

  int markAllCalls() => verify(
    () => bloc.add(any(that: isA<DmChatMarkAllSeenEvent>())),
  ).callCount;

  testWidgets('everything read: opens at the newest and marks the chat read', (
    t,
  ) async {
    await open(t, notes(25));

    expect(find.byType(NewNotesDivider), findsNothing);
    expect(markAllCalls(), greaterThanOrEqualTo(1));
  });

  testWidgets('a short conversation that fits the screen is marked read', (
    t,
  ) async {
    await open(t, notes(2));

    expect(markAllCalls(), greaterThanOrEqualTo(1));
  });

  testWidgets('with unread notes it opens at the divider and does not mark '
      'read yet', (t) async {
    when(() => oldest.call(any())).thenAnswer(
      (_) async =>
          Right<Failure, DateTime?>(t0.add(const Duration(minutes: 10))),
    );

    await open(t, notes(40));

    expect(find.byType(NewNotesDivider), findsOneWidget);
    expect(find.text('New notes'), findsOneWidget);
    verifyNever(() => bloc.add(any(that: isA<DmChatMarkAllSeenEvent>())));
  });

  testWidgets('scrolling to the newest note marks the chat read', (t) async {
    when(() => oldest.call(any())).thenAnswer(
      (_) async =>
          Right<Failure, DateTime?>(t0.add(const Duration(minutes: 10))),
    );
    await open(t, notes(40));
    verifyNever(() => bloc.add(any(that: isA<DmChatMarkAllSeenEvent>())));

    for (var i = 0; i < 12; i++) {
      await t.fling(
        find.byType(Scrollable).first,
        const Offset(0, -2000),
        5000,
      );
      await t.pump(const Duration(milliseconds: 300));
    }

    expect(markAllCalls(), greaterThanOrEqualTo(1));
  });

  testWidgets('the jump button shows how many notes are unread', (t) async {
    when(() => oldest.call(any())).thenAnswer(
      (_) async =>
          Right<Failure, DateTime?>(t0.add(const Duration(minutes: 10))),
    );
    await open(t, notes(40));

    counts.add(7);
    await t.pump();
    await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await t.pump();

    expect(find.text('7'), findsOneWidget);
    expect(find.byType(JumpToBottomButton), findsOneWidget);
  });

  testWidgets('nothing is drawn until the unread boundary is known', (t) async {
    final gate = Completer<Either<Failure, DateTime?>>();
    when(() => oldest.call(any())).thenAnswer((_) => gate.future);

    await open(t, notes(5));
    expect(find.byType(DropLoadingIndicator), findsWidgets);
    expect(find.text('message 0'), findsNothing);

    gate.complete(const Right(null));
    await t.pump();
    await t.pump();

    expect(find.byType(DropLoadingIndicator), findsNothing);
  });

  testWidgets('an empty conversation is not marked and does not throw', (
    t,
  ) async {
    await open(t, const []);

    verifyNever(() => bloc.add(any(that: isA<DmChatMarkAllSeenEvent>())));
    expect(t.takeException(), isNull);
  });

  testWidgets('leaving the page cancels the count subscription', (t) async {
    await open(t, notes(3));
    expect(counts.hasListener, isTrue);

    await t.pumpWidget(const SizedBox());

    expect(counts.hasListener, isFalse);
  });

  testWidgets('tapping the jump button scrolls to the newest and marks read', (
    t,
  ) async {
    when(() => oldest.call(any())).thenAnswer(
      (_) async =>
          Right<Failure, DateTime?>(t0.add(const Duration(minutes: 10))),
    );
    await open(t, notes(40));
    counts.add(4);
    await t.pump();
    await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await t.pump();

    await t.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await t.pump(const Duration(milliseconds: 400));

    expect(markAllCalls(), greaterThanOrEqualTo(1));
  });

  testWidgets('coming back from a thread marks notes that arrived meanwhile', (
    t,
  ) async {
    final states = StreamController<DmChatState>.broadcast();
    DmChatState state(int n) =>
        DmChatState(otherPubkey: pub, messages: notes(n));
    when(() => bloc.state).thenReturn(state(3));
    whenListen(bloc, states.stream, initialState: state(3));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const DmChatPage(otherPubkey: pub),
        ),
        GoRoute(
          path: '/thread/:noteId',
          name: AppRoutes.thread,
          builder: (ctx, __) => Scaffold(
            body: TextButton(
              onPressed: () => ctx.pop(),
              child: const Text('back'),
            ),
          ),
        ),
      ],
    );
    await t.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    for (var i = 0; i < 4; i++) {
      await t.pump();
    }
    clearInteractions(bloc);

    await t.tap(find.byType(NoteCard).first);
    await t.pumpAndSettle();
    expect(find.text('back'), findsOneWidget);
    when(() => bloc.state).thenReturn(state(4));
    states.add(state(4));
    await t.pump();
    await t.tap(find.text('back'));
    await t.pumpAndSettle();
    await t.pump();

    expect(markAllCalls(), greaterThanOrEqualTo(1));
    await states.close();
  });
}
