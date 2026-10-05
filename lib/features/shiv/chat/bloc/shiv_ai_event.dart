part of 'shiv_ai_bloc.dart';

@freezed
abstract class ShivAIEvent with _$ShivAIEvent {
  /// Load the conversation list on tab open.
  const factory ShivAIEvent.loadConversations() = _LoadConversations;

  /// Create a fresh conversation and open it.
  const factory ShivAIEvent.createConversation() = _CreateConversation;

  /// Create a fresh conversation, open it, and immediately send [firstMessage]
  /// as the first user turn. Used by Nataraj's ↓-discuss action.
  const factory ShivAIEvent.createConversationSeeded(String firstMessage) =
      _CreateConversationSeeded;

  /// Open an existing conversation (loads its messages).
  const factory ShivAIEvent.openConversation(String conversationId) =
      _OpenConversation;

  /// Close the active conversation, return to list view.
  const factory ShivAIEvent.closeConversation() = _CloseConversation;

  /// Delete a conversation by id.
  const factory ShivAIEvent.deleteConversation(String conversationId) =
      _DeleteConversation;

  /// User submitted a message — triggers RAG + inference pipeline. [manasIds]
  /// scopes the RAG to the selected Manas; empty = the whole library.
  const factory ShivAIEvent.sendMessage(
    String text, {
    @Default(<String>[]) List<String> manasIds,

    /// Photos sent with the message; empty for a text-only turn.
    @Default(<Uint8List>[]) List<Uint8List> images,
  }) = _SendMessage;

  /// User tapped stop during a streaming response — cancel the native stream
  /// and persist whatever has already been generated.
  const factory ShivAIEvent.stopStreaming() = _StopStreaming;

  /// Internal: BLoC appends each streamed token.
  const factory ShivAIEvent.tokenReceived(String token) = _TokenReceived;

  /// Internal: BLoC signals streaming complete.
  const factory ShivAIEvent.streamDone() = _StreamDone;

  /// Internal: BLoC signals streaming error.
  const factory ShivAIEvent.streamError(String message) = _StreamError;

  /// Switch active branch: rebuild messages by walking parentId chain from [leafMessageId] to root.
  const factory ShivAIEvent.switchBranch(String leafMessageId) = _SwitchBranch;

  /// Fork from [parentMessageId]: position the conversation at that node so
  /// the next sendMessage naturally becomes a new branch from there.
  const factory ShivAIEvent.createBranchFrom(String parentMessageId) = _CreateBranchFrom;

  /// Select a node in the graph view (shows the action panel).
  const factory ShivAIEvent.selectGraphNode(String? messageId) = _SelectGraphNode;
}
