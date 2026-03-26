import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_input.freezed.dart';

@freezed
abstract class GetFeedInput with _$GetFeedInput {
  const factory GetFeedInput({
    required int limit,
    DateTime? before, // cursor for pagination — fetch notes created before this time
  }) = _GetFeedInput;
}
