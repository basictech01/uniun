abstract class BaseUseCase<T> {
  const BaseUseCase();
}

// For use cases that emit a stream of values (e.g. download progress).
abstract class StreamUseCase<T, P> {
  const StreamUseCase();

  Stream<T> call(P input);
}

abstract class UseCase<T, P> extends BaseUseCase<T> {
  const UseCase() : super();

  Future<T> call(P input, {bool cached = false});
}

abstract class NoParamsUseCase<T> extends BaseUseCase<T> {
  const NoParamsUseCase() : super();

  Future<T> call();
}
