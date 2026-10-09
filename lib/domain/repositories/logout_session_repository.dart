import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';

/// Clears data and sessions tied to the current identity before its key is removed.
abstract class LogoutSessionRepository {
  Future<Either<Failure, Unit>> clear({required bool keepModelFiles});
}
