import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/data/models/dm/dm_conversation_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/domain/usecases/dm_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/unread_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/features/dm/chat/bloc/dm_chat_bloc.dart';

import '../../../../_helpers/fixtures.dart';
import '../../../../_helpers/isar_test_harness.dart';

class _MockFetchDm extends Mock implements FetchDmUseCase {}

class _MockSendDm extends Mock implements SendDmUseCase {}

class _MockGetDm extends Mock implements GetDmUseCase {}

class _MockGetProfile extends Mock implements GetProfileUseCase {}

class _MockGetActiveUserProfile extends Mock
    implements GetActiveUserProfileUseCase {}

class _MockMarkUnreadSeen extends Mock implements MarkUnreadSeenUseCase {}

class _MockMarkConversationSeen extends Mock
    implements MarkConversationSeenUseCase {}

/// Covers: DmChatBloc's load (profile hydration for both self + peer,
/// error/exception paths), send (the empty-content+no-attachments guard,
/// the reply-embed path, image-vs-text type detection, success clearing
/// the reply context, both failure paths), refresh (drains the queue then
/// reloads), the once-per-session mark-seen guard, and mark-all-seen's
/// conversation lookup.
void main() {
  late _MockFetchDm fetchDm;
  late _MockSendDm sendDm;
  late _MockGetDm getDm;
  late _MockGetProfile getProfile;
  late _MockGetActiveUserProfile getActiveUserProfile;
  late _MockMarkUnreadSeen markUnreadSeen;
  late _MockMarkConversationSeen markConversationSeen;
  late Isar isar;

  DmChatBloc build() => DmChatBloc(
        fetchDm,
        sendDm,
        getDm,
        getProfile,
        getActiveUserProfile,
        markUnreadSeen,
        markConversationSeen,
        isar,
      );

  setUpAll(() {
    registerFallbackValue(SendDmParams(otherPubkey: '', content: ''));
  });

  setUp(() async {
    isar = await openTestIsar();
    fetchDm = _MockFetchDm();
    sendDm = _MockSendDm();
    getDm = _MockGetDm();
    getProfile = _MockGetProfile();
    getActiveUserProfile = _MockGetActiveUserProfile();
    markUnreadSeen = _MockMarkUnreadSeen();
    markConversationSeen = _MockMarkConversationSeen();

    when(() => fetchDm.call(any())).thenAnswer((_) async => const Right([]));
    when(() => getActiveUserProfile.call())
        .thenAnswer((_) async => const Left(Failure.errorFailure('no active user')));
    when(() => getProfile.call(any()))
        .thenAnswer((_) async => const Left(Failure.errorFailure('not found')));
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('DmChatLoadEvent', () {
    blocTest<DmChatBloc, DmChatState>(
      'loads messages and hydrates profiles for both self and the peer',
      build: () {
        when(() => fetchDm.call('peer')).thenAnswer((_) async => Right([aDmText(conversationId: 1)]));
        when(() => getActiveUserProfile.call())
            .thenAnswer((_) async => const Right(ActiveUserProfile(pubkeyHex: 'self-pub')));
        when(() => getProfile.call('peer')).thenAnswer((_) async => Right(aProfile(pubkey: 'peer')));
        when(() => getProfile.call('self-pub')).thenAnswer((_) async => Right(aProfile(pubkey: 'self-pub')));
        return build();
      },
      act: (b) => b.add(DmChatLoadEvent(otherPubkey: 'peer')),
      verify: (b) {
        expect(b.state.isLoading, isFalse);
        expect(b.state.messages, hasLength(1));
        expect(b.state.profiles.keys, containsAll(['peer', 'self-pub']));
      },
    );

    blocTest<DmChatBloc, DmChatState>(
      'a fetch failure surfaces an error message',
      build: () {
        when(() => fetchDm.call('peer'))
            .thenAnswer((_) async => const Left(Failure.errorFailure('boom')));
        return build();
      },
      act: (b) => b.add(DmChatLoadEvent(otherPubkey: 'peer')),
      verify: (b) {
        expect(b.state.isLoading, isFalse);
        expect(b.state.errorMessage, isNotNull);
      },
    );

    blocTest<DmChatBloc, DmChatState>(
      'an unexpected exception is caught, not rethrown',
      build: () {
        when(() => fetchDm.call('peer')).thenThrow(Exception('boom'));
        return build();
      },
      act: (b) => b.add(DmChatLoadEvent(otherPubkey: 'peer')),
      verify: (b) {
        expect(b.state.isLoading, isFalse);
        expect(b.state.errorMessage, contains('boom'));
      },
    );

    blocTest<DmChatBloc, DmChatState>(
      'a written note triggers a reload via the isar watcher',
      build: build,
      act: (b) async {
        b.add(DmChatLoadEvent(otherPubkey: 'peer'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await isar.writeTxn(() => isar.noteModels.put(
              NoteModel(
                eventId: 'dm-1',
                sig: '',
                authorPubkey: 'peer',
                content: 'hi',
                kind: kDmTextKind,
                type: NoteType.text,
                conversationId: 1,
                eTagRefs: const [],
                pTagRefs: const [],
                tTags: const [],
                created: DateTime(2026, 1, 1),
              ),
            ));
      },
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        verify(() => fetchDm.call('peer')).called(greaterThanOrEqualTo(2));
      },
    );
  });

  group('DmChatSendEvent', () {
    blocTest<DmChatBloc, DmChatState>(
      'empty content and no attachments is a no-op',
      build: build,
      seed: () => const DmChatState(otherPubkey: 'peer'),
      act: (b) => b.add(DmChatSendEvent(content: '   ')),
      expect: () => <DmChatState>[],
      verify: (_) {
        verifyZeroInteractions(sendDm);
      },
    );

    blocTest<DmChatBloc, DmChatState>(
      'no otherPubkey loaded yet is a no-op',
      build: build,
      act: (b) => b.add(DmChatSendEvent(content: 'hi')),
      expect: () => <DmChatState>[],
      verify: (_) {
        verifyZeroInteractions(sendDm);
      },
    );

    blocTest<DmChatBloc, DmChatState>(
      'sends text content, clearing the reply context on success',
      build: () {
        when(() => sendDm.call(any())).thenAnswer((_) async => const Right(unit));
        return build();
      },
      seed: () => DmChatState(otherPubkey: 'peer', replyingToNote: aNote()),
      act: (b) => b.add(DmChatSendEvent(content: 'hello')),
      verify: (b) {
        expect(b.state.isSending, isFalse);
        expect(b.state.replyingToNote, isNull);
        final params = verify(() => sendDm.call(captureAny())).captured.single as SendDmParams;
        expect(params.otherPubkey, 'peer');
        expect(params.content, 'hello');
        expect(params.type.name, 'text');
      },
    );

    blocTest<DmChatBloc, DmChatState>(
      'a reply embeds the target note by value',
      build: () {
        when(() => sendDm.call(any())).thenAnswer((_) async => const Right(unit));
        return build();
      },
      seed: () => DmChatState(otherPubkey: 'peer', replyingToNote: aNote(id: 'replied-to')),
      act: (b) => b.add(DmChatSendEvent(content: 'my reply')),
      verify: (_) {
        final params = verify(() => sendDm.call(captureAny())).captured.single as SendDmParams;
        expect(params.embeddedNoteJson, isNotNull);
      },
    );

    blocTest<DmChatBloc, DmChatState>(
      'an image attachment sets NoteType.image',
      build: () {
        when(() => sendDm.call(any())).thenAnswer((_) async => const Right(unit));
        return build();
      },
      seed: () => const DmChatState(otherPubkey: 'peer'),
      act: (b) => b.add(DmChatSendEvent(content: 'a photo', attachments: [aMediaBlob()])),
      verify: (_) {
        final params = verify(() => sendDm.call(captureAny())).captured.single as SendDmParams;
        expect(params.type.name, 'image');
      },
    );

    blocTest<DmChatBloc, DmChatState>(
      'a send failure surfaces an error',
      build: () {
        when(() => sendDm.call(any()))
            .thenAnswer((_) async => const Left(Failure.errorFailure('relay down')));
        return build();
      },
      seed: () => const DmChatState(otherPubkey: 'peer'),
      act: (b) => b.add(DmChatSendEvent(content: 'hi')),
      verify: (b) {
        expect(b.state.isSending, isFalse);
        expect(b.state.errorMessage, isNotNull);
      },
    );

    blocTest<DmChatBloc, DmChatState>(
      'an unexpected exception during send is caught, not rethrown',
      build: () {
        when(() => sendDm.call(any())).thenThrow(Exception('crash'));
        return build();
      },
      seed: () => const DmChatState(otherPubkey: 'peer'),
      act: (b) => b.add(DmChatSendEvent(content: 'hi')),
      verify: (b) {
        expect(b.state.isSending, isFalse);
        expect(b.state.errorMessage, contains('crash'));
      },
    );
  });

  group('DmChatRefreshEvent', () {
    blocTest<DmChatBloc, DmChatState>(
      'drains the inbound queue then reloads if a pubkey is loaded',
      build: () {
        when(() => getDm.call()).thenAnswer((_) async => const Right(unit));
        return build();
      },
      seed: () => const DmChatState(otherPubkey: 'peer'),
      act: (b) => b.add(DmChatRefreshEvent()),
      wait: const Duration(milliseconds: 20),
      verify: (_) {
        verify(() => getDm.call()).called(1);
        verify(() => fetchDm.call('peer')).called(1);
      },
    );

    blocTest<DmChatBloc, DmChatState>(
      'does nothing beyond draining the queue when no pubkey is loaded yet',
      build: () {
        when(() => getDm.call()).thenAnswer((_) async => const Right(unit));
        return build();
      },
      act: (b) => b.add(DmChatRefreshEvent()),
      verify: (_) {
        verify(() => getDm.call()).called(1);
        verifyZeroInteractions(fetchDm);
      },
    );
  });

  group('reply context', () {
    blocTest<DmChatBloc, DmChatState>(
      'DmChatStartReplyEvent sets the note, DmChatCancelReplyEvent clears it',
      build: build,
      act: (b) {
        b.add(DmChatStartReplyEvent(aNote(id: 'n1')));
        b.add(DmChatCancelReplyEvent());
      },
      expect: () => [
        isA<DmChatState>().having((s) => s.replyingToNote?.id, 'replyingToNote', 'n1'),
        isA<DmChatState>().having((s) => s.replyingToNote, 'replyingToNote', isNull),
      ],
    );
  });

  group('mark seen', () {
    blocTest<DmChatBloc, DmChatState>(
      'marks an event id once per session even if fired again',
      build: () {
        when(() => markUnreadSeen.call(any())).thenAnswer((_) async => const Right(unit));
        return build();
      },
      act: (b) {
        b.add(DmChatMarkSeenEvent('n1'));
        b.add(DmChatMarkSeenEvent('n1'));
      },
      verify: (_) {
        verify(() => markUnreadSeen.call('n1')).called(1);
      },
    );

    blocTest<DmChatBloc, DmChatState>(
      'mark-all-seen is a no-op with no otherPubkey loaded',
      build: build,
      act: (b) => b.add(DmChatMarkAllSeenEvent()),
      verify: (_) {
        verifyZeroInteractions(markConversationSeen);
      },
    );

    // The handler emits no state, so there is nothing for blocTest to await:
    // the stub itself signals, instead of a fixed `wait:` that a loaded CI
    // runner outruns (this is the flake that failed the features shard).
    late Completer<void> marked;
    blocTest<DmChatBloc, DmChatState>(
      'mark-all-seen resolves the conversation id then marks it seen',
      build: () {
        marked = Completer<void>();
        when(() => markConversationSeen.call(any())).thenAnswer((_) async {
          if (!marked.isCompleted) marked.complete();
          return const Right(unit);
        });
        return build();
      },
      seed: () => const DmChatState(otherPubkey: 'peer'),
      setUp: () async {
        await isar.writeTxn(
            () => isar.dmConversationModels.put(DmConversationModel()..otherPubkey = 'peer'));
      },
      act: (b) => b.add(DmChatMarkAllSeenEvent()),
      verify: (_) async {
        await marked.future.timeout(const Duration(seconds: 10));
        verify(() => markConversationSeen.call(any())).called(1);
      },
    );

    blocTest<DmChatBloc, DmChatState>(
      'mark-all-seen is a no-op when the conversation row cannot be found',
      build: build,
      seed: () => const DmChatState(otherPubkey: 'peer'),
      act: (b) => b.add(DmChatMarkAllSeenEvent()),
      verify: (_) {
        verifyZeroInteractions(markConversationSeen);
      },
    );
  });
}
