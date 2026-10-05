import 'dart:typed_data';

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/enum/message_role.dart';
import 'package:uniun/domain/entities/shiv/shiv_conversation_entity.dart';
import 'package:uniun/domain/entities/shiv/shiv_message_entity.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/domain/usecases/shiv_usecases.dart';
import 'package:uniun/features/shiv/chat/bloc/shiv_ai_bloc.dart';
import 'package:uniun/features/shiv/rag/pipeline/rag_pipeline.dart';

class _MGetConversations extends Mock implements GetConversationsUseCase {}

class _MWatchConversations extends Mock implements WatchConversationsUseCase {}

class _MCreateConversation extends Mock implements CreateConversationUseCase {}

class _MDeleteConversation extends Mock implements DeleteConversationUseCase {}

class _MGetMessages extends Mock implements GetMessagesUseCase {}

class _MSaveMessage extends Mock implements SaveMessageUseCase {}

class _MUpdateMessageContent extends Mock
    implements UpdateMessageContentUseCase {}

class _MUpdateConversationTitle extends Mock
    implements UpdateConversationTitleUseCase {}

class _MUpdateActiveLeaf extends Mock implements UpdateActiveLeafUseCase {}

class _MHasModel extends Mock implements HasActiveLlmModelUseCase {}

class _MOpenConv extends Mock implements OpenLlmConversationUseCase {}

class _MCloseConv extends Mock implements CloseLlmConversationUseCase {}

class _MSendChatStream extends Mock implements SendChatStreamUseCase {}

class _MPreempt extends Mock implements PreemptBackgroundWorkUseCase {}

class _MResume extends Mock implements ResumeBackgroundWorkUseCase {}

class _MRag extends Mock implements RagPipeline {}

class _MDrainPending extends Mock implements DrainPendingExtractionsUseCase {}

/// Covers: the `createConversation` event no longer persists a Isar row (a
/// draft lives only in bloc state) — a real row is only written by
/// `sendMessage` on the first turn. Regression coverage for issue #159
/// ("new chat is created even without a single message").
final _photo = Uint8List.fromList([1, 2, 3]);

