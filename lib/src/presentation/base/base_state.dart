import 'package:domain/domain.dart';

/// Base state class for all presentation states
abstract class BaseState {
  const BaseState();
}

/// Initial state - when the screen is first loaded
abstract class InitialState extends BaseState {
  const InitialState();
}

/// Loading state - when data is being fetched
abstract class LoadingState extends BaseState {
  const LoadingState();
}

/// Success state with data
abstract class SuccessState<T> extends BaseState {
  final T data;
  const SuccessState(this.data);
}

/// Error state with failure
abstract class ErrorState extends BaseState {
  final Failure failure;
  const ErrorState(this.failure);

  String get errorMessage => failure.message;
}

/// Empty state - when there's no data
abstract class EmptyState extends BaseState {
  const EmptyState();
}

/// Generic data state for simple CRUD operations
sealed class DataState<T> extends BaseState {
  const DataState();
}

/// Initial data state
class DataInitial<T> extends DataState<T> {
  const DataInitial();
}

/// Loading data state
class DataLoading<T> extends DataState<T> {
  const DataLoading();
}

/// Success data state
class DataSuccess<T> extends DataState<T> {
  final T data;
  const DataSuccess(this.data);
}

/// Error data state
class DataError<T> extends DataState<T> {
  final Failure failure;
  const DataError(this.failure);

  String get errorMessage => failure.message;
}

/// Empty data state
class DataEmpty<T> extends DataState<T> {
  const DataEmpty();
}

