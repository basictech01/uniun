import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uniun/core/enum/note_type.dart';

part 'saved_note_entity.freezed.dart';

@freezed
abstract class SavedNoteEntity with _$SavedNoteEntity {
  const factory SavedNoteEntity({
    required String eventId,
    required String sig,
    required String authorPubkey,
    required String content,
    required NoteType type,
    required List<String> eTagRefs,
    required List<String> pTagRefs,
    required List<String> tTags,
    required DateTime created,
    required DateTime savedAt,
  }) = _SavedNoteEntity;
}
