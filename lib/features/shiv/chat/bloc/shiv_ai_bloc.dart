import 'dart:typed_data';
import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/enum/message_role.dart';
import 'package:uniun/core/utils/llm_text_sanitizer.dart';
import 'package:uniun/domain/entities/shiv/shiv_conversation_entity.dart';
import 'package:uniun/domain/entities/shiv/shiv_message_entity.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/domain/usecases/shiv_usecases.dart';
import 'package:uniun/features/shiv/generation/chat_helpers.dart';
import 'package:uniun/features/shiv/rag/pipeline/rag_pipeline.dart';
import 'package:uuid/uuid.dart';

part 'shiv_ai_event.dart';
part 'shiv_ai_state.dart';
part 'shiv_ai_bloc.freezed.dart';

@injectable
class ShivAIBloc extends Bloc<ShivAIEvent, ShivAIState> {
  final GetConversationsUseCase _getConversations;
  final WatchConversationsUseCase _watchConversations;
  final CreateConversationUseCase _createConversation;
  final DeleteConversationUseCase _deleteConversation;
  final GetMessagesUseCase _getMessages;
  final SaveMessageUseCase _saveMessage;
  final UpdateMessageContentUseCase _updateMessageContent;
  final UpdateConversationTitleUseCase _updateConversationTitle;
  final UpdateActiveLeafUseCase _updateActiveLeaf;
  final HasActiveLlmModelUseCase _hasModel;
  final OpenLlmConversationUseCase _openConv;
  final CloseLlmConversationUseCase _closeConv;
  final SendChatStreamUseCase _sendChatStream;
  final PreemptBackgroundWorkUseCase _preempt;
  final ResumeBackgroundWorkUseCase _resume;
  final RagPipeline _rag;
  final DrainPendingExtractionsUseCase _drainPending;

  StreamSubscription<String>? _streamSub;

  /// Fires whenever the Isar `ShivConversation` collection mutates. Drives
  /// drawer-list freshness when Settings → Delete Chat History bulk-wipes,
  /// so the user doesn't have to restart the app to see the empty state.
  StreamSubscription<void>? _conversationsSub;

  /// Tokens arriving faster than one UI frame are coalesced here and flushed
  /// as a single [_TokenReceived] event on a short timer, so we emit (and
  /// rebuild + re-sanitize) at most ~20×/s instead of once per raw token. The
  /// LLM can stream 30–100 tok/s; without this, every token triggered a full
  /// state emission and a full-buffer sanitize, spiking the UI thread.
  final StringBuffer _pendingTokens = StringBuffer();
  Timer? _tokenFlushTimer;
  static const _kTokenFlushInterval = Duration(milliseconds: 50);

  /// Raw concatenation of streamed tokens for the in-flight assistant turn.
  /// Reset to '' at each `_initChatSession`. The state's [streamingContent]
  /// is the SANITIZED projection of this — we never concat new chunks onto
  /// the sanitized string because the sanitizer can swallow a truncated
  /// mid-`<think>` prefix that only closes in a later chunk.
  String _rawStreamingBuffer = '';

  /// The active conversation's system instruction (persona + any branch
  /// context), built in [_initChatSession] and passed into every send. Held
  /// per-bloc-instance — NOT on the singleton runner — so independent chat
  /// surfaces (Shiv tab, inline composer chat) never clobber each other.
  String? _systemInstruction;

