import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uniun/core/enum/note_type.dart';

part 'note_input.freezed.dart';

@freezed
abstract class GetFeedInput with _$GetFeedInput {
  const factory GetFeedInput({
    required int limit,
    DateTime? before, // cursor for pagination — fetch notes created before this time
  }) = _GetFeedInput;
}

/// Input for Brahma's compose flow — a note not yet signed.
///
/// BrahmaCreateBloc builds this from user input, then:
///   1. Signs it (UserRepository → nsec → Schnorr sign)
///   2. Builds a fully populated NoteEntity (with id, sig, created)
///   3. Calls PublishNoteUseCase(noteEntity)
@freezed
abstract class ComposeNoteInput with _$ComposeNoteInput {
  const factory ComposeNoteInput({
    /// The text content of the note.
    required String content,

    /// Derived from content — caller sets this (text / image / link / reference).
    required NoteType type,

    /// Thread root event ID — null = this is a new top-level note.
    String? rootEventId,

    /// Direct parent event ID — null = this is a new top-level note.
    String? replyToEventId,

    /// Pubkeys explicitly @-mentioned in the note.
    @Default([]) List<String> pTagRefs,

    /// Hashtags extracted from content.
    @Default([]) List<String> tTags,

    /// Extra e-tag "mention" references (e.g. quoting another note).
    @Default([]) List<String> mentionEventIds,
  }) = _ComposeNoteInput;
}
