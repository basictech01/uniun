import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uniun/core/enum/outbound_status.dart';

part 'outbound_event_entity.freezed.dart';

@freezed
abstract class OutboundEventEntity with _$OutboundEventEntity {
  const factory OutboundEventEntity({
    required int id,
    required String serializedEvent,
    required OutboundStatus status,
    required DateTime createdAt,
    required int retryCount,
  }) = _OutboundEventEntity;
}
