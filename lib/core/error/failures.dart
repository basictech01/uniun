import 'package:freezed_annotation/freezed_annotation.dart';
part 'failures.freezed.dart';

@freezed
abstract class Failure with _$Failure {
  const Failure._();

  const factory Failure.failure(final String message) = _Failure;
  const factory Failure.notFoundFailure(final String message) = _NotFoundFailure;
  const factory Failure.errorFailure(final String message) = _ErrorFailure;

  String toMessage() => when(
        failure: (m) => m,
        notFoundFailure: (m) => m,
        errorFailure: (m) => m,
      );
}
