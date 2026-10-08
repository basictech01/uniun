import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/widgets/chat/new_notes_divider.dart';
import 'package:uniun/common/widgets/note_card/cubit/note_card_cubit.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/common/widgets/note_card/note_card.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/usecases/create_group_message_usecase.dart';
import 'package:uniun/domain/usecases/get_group_by_id_usecase.dart';
import 'package:uniun/domain/usecases/get_group_messages_usecase.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/domain/usecases/unread_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/features/groups/feed/pages/group_feed_page.dart';
import 'package:uniun/features/shiv/composer_chat/cubit/composer_chat_cubit.dart';
import 'package:uniun/features/shiv/composer_chat/cubit/composer_chat_state.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../_helpers/fixtures.dart';

class _MockGetGroupById extends Mock implements GetGroupByIdUseCase {}

class _MockOldest extends Mock implements GetGroupOldestUnreadTimeUseCase {}

class _MockMessages extends Mock implements GetGroupMessagesUseCase {}

class _MockAfter extends Mock implements GetGroupMessagesAfterUseCase {}

class _MockKeys extends Mock implements GetActiveUserKeysUseCase {}

class _MockCreate extends Mock implements CreateGroupMessageUseCase {}

class _MockSave extends Mock implements SaveNoteUseCase {}

class _MockUnsave extends Mock implements UnsaveNoteUseCase {}

class _MockProfile extends Mock implements GetProfileUseCase {}

class _MockIsSaved extends Mock implements IsSavedNoteUseCase {}

class _MockMarkOne extends Mock implements MarkUnreadSeenUseCase {}

class _MockMarkGroup extends Mock implements MarkGroupSeenUseCase {}

class _MockWatch extends Mock implements WatchGroupUnreadCountUseCase {}

class _MockActive extends Mock implements GetActiveUserProfileUseCase {}

class _MockNoteCardCubit extends MockCubit<NoteCardState>
    implements NoteCardCubit {}

class _MockComposerChat extends MockCubit<ComposerChatState>
    implements ComposerChatCubit {}

