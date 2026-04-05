import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/outbound_status.dart';
import 'package:uniun/domain/entities/outbound_event/outbound_event_entity.dart';

part 'outbound_event_model.g.dart';

@Collection(ignore: {'copyWith'})
@Name('OutboundEvent')
class OutboundEventModel {
  Id id = Isar.autoIncrement;

  /// Serialized signed Nostr event JSON — ready to send to relays.
  late String serializedEvent;

  @Enumerated(EnumType.name)
  late OutboundStatus status;

  /// When the UI enqueued this event.
  late DateTime createdAt;

  /// Incremented by EmbeddedServer on each failed broadcast attempt.
  int retryCount = 0;
}

extension OutboundEventModelExtension on OutboundEventModel {
  OutboundEventEntity toDomain() => OutboundEventEntity(
        id: id,
        serializedEvent: serializedEvent,
        status: status,
        createdAt: createdAt,
        retryCount: retryCount,
      );
}
