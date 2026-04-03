import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/relay/relay_entity.dart';

abstract class RelayRepository {
  /// Returns all persisted relay configurations.
  Future<Either<Failure, List<RelayEntity>>> getAll();

  /// Persists a relay (insert or update by url).
  Future<Either<Failure, RelayEntity>> save(RelayEntity relay);

  /// Removes a relay by URL.
  Future<Either<Failure, Unit>> delete(String url);
}