/// Covers: the group page marking the group read at the newest note, opening
/// at the first unread under the New notes divider, pulling in and reading a
/// note that arrives while the user is at the bottom, leaving one that arrives
/// while scrolled up, the jump button, and cleaning up its subscription.
void main() {
  const gid = 'g1';
  final t0 = DateTime.utc(2026, 3, 1, 9);
  late _MockGetGroupById byId;
  late _MockOldest oldest;
  late _MockMessages messages;
  late _MockAfter after;
  late _MockMarkGroup markGroup;
  late StreamController<int> counts;

  NoteEntity msg(int i) => aGroupMessage(
    groupId: gid,
    id: 'm$i',
    content: 'message $i',
    created: t0.add(Duration(minutes: i)),
  );

  setUpAll(() {
    registerFallbackValue(const GetGroupMessagesInput(groupId: ''));
    registerFallbackValue(
      GetGroupMessagesAfterInput(groupId: '', after: DateTime(2026)),
    );
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  setUp(() async {
    byId = _MockGetGroupById();
    oldest = _MockOldest();
    messages = _MockMessages();
    after = _MockAfter();
    markGroup = _MockMarkGroup();
    counts = StreamController<int>.broadcast();
    when(
      () => byId.call(gid),
    ).thenAnswer((_) async => Right(aGroup(groupId: gid)));
    when(() => oldest.call(gid)).thenAnswer((_) async => const Right(null));
    when(() => messages.call(any())).thenAnswer((_) async => const Right([]));
    when(() => after.call(any())).thenAnswer((_) async => const Right([]));
    when(
      () => markGroup.call(any()),
    ).thenAnswer((_) async => const Right(unit));
    final profile = _MockProfile();
    when(
      () => profile.call(any()),
    ).thenAnswer((_) async => const Left(Failure.errorFailure('none')));
    final isSaved = _MockIsSaved();
    when(() => isSaved.call(any())).thenAnswer((_) async => const Right(false));
    final markOne = _MockMarkOne();
    when(() => markOne.call(any())).thenAnswer((_) async => const Right(unit));
    final watch = _MockWatch();
    when(() => watch.call(any())).thenAnswer((_) => counts.stream);
    final active = _MockActive();
    when(
      () => active.call(),
    ).thenAnswer((_) async => const Left(Failure.errorFailure('none')));
    final card = _MockNoteCardCubit();
    when(() => card.state).thenReturn(const NoteCardState());
    when(() => card.note).thenReturn(aNote(id: 'x'));
    final chat = _MockComposerChat();
    when(() => chat.state).thenReturn(const ComposerChatState());
    when(() => chat.close()).thenAnswer((_) async {});
    await GetIt.instance.reset();
    GetIt.instance
      ..registerFactory<GetGroupByIdUseCase>(() => byId)
      ..registerFactory<GetGroupOldestUnreadTimeUseCase>(() => oldest)
      ..registerFactory<GetGroupMessagesUseCase>(() => messages)
      ..registerFactory<GetGroupMessagesAfterUseCase>(() => after)
      ..registerFactory<GetActiveUserKeysUseCase>(() => _MockKeys())
      ..registerFactory<CreateGroupMessageUseCase>(() => _MockCreate())
      ..registerFactory<SaveNoteUseCase>(() => _MockSave())
      ..registerFactory<UnsaveNoteUseCase>(() => _MockUnsave())
      ..registerFactory<GetProfileUseCase>(() => profile)
      ..registerFactory<IsSavedNoteUseCase>(() => isSaved)
      ..registerFactory<MarkUnreadSeenUseCase>(() => markOne)
      ..registerFactory<MarkGroupSeenUseCase>(() => markGroup)
      ..registerFactory<WatchGroupUnreadCountUseCase>(() => watch)
      ..registerFactory<GetActiveUserProfileUseCase>(() => active)
      ..registerFactoryParam<NoteCardCubit, NoteEntity, void>((_, __) => card)
      ..registerFactory<ComposerChatCubit>(() => chat);
  });

  tearDown(() async {
    await counts.close();
    await GetIt.instance.reset();
  });

  /// The read page returned newest first, as the use case does.
  void readNotes(int n) {
    when(
      () => messages.call(any()),
    ).thenAnswer((_) async => Right([for (var i = n - 1; i >= 0; i--) msg(i)]));
  }

  Future<void> open(WidgetTester t) async {
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GroupFeedPage(groupId: gid),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> flingToEnd(WidgetTester t) async {
    for (var i = 0; i < 12; i++) {
      await t.fling(
        find.byType(Scrollable).first,
        const Offset(0, -2000),
        5000,
      );
      await t.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('everything read: opens at the newest and marks the group read', (
    t,
  ) async {
    readNotes(25);

    await open(t);

    expect(find.byType(NewNotesDivider), findsNothing);
    verify(() => markGroup.call(gid)).called(greaterThanOrEqualTo(1));
  });

  testWidgets('a short group that fits the screen is marked read', (t) async {
    readNotes(2);

    await open(t);

    verify(() => markGroup.call(gid)).called(greaterThanOrEqualTo(1));
  });

  testWidgets('with unread notes it opens at the divider and is not read yet', (
    t,
  ) async {
    final boundary = t0.add(const Duration(minutes: 20));
    when(() => oldest.call(gid)).thenAnswer((_) async => Right(boundary));
    when(
      () => messages.call(any()),
    ).thenAnswer((_) async => Right([for (var i = 19; i >= 0; i--) msg(i)]));
    when(
      () => after.call(any()),
    ).thenAnswer((_) async => Right([for (var i = 20; i < 40; i++) msg(i)]));

    await open(t);

    expect(find.byType(NewNotesDivider), findsOneWidget);
    verifyNever(() => markGroup.call(any()));
  });

  testWidgets('scrolling to the newest note marks the group read', (t) async {
    final boundary = t0.add(const Duration(minutes: 20));
    when(() => oldest.call(gid)).thenAnswer((_) async => Right(boundary));
    when(
      () => messages.call(any()),
    ).thenAnswer((_) async => Right([for (var i = 19; i >= 0; i--) msg(i)]));
    when(
      () => after.call(any()),
    ).thenAnswer((_) async => Right([for (var i = 20; i < 30; i++) msg(i)]));
    await open(t);

    await flingToEnd(t);

    verify(() => markGroup.call(gid)).called(greaterThanOrEqualTo(1));
  });

  testWidgets('a note arriving while at the bottom is pulled in and read', (
    t,
  ) async {
    readNotes(25);
    await open(t);
    clearInteractions(markGroup);
    var pulled = false;
    when(() => after.call(any())).thenAnswer((_) async {
      pulled = true;
      return Right([msg(24), msg(25)]);
    });

    counts.add(1);
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }

    expect(pulled, isTrue, reason: 'asked for the newer note');
    verify(() => markGroup.call(gid)).called(greaterThanOrEqualTo(1));
  });

  testWidgets('a note arriving while scrolled up is not pulled in; the badge '
      'counts it', (t) async {
    final boundary = t0.add(const Duration(minutes: 20));
    when(() => oldest.call(gid)).thenAnswer((_) async => Right(boundary));
    when(
      () => messages.call(any()),
    ).thenAnswer((_) async => Right([for (var i = 19; i >= 0; i--) msg(i)]));
    when(
      () => after.call(any()),
    ).thenAnswer((_) async => Right([for (var i = 20; i < 40; i++) msg(i)]));
    await open(t);
    await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await t.pump();
    clearInteractions(after);

    counts.add(3);
    await t.pump(const Duration(milliseconds: 200));

    verifyNever(() => after.call(any()));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('the jump button asks for newer notes before scrolling', (
    t,
  ) async {
    final boundary = t0.add(const Duration(minutes: 20));
    when(() => oldest.call(gid)).thenAnswer((_) async => Right(boundary));
    when(
      () => messages.call(any()),
    ).thenAnswer((_) async => Right([for (var i = 19; i >= 0; i--) msg(i)]));
    when(
      () => after.call(any()),
    ).thenAnswer((_) async => Right([for (var i = 20; i < 40; i++) msg(i)]));
    await open(t);
    await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await t.pump();
    counts.add(2);
    await t.pump();
    clearInteractions(after);

    await t.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await t.pump(const Duration(milliseconds: 400));

    verify(() => after.call(any())).called(greaterThanOrEqualTo(1));
  });

  testWidgets('leaving the page cancels the count subscription', (t) async {
    readNotes(3);
    await open(t);
    expect(counts.hasListener, isTrue);

    await t.pumpWidget(const SizedBox());

    expect(counts.hasListener, isFalse);
  });

  testWidgets('a group that cannot be found shows an error, not a crash', (
    t,
  ) async {
    when(
      () => byId.call(gid),
    ).thenAnswer((_) async => const Left(Failure.errorFailure('missing')));

    await open(t);

    expect(find.text('Group not found.'), findsOneWidget);
    verifyNever(() => markGroup.call(any()));
  });

  testWidgets('coming back from a thread pulls in what arrived meanwhile and '
      'marks it read', (t) async {
    readNotes(3);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const GroupFeedPage(groupId: gid),
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
      await t.pump(const Duration(milliseconds: 50));
    }
    await t.tap(find.byType(NoteCard).first);
    await t.pumpAndSettle();
    clearInteractions(after);
    clearInteractions(markGroup);
    when(() => after.call(any())).thenAnswer((_) async => Right([msg(3)]));

    await t.tap(find.text('back'));
    await t.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }

    verify(() => after.call(any())).called(greaterThanOrEqualTo(1));
  });
}
