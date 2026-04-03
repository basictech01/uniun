import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uniun/core/enum/relay_status.dart';

part 'relay_entity.freezed.dart';

@freezed
abstract class RelayEntity with _$RelayEntity {
  const factory RelayEntity({
    required String url,
    required bool read,
    required bool write,
    required RelayStatus status,
    DateTime? lastConnectedAt,
  }) = _RelayEntity;
}
