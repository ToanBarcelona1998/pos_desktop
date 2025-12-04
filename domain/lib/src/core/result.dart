import 'failure.dart';

/// A type that represents either a success value or a failure.
/// Similar to Either type in functional programming.
sealed class Result<T> {
  const Result();

  /// Returns true if this is a success result
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a failure result
  bool get isFailure => this is Failure;

  /// Gets the success value or null
  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Error() => null,
      };

  /// Gets the failure or null
  Failure? get failureOrNull => switch (this) {
        Success() => null,
        Error(:final failure) => failure,
      };

  /// Maps the success value to a new type
  Result<R> map<R>(R Function(T value) mapper) => switch (this) {
        Success(:final value) => Success(mapper(value)),
        Error(:final failure) => Error(failure),
      };

  /// Maps the success value to a new Result
  Result<R> flatMap<R>(Result<R> Function(T value) mapper) => switch (this) {
        Success(:final value) => mapper(value),
        Error(:final failure) => Error(failure),
      };

  /// Folds the result into a single value
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onError,
  }) =>
      switch (this) {
        Success(:final value) => onSuccess(value),
        Error(:final failure) => onError(failure),
      };

  /// Gets the value or throws an exception
  T getOrThrow() => switch (this) {
        Success(:final value) => value,
        Error(:final failure) =>
          throw Exception('Result is Error: ${failure.message}'),
      };

  /// Gets the value or returns a default
  T getOrElse(T defaultValue) => switch (this) {
        Success(:final value) => value,
        Error() => defaultValue,
      };

  /// Gets the value or computes a default
  T getOrElseCompute(T Function() compute) => switch (this) {
        Success(:final value) => value,
        Error() => compute(),
      };
}

/// Represents a successful result
final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Represents an error result
final class Error<T> extends Result<T> {
  final Failure failure;

  const Error(this.failure);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Error<T> && other.failure == failure;
  }

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Error($failure)';
}

/// Extension for creating Result from nullable values
extension ResultExtension<T> on T? {
  Result<T> toResult({Failure? failure}) => this != null
      ? Success(this as T)
      : Error(failure ?? const UnknownFailure());
}









