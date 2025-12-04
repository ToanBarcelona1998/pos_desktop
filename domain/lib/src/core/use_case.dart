import 'result.dart';

/// Base use case interface for all use cases in the application.
/// [T] is the return type, [P] is the parameters type.
abstract class UseCase<T, P> {
  /// Executes the use case with the given parameters.
  Future<Result<T>> call(P params);
}

/// Use case that doesn't require any parameters.
abstract class UseCaseNoParams<T> {
  /// Executes the use case without parameters.
  Future<Result<T>> call();
}

/// Synchronous use case interface.
abstract class SyncUseCase<T, P> {
  /// Executes the use case synchronously.
  Result<T> call(P params);
}

/// Synchronous use case that doesn't require any parameters.
abstract class SyncUseCaseNoParams<T> {
  /// Executes the use case synchronously without parameters.
  Result<T> call();
}

/// Stream-based use case for reactive data.
abstract class StreamUseCase<T, P> {
  /// Returns a stream of results.
  Stream<Result<T>> call(P params);
}

/// Stream-based use case without parameters.
abstract class StreamUseCaseNoParams<T> {
  /// Returns a stream of results without parameters.
  Stream<Result<T>> call();
}

/// No parameters class for use cases that don't need parameters.
class NoParams {
  const NoParams();
}