  ShivAIBloc(
    this._getConversations,
    this._watchConversations,
    this._createConversation,
    this._deleteConversation,
    this._getMessages,
    this._saveMessage,
    this._updateMessageContent,
    this._updateConversationTitle,
    this._updateActiveLeaf,
    this._hasModel,
    this._openConv,
    this._closeConv,
    this._sendChatStream,
    this._preempt,
    this._resume,
    this._rag,
    this._drainPending,
  ) : super(const ShivAIState()) {
    // Tab enter/leave hooks (pause/resume + preempt + drain) live on
    // [onEnterShivTab] / [onLeaveShivTab]. They are driven by the parent
    // widget watching the bottom-nav index. We cannot do it from the bloc's
    // own constructor / [close] because [HomePage] uses an IndexedStack,
    // which keeps [ShivPage] mounted across tab switches — so the bloc never
    // actually disposes on tab change.
    on<_LoadConversations>(_onLoadConversations, transformer: droppable());
    on<_CreateConversation>(_onCreateConversation, transformer: droppable());
    on<_CreateConversationSeeded>(_onCreateConversationSeeded, transformer: droppable());
    on<_OpenConversation>(_onOpenConversation, transformer: droppable());
    on<_CloseConversation>(_onCloseConversation);
    on<_DeleteConversation>(_onDeleteConversation, transformer: sequential());
    on<_SendMessage>(_onSendMessage, transformer: sequential());
    on<_StopStreaming>(_onStopStreaming);
    on<_TokenReceived>(_onTokenReceived, transformer: sequential());
    on<_StreamDone>(_onStreamDone);
    on<_StreamError>(_onStreamError);
    on<_SwitchBranch>(_onSwitchBranch, transformer: droppable());
    on<_CreateBranchFrom>(_onCreateBranchFrom, transformer: droppable());
    on<_SelectGraphNode>(_onSelectGraphNode);

    // Keep the drawer in sync with Isar. Settings → Delete Chat History
    // bulk-clears `shivConversationModels`; without this the drawer keeps
    // stale rows until restart. Dispatches the same [_LoadConversations]
    // path the chat tab uses at open — `_rag.init()` is idempotent so a
    // re-trigger is cheap.
    _conversationsSub = _watchConversations.call().listen((_) {
      if (!isClosed) add(const ShivAIEvent.loadConversations());
    });
  }

  // ── Conversation list ───────────────────────────────────────────────────────

  Future<void> _onLoadConversations(
      _LoadConversations event, Emitter<ShivAIState> emit) async {
    emit(state.copyWith(isRagInitializing: true));
    await _rag.init();
    emit(state.copyWith(isRagInitializing: false));

    final result = await _getConversations.call();
    result.fold(
      (f) => emit(state.copyWith(
          status: ShivChatStatus.error, errorMessage: f.toString())),
      (list) {
        // If the active conversation was just wiped (Settings → Delete Chat
        // History fires this path), drop the selection so the chat pane
        // doesn't keep rendering a deleted row.
        final activeId = state.activeConversation?.conversationId;
        final activeGone =
            activeId != null && !list.any((c) => c.conversationId == activeId);
        emit(state.copyWith(
          // The watcher re-fires this path on every conversation mutation —
          // including the create + auto-title update that land WHILE the first
          // reply streams. Preserve an in-flight stream so the chat page keeps
          // the live streaming bubble instead of swapping in an empty one.
          status: refreshStatus(state.status, activeGone: activeGone),
          conversations: list,
          activeConversation: activeGone ? null : state.activeConversation,
          messages: activeGone ? const [] : state.messages,
          errorMessage: null,
        ));
      },
    );
  }

