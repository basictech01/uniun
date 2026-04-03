import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/relay_status.dart';
import 'package:uniun/domain/entities/relay/relay_entity.dart';

part 'relay_model.g.dart';

/// Persisted relay configuration and live connection status.
///
/// Written by two actors:
///  - [RelayRepositoryImpl] (Isolate 1) for CRUD: add, remove, toggle read/write.
///  - [WebSocketService] (Isolate 2) for live status updates.
///
/// Watched by both isolates:
///  - Flutter UI watches for status badge updates.
///  - [CentralRelayManager] watches for runtime add/remove relay.
@Collection(ignore: {'copyWith'})
@Name('Relay')
class RelayModel {
  Id id = Isar.autoIncrement;

  /// WebSocket URL — ws:// or wss://.
  @Index(unique: true)
  late String url;

  /// Whether this relay is used for incoming event subscriptions (REQ).
  late bool read;

  /// Whether this relay is used for outbound event publishing (EVENT).
  late bool write;

  /// Live connection state — updated by [WebSocketService] on every transition.
  @Enumerated(EnumType.name)
  late RelayStatus status;

  /// Last time this relay successfully reached [RelayStatus.connected].
  DateTime? lastConnectedAt;
}

extension RelayModelExtension on RelayModel {
  RelayEntity toDomain() => RelayEntity(
        url: url,
        read: read,
        write: write,
        status: status,
        lastConnectedAt: lastConnectedAt,
      );
}
