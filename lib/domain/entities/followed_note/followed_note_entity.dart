import 'package:freezed_annotation/freezed_annotation.dart';

part 'followed_note_entity.freezed.dart';

@freezed
abstract class FollowedNoteEntity with _$FollowedNoteEntity {
  const factory FollowedNoteEntity({
    required String eventId,
    required String contentPreview,
    required DateTime followedAt,
    required int newReferenceCount,
  }) = _FollowedNoteEntity;
}