void main() {
  setUpAll(() {
    registerFallbackValue(ShivMessageEntity(
      messageId: 'fallback',
      conversationId: 'fallback',
      role: MessageRole.user,
      content: '',
      createdAt: DateTime(2026, 1, 1),
    ));
    registerFallbackValue(const SendChatStreamInput(message: ''));
    registerFallbackValue(('', ''));
  });

  late _MGetConversations getConversations;
  late _MWatchConversations watchConversations;
  late _MCreateConversation createConversation;
  late _MDeleteConversation deleteConversation;
  late _MGetMessages getMessages;
  late _MSaveMessage saveMessage;
  late _MUpdateMessageContent updateMessageContent;
  late _MUpdateConversationTitle updateConversationTitle;
  late _MUpdateActiveLeaf updateActiveLeaf;
  late _MHasModel hasModel;
  late _MOpenConv openConv;
  late _MCloseConv closeConv;
  late _MSendChatStream sendChatStream;
  late _MPreempt preempt;
  late _MResume resume;
  late _MRag rag;
  late _MDrainPending drainPending;

  ShivAIBloc build() => ShivAIBloc(
        getConversations,
        watchConversations,
        createConversation,
        deleteConversation,
        getMessages,
        saveMessage,
        updateMessageContent,
        updateConversationTitle,
        updateActiveLeaf,
        hasModel,
        openConv,
        closeConv,
        sendChatStream,
        preempt,
        resume,
        rag,
        drainPending,
      );

  final persistedConv = ShivConversationEntity(
    conversationId: 'persisted-1',
    title: 'first message text',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    getConversations = _MGetConversations();
    watchConversations = _MWatchConversations();
    createConversation = _MCreateConversation();
    deleteConversation = _MDeleteConversation();
    getMessages = _MGetMessages();
    saveMessage = _MSaveMessage();
    updateMessageContent = _MUpdateMessageContent();
    updateConversationTitle = _MUpdateConversationTitle();
    updateActiveLeaf = _MUpdateActiveLeaf();
    hasModel = _MHasModel();
    openConv = _MOpenConv();
    closeConv = _MCloseConv();
    sendChatStream = _MSendChatStream();
    preempt = _MPreempt();
    resume = _MResume();
    rag = _MRag();
    drainPending = _MDrainPending();

    when(() => watchConversations.call()).thenAnswer((_) => const Stream.empty());
    when(() => hasModel.call()).thenAnswer((_) async => true);
    when(() => openConv.call()).thenAnswer((_) async => const Right(unit));
    when(() => closeConv.call()).thenAnswer((_) async => const Right(unit));
    when(() => rag.buildSystemInstruction()).thenAnswer((_) async => 'sys');
    when(() => updateMessageContent.call(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => preempt.call()).thenAnswer((_) async => const Right(unit));
    when(() => resume.call()).thenAnswer((_) async => const Right(unit));
    when(() => drainPending.call()).thenAnswer((_) async {});
  });

  blocTest<ShivAIBloc, ShivAIState>(
    'createConversation only sets an in-memory draft — no persistence call, '
    'and the drawer list stays empty',
    build: build,
    act: (b) => b.add(const ShivAIEvent.createConversation()),
    verify: (b) {
      expect(b.state.activeConversation, isNotNull);
      expect(b.state.activeConversation!.title, 'New conversation');
      expect(b.state.conversations, isEmpty);
      verifyNever(() => createConversation.call(any()));
    },
  );

  blocTest<ShivAIBloc, ShivAIState>(
    'createConversation guarded by no active model — no draft, no crash',
    build: build,
    setUp: () => when(() => hasModel.call()).thenAnswer((_) async => false),
    act: (b) => b.add(const ShivAIEvent.createConversation()),
    verify: (b) {
      expect(b.state.activeConversation, isNull);
      verifyNever(() => createConversation.call(any()));
    },
  );

  group('sendMessage on a draft conversation persists it lazily', () {
    setUp(() {
      when(() => createConversation.call(any()))
          .thenAnswer((_) async => Right(persistedConv));
      when(() => saveMessage.call(any()))
          .thenAnswer((i) async => Right(i.positionalArguments.first));
      when(() => rag.buildMessage(
            userQuestion: any(named: 'userQuestion'),
            manasIds: any(named: 'manasIds'),
          )).thenAnswer((_) async => const RagMessage(
            userMessage: 'q',
            contextCount: 0,
          ));
      when(() => sendChatStream.call(any()))
          .thenAnswer((_) => const Stream.empty());
    });

    blocTest<ShivAIBloc, ShivAIState>(
      'first send on a draft calls CreateConversationUseCase with the '
      'message-derived title and adds it to the conversation list exactly once',
      build: build,
      act: (b) async {
        b.add(const ShivAIEvent.createConversation());
        await Future<void>.delayed(Duration.zero);
        b.add(const ShivAIEvent.sendMessage('first message text'));
      },
      wait: const Duration(milliseconds: 20),
      verify: (b) {
        verify(() => createConversation.call('first message text')).called(1);
        expect(b.state.activeConversation?.conversationId, 'persisted-1');
        expect(
          b.state.conversations.where((c) => c.conversationId == 'persisted-1'),
          hasLength(1),
        );
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'the images of a message reach the chat stream; a text message sends none',
      build: build,
      act: (b) async {
        b.add(const ShivAIEvent.createConversation());
        await Future<void>.delayed(Duration.zero);
        b.add(ShivAIEvent.sendMessage('what is this?', images: [_photo]));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      },
      wait: const Duration(milliseconds: 20),
      verify: (b) {
        final input = verify(() => sendChatStream.call(captureAny()))
            .captured
            .single as SendChatStreamInput;
        expect(input.images, [_photo]);
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'a message with no images sends an empty list to the chat stream',
      build: build,
      act: (b) async {
        b.add(const ShivAIEvent.createConversation());
        await Future<void>.delayed(Duration.zero);
        b.add(const ShivAIEvent.sendMessage('hello'));
      },
      wait: const Duration(milliseconds: 20),
      verify: (b) {
        final input = verify(() => sendChatStream.call(captureAny()))
            .captured
            .single as SendChatStreamInput;
        expect(input.images, isEmpty);
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'sending a second message on an already-persisted conversation does '
      'NOT call CreateConversationUseCase again',
      build: build,
      act: (b) async {
        b.add(const ShivAIEvent.createConversation());
        await Future<void>.delayed(Duration.zero);
        b.add(const ShivAIEvent.sendMessage('first message text'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        b.add(const ShivAIEvent.sendMessage('second message'));
      },
      wait: const Duration(milliseconds: 40),
      verify: (b) {
        verify(() => createConversation.call(any())).called(1);
        verifyNever(() => updateConversationTitle.call(any()));
      },
    );

    // ── Edge cases ──────────────────────────────────────────────────────

    blocTest<ShivAIBloc, ShivAIState>(
      'whitespace-only first message is a no-op — draft is never persisted',
      build: build,
      act: (b) async {
        b.add(const ShivAIEvent.createConversation());
        await Future<void>.delayed(Duration.zero);
        b.add(const ShivAIEvent.sendMessage('   \t\n  '));
      },
      wait: const Duration(milliseconds: 20),
      verify: (b) {
        verifyNever(() => createConversation.call(any()));
        expect(b.state.conversations, isEmpty);
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'sendMessage with no active conversation at all is a no-op',
      build: build,
      act: (b) => b.add(const ShivAIEvent.sendMessage('hello')),
      verify: (b) {
        verifyNever(() => createConversation.call(any()));
        expect(b.state.activeConversation, isNull);
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'persistence failure on first send surfaces an error and does not '
      'save any message',
      build: build,
      setUp: () => when(() => createConversation.call(any())).thenAnswer(
          (_) async => const Left(Failure.errorFailure('db error'))),
      act: (b) async {
        b.add(const ShivAIEvent.createConversation());
        await Future<void>.delayed(Duration.zero);
        b.add(const ShivAIEvent.sendMessage('hello'));
      },
      wait: const Duration(milliseconds: 20),
      verify: (b) {
        expect(b.state.status, ShivChatStatus.error);
        verifyNever(() => saveMessage.call(any()));
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'createConversationSeeded creates the draft then persists it via the '
      'same lazy path as a normal first send',
      build: build,
      act: (b) => b.add(const ShivAIEvent.createConversationSeeded('seed text')),
      wait: const Duration(milliseconds: 20),
      verify: (b) {
        verify(() => createConversation.call('seed text')).called(1);
        expect(b.state.activeConversation?.conversationId, 'persisted-1');
      },
    );
  });

  group('source ids for the Sources chip', () {
    setUp(() {
      when(() => createConversation.call(any()))
          .thenAnswer((_) async => Right(persistedConv));
      when(() => saveMessage.call(any()))
          .thenAnswer((i) async => Right(i.positionalArguments.first));
      when(() => rag.buildMessage(
            userQuestion: any(named: 'userQuestion'),
            manasIds: any(named: 'manasIds'),
          )).thenAnswer((_) async => const RagMessage(
            userMessage: 'q',
            contextCount: 2,
            sourceNoteIds: ['n1'],
            sourceChunkIds: ['s:0'],
          ));
      when(() => sendChatStream.call(any()))
          .thenAnswer((_) => const Stream.empty());
    });

    blocTest<ShivAIBloc, ShivAIState>(
      'a reply keeps both the note ids and the PDF chunk ids that grounded it',
      build: build,
      act: (b) async {
        b.add(const ShivAIEvent.createConversation());
        await Future<void>.delayed(Duration.zero);
        b.add(const ShivAIEvent.sendMessage('question'));
      },
      wait: const Duration(milliseconds: 40),
      verify: (b) {
        expect(b.state.lastTurnSourceNoteIds, ['n1']);
        expect(b.state.lastTurnSourceChunkIds, ['s:0']);
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'closing the conversation clears both id lists',
      build: build,
      act: (b) async {
        b.add(const ShivAIEvent.createConversation());
        await Future<void>.delayed(Duration.zero);
        b.add(const ShivAIEvent.sendMessage('question'));
        await Future<void>.delayed(const Duration(milliseconds: 40));
        b.add(const ShivAIEvent.closeConversation());
      },
      wait: const Duration(milliseconds: 40),
      verify: (b) {
        expect(b.state.lastTurnSourceNoteIds, isEmpty);
        expect(b.state.lastTurnSourceChunkIds, isEmpty);
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'starting a new conversation clears both id lists',
      build: build,
      act: (b) async {
        b.add(const ShivAIEvent.createConversation());
        await Future<void>.delayed(Duration.zero);
        b.add(const ShivAIEvent.sendMessage('question'));
        await Future<void>.delayed(const Duration(milliseconds: 40));
        b.add(const ShivAIEvent.createConversation());
      },
      wait: const Duration(milliseconds: 40),
      verify: (b) {
        expect(b.state.lastTurnSourceNoteIds, isEmpty);
        expect(b.state.lastTurnSourceChunkIds, isEmpty);
      },
    );
  });

  group('mid-stream interruption never leaves a permanently blank bubble', () {
    late StreamController<String> tokenController;

    setUp(() {
      tokenController = StreamController<String>();
      when(() => createConversation.call(any()))
          .thenAnswer((_) async => Right(persistedConv));
      when(() => saveMessage.call(any()))
          .thenAnswer((i) async => Right(i.positionalArguments.first));
      when(() => rag.buildMessage(
            userQuestion: any(named: 'userQuestion'),
            manasIds: any(named: 'manasIds'),
          )).thenAnswer((_) async => const RagMessage(
            userMessage: 'q',
            contextCount: 0,
          ));
      when(() => sendChatStream.call(any()))
          .thenAnswer((_) => tokenController.stream);
    });

    // Not `await tokenController.close()`: a single-subscription controller
    // that was never listened to (the "idle, no sendMessage" test below)
    // has a `.close()` future that never completes without a subscriber —
    // fire-and-forget avoids hanging tearDown.
    tearDown(() {
      unawaited(tokenController.close());
    });

    blocTest<ShivAIBloc, ShivAIState>(
      'tapping Stop mid-stream persists the partial tokens generated so far',
      build: build,
      act: (b) async {
        b.add(const ShivAIEvent.createConversation());
        await Future<void>.delayed(Duration.zero);
        b.add(const ShivAIEvent.sendMessage('question'));
        await Future<void>.delayed(Duration.zero);
        tokenController.add('partial answer');
        await Future<void>.delayed(const Duration(milliseconds: 60));
        b.add(const ShivAIEvent.stopStreaming());
      },
      wait: const Duration(milliseconds: 20),
      verify: (b) {
        expect(b.state.status, ShivChatStatus.chatIdle);
        expect(b.state.streamingContent, isNull);
        final captured =
            verify(() => updateMessageContent.call(captureAny())).captured;
        final lastCall = captured.last as (String, String);
        expect(lastCall.$2, 'partial answer');
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'a second token appends onto the already-non-empty raw buffer (the '
      'non-trimLeft branch)',
      build: build,
      act: (b) async {
        b.add(const ShivAIEvent.createConversation());
        await Future<void>.delayed(Duration.zero);
        b.add(const ShivAIEvent.sendMessage('question'));
        await Future<void>.delayed(Duration.zero);
        tokenController.add('one ');
        await Future<void>.delayed(const Duration(milliseconds: 60));
        tokenController.add('two');
        await Future<void>.delayed(const Duration(milliseconds: 60));
        b.add(const ShivAIEvent.stopStreaming());
      },
      verify: (b) {
        final captured =
            verify(() => updateMessageContent.call(captureAny())).captured;
        final lastCall = captured.last as (String, String);
        expect(lastCall.$2, 'one two');
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'tapping Stop before any token has arrived persists the "(stopped)" '
      'fallback, not an empty string',
      build: build,
      act: (b) async {
        b.add(const ShivAIEvent.createConversation());
        await Future<void>.delayed(Duration.zero);
        b.add(const ShivAIEvent.sendMessage('question'));
        await Future<void>.delayed(Duration.zero);
        b.add(const ShivAIEvent.stopStreaming());
      },
      verify: (b) {
        final captured =
            verify(() => updateMessageContent.call(captureAny())).captured;
        final lastCall = captured.last as (String, String);
        expect(lastCall.$2, '(stopped)');
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'closing the conversation mid-stream — the real issue #159 follow-on — '
      'persists the "(interrupted)" fallback instead of leaving the '
      'assistant placeholder blank forever',
      build: build,
      act: (b) async {
        b.add(const ShivAIEvent.createConversation());
        await Future<void>.delayed(Duration.zero);
        b.add(const ShivAIEvent.sendMessage('question'));
        await Future<void>.delayed(Duration.zero);
        b.add(const ShivAIEvent.closeConversation());
      },
      verify: (b) {
        expect(b.state.activeConversation, isNull);
        final captured =
            verify(() => updateMessageContent.call(captureAny())).captured;
        final lastCall = captured.last as (String, String);
        expect(lastCall.$2, '(interrupted)');
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'closing the conversation mid-stream AFTER some tokens arrived '
      'persists those tokens, not the fallback',
      build: build,
      act: (b) async {
        b.add(const ShivAIEvent.createConversation());
        await Future<void>.delayed(Duration.zero);
        b.add(const ShivAIEvent.sendMessage('question'));
        await Future<void>.delayed(Duration.zero);
        tokenController.add('half ');
        await Future<void>.delayed(const Duration(milliseconds: 60));
        b.add(const ShivAIEvent.closeConversation());
      },
      verify: (b) {
        final captured =
            verify(() => updateMessageContent.call(captureAny())).captured;
        final lastCall = captured.last as (String, String);
        expect(lastCall.$2, 'half');
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'closing an idle (non-streaming) conversation never calls '
      'updateMessageContent at all',
      build: build,
      act: (b) async {
        b.add(const ShivAIEvent.createConversation());
        await Future<void>.delayed(Duration.zero);
        b.add(const ShivAIEvent.closeConversation());
      },
      verify: (b) {
        verifyNever(() => updateMessageContent.call(any()));
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'a stream error surfaces as state.status == error with the error '
      'text, and persists that same error text into the assistant bubble '
      '(never a silent blank)',
      build: build,
      act: (b) async {
        b.add(const ShivAIEvent.createConversation());
        await Future<void>.delayed(Duration.zero);
        b.add(const ShivAIEvent.sendMessage('question'));
        await Future<void>.delayed(Duration.zero);
        tokenController.addError(Exception('model crashed'));
      },
      wait: const Duration(milliseconds: 20),
      verify: (b) {
        expect(b.state.status, ShivChatStatus.error);
        expect(b.state.errorMessage, contains('model crashed'));
        final captured =
            verify(() => updateMessageContent.call(captureAny())).captured;
        final lastCall = captured.last as (String, String);
        expect(lastCall.$2, contains('model crashed'));
      },
    );
  });

  group('sendMessage on an already-persisted, message-less conversation', () {
    blocTest<ShivAIBloc, ShivAIState>(
      'reopened-draft-less edge case: auto-titles via updateConversationTitle '
      'instead of createConversation',
      build: build,
      seed: () => ShivAIState(
        activeConversation: persistedConv,
        conversations: [persistedConv],
        messages: const [],
      ),
      setUp: () {
        when(() => updateConversationTitle.call(any()))
            .thenAnswer((_) async => const Right(unit));
        when(() => saveMessage.call(any()))
            .thenAnswer((i) async => Right(i.positionalArguments.first));
        when(() => rag.buildMessage(
              userQuestion: any(named: 'userQuestion'),
              manasIds: any(named: 'manasIds'),
            )).thenAnswer((_) async => const RagMessage(userMessage: 'q', contextCount: 0));
        when(() => sendChatStream.call(any())).thenAnswer((_) => const Stream.empty());
      },
      act: (b) => b.add(const ShivAIEvent.sendMessage('a brand new question')),
      wait: const Duration(milliseconds: 20),
      verify: (b) {
        verifyNever(() => createConversation.call(any()));
        verify(() => updateConversationTitle.call(('persisted-1', 'a brand new question')))
            .called(1);
        expect(b.state.activeConversation?.title, 'a brand new question');
      },
    );
  });

  group('defensive branches (streaming status with no in-flight message id)',
      () {
    // Not reachable via normal user flow — status==streaming is always set
    // together with streamingMessageId in _onSendMessage — but both handlers
    // guard the null case defensively; exercised here by seeding directly.
    blocTest<ShivAIBloc, ShivAIState>(
      '_onStopStreaming with no streamingMessageId clears status without '
      'calling updateMessageContent',
      build: build,
      seed: () => const ShivAIState(status: ShivChatStatus.streaming),
      act: (b) => b.add(const ShivAIEvent.stopStreaming()),
      verify: (b) {
        expect(b.state.status, ShivChatStatus.chatIdle);
        verifyNever(() => updateMessageContent.call(any()));
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      '_onStreamDone with no streamingMessageId clears status without '
      'calling updateMessageContent',
      build: build,
      seed: () => const ShivAIState(status: ShivChatStatus.streaming),
      act: (b) => b.add(const ShivAIEvent.streamDone()),
      verify: (b) {
        expect(b.state.status, ShivChatStatus.chatIdle);
        verifyNever(() => updateMessageContent.call(any()));
      },
    );
  });

  group('_onLoadConversations', () {
    setUp(() {
      when(() => rag.init()).thenAnswer((_) async {});
    });

    blocTest<ShivAIBloc, ShivAIState>(
      'success: inits RAG, loads the list, clears any error',
      build: build,
      setUp: () {
        when(() => getConversations.call())
            .thenAnswer((_) async => Right([persistedConv]));
      },
      act: (b) => b.add(const ShivAIEvent.loadConversations()),
      expect: () => [
        isA<ShivAIState>().having((s) => s.isRagInitializing, 'ragInit', true),
        isA<ShivAIState>().having((s) => s.isRagInitializing, 'ragInit', false),
        isA<ShivAIState>()
            .having((s) => s.conversations, 'conversations', [persistedConv])
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'a repository failure surfaces as an error status',
      build: build,
      setUp: () {
        when(() => getConversations.call())
            .thenAnswer((_) async => const Left(Failure.errorFailure('db down')));
      },
      act: (b) => b.add(const ShivAIEvent.loadConversations()),
      verify: (b) {
        expect(b.state.status, ShivChatStatus.error);
        expect(b.state.errorMessage, contains('db down'));
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'the active conversation being wiped (bulk delete) drops the '
      'selection and clears messages',
      build: build,
      seed: () => ShivAIState(
        activeConversation: persistedConv,
        messages: const [],
        status: ShivChatStatus.chatIdle,
      ),
      setUp: () {
        when(() => getConversations.call())
            .thenAnswer((_) async => const Right([])); // persistedConv gone
      },
      act: (b) => b.add(const ShivAIEvent.loadConversations()),
      verify: (b) {
        expect(b.state.activeConversation, isNull);
        expect(b.state.messages, isEmpty);
        expect(b.state.status, ShivChatStatus.idle);
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'a live in-flight stream survives a background list refresh — the '
      'chat page must not swap to an empty bubble mid-generation',
      build: build,
      seed: () => ShivAIState(
        activeConversation: persistedConv,
        status: ShivChatStatus.streaming,
      ),
      setUp: () {
        when(() => getConversations.call())
            .thenAnswer((_) async => Right([persistedConv]));
      },
      act: (b) => b.add(const ShivAIEvent.loadConversations()),
      verify: (b) {
        expect(b.state.status, ShivChatStatus.streaming);
        expect(b.state.activeConversation, persistedConv);
      },
    );

    test('the constructor subscribes to the conversations watcher and '
        'reloads on every mutation', () async {
      final controller = StreamController<void>();
      when(() => watchConversations.call()).thenAnswer((_) => controller.stream);
      when(() => getConversations.call())
          .thenAnswer((_) async => Right([persistedConv]));
      final bloc = build();

      controller.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.conversations, [persistedConv]);
      await controller.close();
      await bloc.close();
    });
  });

  group('_onOpenConversation', () {
    blocTest<ShivAIBloc, ShivAIState>(
      'no active model — no-op',
      build: build,
      setUp: () => when(() => hasModel.call()).thenAnswer((_) async => false),
      act: (b) => b.add(const ShivAIEvent.openConversation('persisted-1')),
      verify: (b) {
        verifyNever(() => getMessages.call(any()));
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'a conversationId not present in state.conversations is a no-op',
      build: build,
      act: (b) => b.add(const ShivAIEvent.openConversation('unknown-id')),
      verify: (b) {
        verifyNever(() => getMessages.call(any()));
        expect(b.state.activeConversation, isNull);
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'a getMessages failure surfaces an error status',
      build: build,
      seed: () => ShivAIState(conversations: [persistedConv]),
      setUp: () {
        when(() => getMessages.call('persisted-1'))
            .thenAnswer((_) async => const Left(Failure.errorFailure('x')));
      },
      act: (b) => b.add(const ShivAIEvent.openConversation('persisted-1')),
      verify: (b) {
        expect(b.state.status, ShivChatStatus.error);
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      'success opens a fresh chat session and loads the conversation\'s '
      'messages',
      build: () {
        when(() => getMessages.call('persisted-1')).thenAnswer((_) async =>
            Right([_msg('u1', 'persisted-1', MessageRole.user, 'hi')]));
        return build();
      },
      seed: () => ShivAIState(conversations: [persistedConv]),
      act: (b) => b.add(const ShivAIEvent.openConversation('persisted-1')),
      verify: (b) {
        expect(b.state.status, ShivChatStatus.chatIdle);
        expect(b.state.activeConversation, persistedConv);
        expect(b.state.messages, hasLength(1));
        verify(() => openConv.call()).called(1);
      },
    );
  });

  group('_onDeleteConversation', () {
    blocTest<ShivAIBloc, ShivAIState>(
      'removes the deleted conversation from the list',
      build: build,
      seed: () => ShivAIState(conversations: [persistedConv]),
      setUp: () {
        when(() => deleteConversation.call('persisted-1'))
            .thenAnswer((_) async => const Right(unit));
      },
      act: (b) => b.add(const ShivAIEvent.deleteConversation('persisted-1')),
      expect: () => [
        isA<ShivAIState>().having((s) => s.conversations, 'conversations', isEmpty),
      ],
    );
  });

  group('branch navigation', () {
    setUp(() {
      when(() => updateActiveLeaf.call(any()))
          .thenAnswer((_) async => const Right(unit));
      when(() => rag.buildBranchContextSummary(any())).thenReturn('summary');
    });

    blocTest<ShivAIBloc, ShivAIState>(
      '_onSwitchBranch with no active conversation is a no-op',
      build: build,
      act: (b) => b.add(const ShivAIEvent.switchBranch('leaf1')),
      verify: (_) {
        verifyNever(() => updateActiveLeaf.call(any()));
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      '_onSwitchBranch rebuilds the branch, re-inits the chat session with '
      'branch context, and updates activeLeafMessageId',
      build: build,
      seed: () => ShivAIState(
        activeConversation: persistedConv,
        allMessages: [
          _msg('root', 'persisted-1', MessageRole.user, 'root'),
          _msg('leaf1', 'persisted-1', MessageRole.assistant, 'leaf',
              parentId: 'root'),
        ],
      ),
      act: (b) => b.add(const ShivAIEvent.switchBranch('leaf1')),
      verify: (b) {
        verify(() => updateActiveLeaf.call(('persisted-1', 'leaf1'))).called(1);
        expect(b.state.messages, hasLength(2));
        expect(b.state.activeConversation?.activeLeafMessageId, 'leaf1');
        expect(b.state.selectedNodeMessageId, isNull);
        verify(() => openConv.call()).called(1);
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      '_onCreateBranchFrom with no active conversation is a no-op',
      build: build,
      act: (b) => b.add(const ShivAIEvent.createBranchFrom('root')),
      verify: (_) {
        verifyNever(() => updateActiveLeaf.call(any()));
      },
    );

    blocTest<ShivAIBloc, ShivAIState>(
      '_onCreateBranchFrom rebuilds the branch up to parentMessageId and '
      'updates activeLeafMessageId to it',
      build: build,
      seed: () => ShivAIState(
        activeConversation: persistedConv,
        allMessages: [
          _msg('root', 'persisted-1', MessageRole.user, 'root'),
        ],
      ),
      act: (b) => b.add(const ShivAIEvent.createBranchFrom('root')),
      verify: (b) {
        verify(() => updateActiveLeaf.call(('persisted-1', 'root'))).called(1);
        expect(b.state.activeConversation?.activeLeafMessageId, 'root');
      },
    );
  });

  group('_onSelectGraphNode', () {
    blocTest<ShivAIBloc, ShivAIState>(
      'sets selectedNodeMessageId',
      build: build,
      act: (b) => b.add(const ShivAIEvent.selectGraphNode('n1')),
      expect: () => [
        isA<ShivAIState>()
            .having((s) => s.selectedNodeMessageId, 'selectedNodeMessageId', 'n1'),
      ],
    );
  });

  group('tab enter/leave hooks', () {
    test('onEnterShivTab preempts background work', () {
      final bloc = build();

      bloc.onEnterShivTab();

      verify(() => preempt.call()).called(1);
    });

    test('onLeaveShivTab resumes background work and drains pending '
        'extractions', () {
      final bloc = build();

      bloc.onLeaveShivTab();

      verify(() => resume.call()).called(1);
      verify(() => drainPending.call()).called(1);
    });
  });

  group('close()', () {
    test('idle close: skips interrupted-stream persistence, still tears '
        'down conv/resume/drain', () async {
      final bloc = build();

      await bloc.close();

      verifyNever(() => updateMessageContent.call(any()));
      verify(() => closeConv.call()).called(1);
      verify(() => resume.call()).called(1);
      verify(() => drainPending.call()).called(1);
    });

    test('closing mid-stream finalizes the interrupted turn before tearing '
        'down', () async {
      final tokenController = StreamController<String>();
      when(() => createConversation.call(any()))
          .thenAnswer((_) async => Right(persistedConv));
      when(() => saveMessage.call(any()))
          .thenAnswer((i) async => Right(i.positionalArguments.first));
      when(() => rag.buildMessage(
            userQuestion: any(named: 'userQuestion'),
            manasIds: any(named: 'manasIds'),
          )).thenAnswer((_) async => const RagMessage(userMessage: 'q', contextCount: 0));
      when(() => sendChatStream.call(any())).thenAnswer((_) => tokenController.stream);
      final bloc = build();
      bloc.add(const ShivAIEvent.createConversation());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ShivAIEvent.sendMessage('question'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // Stream never completes on its own — only close() should finalize it.
      expect(bloc.state.status, ShivChatStatus.streaming);

      await bloc.close();
      unawaited(tokenController.close());

      final captured =
          verify(() => updateMessageContent.call(captureAny())).captured;
      expect((captured.last as (String, String)).$2, '(interrupted)');
    });
  });

  group('refreshStatus (static helper)', () {
    test('a live stream survives when the active conversation is still '
        'present', () {
      expect(
        ShivAIBloc.refreshStatus(ShivChatStatus.streaming, activeGone: false),
        ShivChatStatus.streaming,
      );
    });

    test('a live stream is downgraded to idle when the active conversation '
        'was wiped', () {
      expect(
        ShivAIBloc.refreshStatus(ShivChatStatus.streaming, activeGone: true),
        ShivChatStatus.idle,
      );
    });

    test('any non-streaming status always settles to idle', () {
      expect(ShivAIBloc.refreshStatus(ShivChatStatus.error, activeGone: false),
          ShivChatStatus.idle);
      expect(ShivAIBloc.refreshStatus(ShivChatStatus.chatIdle, activeGone: false),
          ShivChatStatus.idle);
    });
  });
}

ShivMessageEntity _msg(
  String id,
  String conversationId,
  MessageRole role,
  String content, {
  String? parentId,
}) =>
    ShivMessageEntity(
      messageId: id,
      conversationId: conversationId,
      parentId: parentId,
      role: role,
      content: content,
      createdAt: DateTime(2026, 1, 1),
    );