  Future<void> _onCreateConversation(
      _CreateConversation event, Emitter<ShivAIState> emit) async {
    // Guard: no model loaded yet — ShivPage._checkModel() will redirect.
    if (!await _hasModel.call()) return;

    await _initChatSession();
    // Draft only — NOT persisted to Isar and NOT added to state.conversations,
    // so it never appears in the drawer. It's only written to Isar (via
    // _onSendMessage's isDraft branch) once the user actually sends a first
    // message, so opening/abandoning an empty chat leaves no history row.
    final draft = ShivConversationEntity(
      conversationId: const Uuid().v4(),
      title: 'New conversation',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    emit(state.copyWith(
      status: ShivChatStatus.chatIdle,
      activeConversation: draft,
      messages: [],
      ragContextCount: 0,
      lastTurnSourceNoteIds: const [],
      lastTurnSourceChunkIds: const [],
      errorMessage: null,
    ));
  }

  Future<void> _onCreateConversationSeeded(
      _CreateConversationSeeded event, Emitter<ShivAIState> emit) async {
    // Step 1: create + open a fresh conversation (same path as _onCreateConversation).
    await _onCreateConversation(
        const ShivAIEvent.createConversation() as _CreateConversation, emit);
    // Step 2: send the seed text through the normal RAG + inference pipeline.
    // _onSendMessage reads state.activeConversation, which was set by the emit
    // in step 1 — safe to call sequentially within the same handler/emitter.
    await _onSendMessage(
        ShivAIEvent.sendMessage(event.firstMessage) as _SendMessage, emit);
  }

  Future<void> _onOpenConversation(
      _OpenConversation event, Emitter<ShivAIState> emit) async {
    // Guard: no model loaded yet — ShivPage._checkModel() will redirect.
    if (!await _hasModel.call()) return;

    final conv = state.conversations
        .where((c) => c.conversationId == event.conversationId)
        .firstOrNull;
    if (conv == null) return;

    final result = await _getMessages.call(event.conversationId);
    await result.fold(
      (f) async => emit(state.copyWith(
          status: ShivChatStatus.error, errorMessage: f.toString())),
      (msgs) async {
        await _initChatSession();
        emit(state.copyWith(
          status: ShivChatStatus.chatIdle,
          activeConversation: conv,
          messages: msgs,
          allMessages: msgs,
          ragContextCount: 0,
          lastTurnSourceNoteIds: const [],
          lastTurnSourceChunkIds: const [],
          errorMessage: null,
        ));
      },
    );
  }

  Future<void> _onCloseConversation(
      _CloseConversation event, Emitter<ShivAIState> emit) async {
    // Leaving mid-generation (back button, navigating away) must not leave
    // the assistant placeholder permanently blank — finalize whatever
    // streamed so far, same as the explicit Stop button.
    if (state.status == ShivChatStatus.streaming) {
      await _persistInterruptedStream('(interrupted)');
    }
    _streamSub?.cancel();
    _cancelTokenFlush();
    await _closeConv.call();
    emit(state.copyWith(
      status: ShivChatStatus.idle,
      activeConversation: null,
      messages: [],
      streamingContent: null,
      streamingMessageId: null,
      ragContextCount: 0,
      lastTurnSourceNoteIds: const [],
      lastTurnSourceChunkIds: const [],
    ));
  }

  Future<void> _onDeleteConversation(
      _DeleteConversation event, Emitter<ShivAIState> emit) async {
    await _deleteConversation.call(event.conversationId);
    final updated = state.conversations
        .where((c) => c.conversationId != event.conversationId)
        .toList();
    emit(state.copyWith(conversations: updated));
  }

  // ── Chat / Inference ────────────────────────────────────────────────────────

  Future<void> _onSendMessage(
      _SendMessage event, Emitter<ShivAIState> emit) async {
    final conv = state.activeConversation;
    if (conv == null) return;

    final text = event.text.trim();
    if (text.isEmpty) return;

    // A conversation created by _onCreateConversation is a draft — not yet
    // persisted to Isar, so it's absent from state.conversations. This is
    // the actual moment (first real message) it becomes real history.
    final isFirstMessage = state.messages.isEmpty;
    final isDraft =
        !state.conversations.any((c) => c.conversationId == conv.conversationId);

    ShivConversationEntity updatedConv = conv;
    if (isDraft) {
      final title = text.length > 40 ? '${text.substring(0, 40)}…' : text;
      final result = await _createConversation.call(title);
      final created = result.fold((f) => null, (c) => c);
      if (created == null) {
        emit(state.copyWith(
            status: ShivChatStatus.error,
            errorMessage: result.fold((f) => f.toString(), (_) => '')));
        return;
      }
      updatedConv = created;
      emit(state.copyWith(
        activeConversation: updatedConv,
        conversations: [
          updatedConv,
          ...state.conversations
              .where((c) => c.conversationId != updatedConv.conversationId),
        ],
      ));
    } else if (isFirstMessage) {
      // Existing persisted conversation with no messages yet (e.g. reopened
      // draft-less edge case) — keep the old auto-title-on-first-message path.
      final title = text.length > 40 ? '${text.substring(0, 40)}…' : text;
      await _updateConversationTitle.call((conv.conversationId, title));
      updatedConv = conv.copyWith(title: title);
      final updatedList = state.conversations.map((c) {
        return c.conversationId == conv.conversationId ? updatedConv : c;
      }).toList();
      emit(state.copyWith(
        activeConversation: updatedConv,
        conversations: updatedList,
      ));
    }

    // 1 — Save user message.
    final userMsgId = const Uuid().v4();
    final userMsg = ShivMessageEntity(
      messageId: userMsgId,
      conversationId: updatedConv.conversationId,
      parentId: state.messages.lastOrNull?.messageId,
      role: MessageRole.user,
      content: text,
      createdAt: DateTime.now(),
    );
    await _saveMessage.call(userMsg);

    // 2 — Placeholder assistant message.
    final assistantMsgId = const Uuid().v4();
    final placeholderMsg = ShivMessageEntity(
      messageId: assistantMsgId,
      conversationId: updatedConv.conversationId,
      parentId: userMsgId,
      role: MessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
    );
    await _saveMessage.call(placeholderMsg);

    final newMessages = [...state.messages, userMsg, placeholderMsg];
    emit(state.copyWith(
      status: ShivChatStatus.streaming,
      messages: newMessages,
      allMessages: [...state.allMessages, userMsg, placeholderMsg],
      streamingContent: '',
      streamingMessageId: assistantMsgId,
    ));
    _rawStreamingBuffer = '';

    // 3 — RAG: embed query → retrieve notes → build per-turn user message.
    final ragMsg =
        await _rag.buildMessage(userQuestion: text, manasIds: event.manasIds);
    emit(state.copyWith(
      ragContextCount: ragMsg.contextCount,
      lastTurnSourceNoteIds: ragMsg.sourceNoteIds,
      lastTurnSourceChunkIds: ragMsg.sourceChunkIds,
    ));

    // 4 — Pair up prior turns as clean (Q, A) tuples. We exclude the
    //     placeholder we just appended; cap to last 3 pairs so the prompt
    //     stays small but the model still has continuity for follow-ups.
    final cleanHistory = pairCleanHistory(
      state.messages.where((m) => m.messageId != userMsgId && m.messageId != assistantMsgId).toList(),
      maxPairs: 3,
    );

    // 5 — Stream inference through the LlmRepository (priority-coordinated
    //     locally; goes over HTTP for the cloud backend in Phase 3).
    _streamSub?.cancel();
    _cancelTokenFlush();
    _streamSub = _sendChatStream
        .call(SendChatStreamInput(
          message: ragMsg.userMessage,
          systemInstruction: _systemInstruction,
          cleanHistory: cleanHistory,
          images: event.images,
        ))
        .listen(
      (token) {
        _pendingTokens.write(token);
        _tokenFlushTimer ??= Timer(_kTokenFlushInterval, _flushPendingTokens);
      },
      onDone: () {
        _flushPendingTokens(); // flush the trailing batch BEFORE streamDone
        add(const ShivAIEvent.streamDone());
      },
      onError: (Object e) {
        _cancelTokenFlush();
        add(ShivAIEvent.streamError(e.toString()));
      },
      cancelOnError: true,
    );
  }

  /// Drain [_pendingTokens] into a single [_TokenReceived] event. Called by the
  /// flush timer and once more on `onDone` so no trailing batch is lost.
  void _flushPendingTokens() {
    _tokenFlushTimer?.cancel();
    _tokenFlushTimer = null;
    if (_pendingTokens.isEmpty) return;
    final batch = _pendingTokens.toString();
    _pendingTokens.clear();
    add(ShivAIEvent.tokenReceived(batch));
  }

  /// Drop any buffered tokens and stop the flush timer. Called wherever the
  /// stream subscription is torn down so a late timer can't `add` into a turn
  /// that no longer exists.
  void _cancelTokenFlush() {
    _tokenFlushTimer?.cancel();
    _tokenFlushTimer = null;
    _pendingTokens.clear();
  }

  /// Persists whatever content streamed so far into the in-flight assistant
  /// placeholder (or [fallbackText] if nothing arrived yet at all), so a
  /// stream that gets torn down mid-turn — Stop button, closing the chat,
  /// leaving the app — never leaves a permanently blank assistant bubble in
  /// Isar. Returns the content actually written, or null if there was no
  /// in-flight assistant message to finalize.
  Future<String?> _persistInterruptedStream(String fallbackText) async {
    final msgId = state.streamingMessageId;
    if (msgId == null) return null;
    final partial = stripThinking(state.streamingContent ?? '').trim();
    final finalContent = partial.isEmpty ? fallbackText : partial;
    await _updateMessageContent.call((msgId, finalContent));
    return finalContent;
  }

  /// User tapped stop during streaming. Cancel the native token stream, keep
  /// whatever's already been generated, and persist it as the final assistant
  /// message so the conversation stays coherent on next open.
  Future<void> _onStopStreaming(
      _StopStreaming event, Emitter<ShivAIState> emit) async {
    if (state.status != ShivChatStatus.streaming) return;
    await _streamSub?.cancel();
    _streamSub = null;
    _cancelTokenFlush();

    final msgId = state.streamingMessageId;
    final finalContent = await _persistInterruptedStream('(stopped)');

    if (msgId != null && finalContent != null) {
      final updatedMessages = state.messages.map((m) {
        if (m.messageId == msgId) return m.copyWith(content: finalContent);
        return m;
      }).toList();
      // Keep allMessages (the branch-tree source) in sync with the partial.
      final updatedAllMessages = state.allMessages.map((m) {
        if (m.messageId == msgId) return m.copyWith(content: finalContent);
        return m;
      }).toList();
      emit(state.copyWith(
        status: ShivChatStatus.chatIdle,
        messages: updatedMessages,
        allMessages: updatedAllMessages,
        streamingContent: null,
        streamingMessageId: null,
      ));
    } else {
      emit(state.copyWith(
        status: ShivChatStatus.chatIdle,
        streamingContent: null,
        streamingMessageId: null,
      ));
    }
  }

  void _onTokenReceived(_TokenReceived event, Emitter<ShivAIState> emit) {
    // Strip whitespace-only prefix some chat templates emit as the first token.
    _rawStreamingBuffer = _rawStreamingBuffer.isEmpty
        ? (_rawStreamingBuffer + event.token).trimLeft()
        : _rawStreamingBuffer + event.token;
    // The sanitizer MUST run on the cumulative buffer, not per-chunk, because
    // UTF-8 multi-byte sequences (emoji mojibake) can span token boundaries.
    // Idempotent + cheap — safe to re-run every token. This is the only path
    // that cleans the live bubble; `_onStreamDone` saves the cleaned row
    // separately via [shiv_repository_impl.dart].
    emit(state.copyWith(
      streamingContent: LlmTextSanitizer.clean(_rawStreamingBuffer),
    ));
  }

  Future<void> _onStreamDone(
      _StreamDone event, Emitter<ShivAIState> emit) async {
    final msgId = state.streamingMessageId;
    // Strip <think>...</think> blocks before persisting — model reasoning is
    // never stored so it cannot leak back into RAG context or branch summaries.
    final content = stripThinking(state.streamingContent ?? '');

    if (msgId != null) {
      await _updateMessageContent.call((msgId, content));

      final updatedMessages = state.messages.map((m) {
        if (m.messageId == msgId) return m.copyWith(content: content);
        return m;
      }).toList();
      // Keep allMessages (the branch-tree source) in sync — otherwise the
      // tree keeps rendering the empty placeholder for this reply.
      final updatedAllMessages = state.allMessages.map((m) {
        if (m.messageId == msgId) return m.copyWith(content: content);
        return m;
      }).toList();

      emit(state.copyWith(
        status: ShivChatStatus.chatIdle,
        messages: updatedMessages,
        allMessages: updatedAllMessages,
        streamingContent: null,
        streamingMessageId: null,
      ));
    } else {
      emit(state.copyWith(
        status: ShivChatStatus.chatIdle,
        streamingContent: null,
        streamingMessageId: null,
      ));
    }
  }

  Future<void> _onStreamError(
      _StreamError event, Emitter<ShivAIState> emit) async {
    // Write the error into the assistant placeholder bubble — otherwise the
    // turn ends as a silent empty bubble and the user never learns why
    // (rate limit, no credit, model not allowed, network…).
    final msgId = state.streamingMessageId;
    var messages = state.messages;
    var allMessages = state.allMessages;
    if (msgId != null) {
      await _updateMessageContent.call((msgId, event.message));
      messages = messages
          .map((m) =>
              m.messageId == msgId ? m.copyWith(content: event.message) : m)
          .toList();
      allMessages = allMessages
          .map((m) =>
              m.messageId == msgId ? m.copyWith(content: event.message) : m)
          .toList();
    }

    emit(state.copyWith(
      status: ShivChatStatus.error,
      errorMessage: event.message,
      messages: messages,
      allMessages: allMessages,
      streamingContent: null,
      streamingMessageId: null,
    ));
  }

  // ── Branch graph ────────────────────────────────────────────────────────────

  Future<void> _onSwitchBranch(
      _SwitchBranch event, Emitter<ShivAIState> emit) async {
    final conv = state.activeConversation;
    if (conv == null) return;

    final branch = buildBranch(event.leafMessageId, state.allMessages);
    await _updateActiveLeaf.call((conv.conversationId, event.leafMessageId));

    // Reinit chat with a compact summary of the branch as context so the model
    // knows what was discussed on this path without replaying full history.
    await _initChatSession(branchContext: branch);

    emit(state.copyWith(
      messages: branch,
      activeConversation: conv.copyWith(activeLeafMessageId: event.leafMessageId),
      selectedNodeMessageId: null,
      lastTurnSourceNoteIds: const [],
      lastTurnSourceChunkIds: const [],
    ));
  }

  Future<void> _onCreateBranchFrom(
      _CreateBranchFrom event, Emitter<ShivAIState> emit) async {
    final conv = state.activeConversation;
    if (conv == null) return;

    final branch = buildBranch(event.parentMessageId, state.allMessages);
    await _updateActiveLeaf.call((conv.conversationId, event.parentMessageId));

    await _initChatSession(branchContext: branch);

    emit(state.copyWith(
      messages: branch,
      activeConversation: conv.copyWith(activeLeafMessageId: event.parentMessageId),
      selectedNodeMessageId: null,
      lastTurnSourceNoteIds: const [],
      lastTurnSourceChunkIds: const [],
    ));
  }

  void _onSelectGraphNode(
      _SelectGraphNode event, Emitter<ShivAIState> emit) {
    emit(state.copyWith(selectedNodeMessageId: event.messageId));
  }

  /// Called by [ShivPage] when the user navigates onto the AI tab. Pauses
  /// the low-priority queue so no new background extraction starts while
  /// the user might chat. Any in-flight extraction is allowed to finish on
  /// its own — the actual "stop the running one" preemption is triggered
  /// inside [LlmRepository.sendChat] the moment the user sends a turn,
  /// which is safe on flutter_gemma 0.16 because [InferenceModel.openChat]
  /// gives each Dart wrapper its own native session.
  void onEnterShivTab() {
    unawaited(_preempt.call());
  }

  /// Called by [ShivPage] when the user navigates away from the AI tab.
  /// Resumes background extraction and replays any extraction that got
  /// preempted while the user was chatting, so the graph/memory for those
  /// notes gets built before the next visit. Fire-and-forget; the drainer
  /// uses the low-priority lane and is internally guarded against overlap.
  void onLeaveShivTab() {
    unawaited(_resume.call());
    unawaited(_drainPending.call());
  }

  @override
  Future<void> close() async {
    // Bloc/app teardown mid-generation (logout, HomePage disposal) — same
    // finalize-don't-leave-blank rule as _onCloseConversation.
    if (state.status == ShivChatStatus.streaming) {
      await _persistInterruptedStream('(interrupted)');
    }
    _streamSub?.cancel();
    _conversationsSub?.cancel();
    _cancelTokenFlush();
    await _closeConv.call();
    // Safety net for logout / HomePage teardown — make sure the queue isn't
    // left paused and any pending extractions get a final chance to drain.
    await _resume.call();
    unawaited(_drainPending.call());
    return super.close();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Resolves the chat [ShivChatStatus] when the background conversations
  /// watcher refreshes the list mid-session. The watcher
  /// (`shivConversationModels.watchLazy`) re-fires on EVERY conversation
  /// mutation — including the conversation-create + auto-title update that land
  /// WHILE the first reply is streaming. Downgrading an in-flight `streaming`
  /// turn to `idle` here makes the chat page render the assistant placeholder
  /// as a regular (non-streaming) bubble, hiding the typing dots AND the
  /// streamed tokens until the turn ends. So a live stream is preserved;
  /// everything else settles to `idle` (which also clears any prior error).
  @visibleForTesting
  static ShivChatStatus refreshStatus(
    ShivChatStatus current, {
    required bool activeGone,
  }) {
    if (!activeGone && current == ShivChatStatus.streaming) {
      return ShivChatStatus.streaming;
    }
    return ShivChatStatus.idle;
  }

  /// Creates a fresh InferenceChat session with the Shiv system instruction.
  /// On branch switch, [branchContext] adds a compact conversation summary so
  /// the model understands what was discussed on the parent path.
  Future<void> _initChatSession({List<ShivMessageEntity>? branchContext}) async {
    final base = await _rag.buildSystemInstruction();
    final contextSummary = branchContext != null && branchContext.isNotEmpty
        ? _rag.buildBranchContextSummary(branchContext)
        : '';
    // Hold the instruction on this bloc instance; it rides each send turn.
    _systemInstruction = contextSummary.isEmpty ? base : '$base$contextSummary';
    await _openConv.call();
  }
}
