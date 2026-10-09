import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/widgets/note_card/cubit/note_card_cubit.dart';
import 'package:uniun/common/widgets/thread/message_thread_page.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/followed_note/thread_unread_marker.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/features/shiv/composer_chat/cubit/composer_chat_cubit.dart';
import 'package:uniun/features/shiv/composer_chat/cubit/composer_chat_state.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../../../_helpers/fixtures.dart';

class _MockNoteCardCubit extends MockCubit<NoteCardState>
    implements NoteCardCubit {}

class _MockComposerChat extends MockCubit<ComposerChatState>
    implements ComposerChatCubit {}

class _MockActiveProfile extends Mock implements GetActiveUserProfileUseCase {}

/// Covers: MessageThreadPage handing the followed-note markers to the thread
/// body, with and without markers.
void main() {
  setUp(() async {
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
    await GetIt.instance.reset();
    GetIt.instance
      ..registerFactoryParam<NoteCardCubit, NoteEntity, void>((_, __) => card)
      ..registerFactory<ComposerChatCubit>(() => chat)
      ..registerFactory<GetActiveUserProfileUseCase>(() => profile);
  });

  tearDown(() => GetIt.instance.reset());

  Widget host(Map<String, ThreadUnreadMarker> markers) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MessageThreadPage(
      root: aNote(id: 'root'),
      profiles: const {},
      replies: [
        aNote(id: 'r1'),
        aNote(id: 'r2'),
      ],
      unreadMarkers: markers,
      onSendReply: (_, __, ___) {},
      onOpenThread: (_) {},
    ),
  );

  testWidgets('the markers reach the replies', (t) async {
    await t.pumpWidget(
      host(const {'r2': ThreadUnreadMarker(unread: true, unreadInside: false)}),
    );
    await t.pump();

    expect(find.text('New'), findsOneWidget);
  });

  testWidgets('without markers no trail is drawn', (t) async {
    await t.pumpWidget(host(const {}));
    await t.pump();

    expect(find.text('New'), findsNothing);
    expect(find.text('New reply inside'), findsNothing);
  });
}
