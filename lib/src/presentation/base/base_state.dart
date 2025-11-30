import 'package:domain/domain.dart';

/// Base state for all Blocs
abstract class BaseState {
  const BaseState();
}

/// Initial state
class InitialState extends BaseState {
  const InitialState();
}

/// Loading state
class LoadingState extends BaseState {
  final String? message;
  const LoadingState({this.message});
}

/// Success state with data
class SuccessState<T> extends BaseState {
  final T data;
  final String? message;
  
  const SuccessState({required this.data, this.message});
}

/// Error state
class ErrorState extends BaseState {
  final Failure failure;
  final String? message;
  
  const ErrorState({required this.failure, this.message});
  
  String get errorMessage => message ?? failure.message;
}

/// Empty state
class EmptyState extends BaseState {
  final String? message;
  const EmptyState({this.message});
}
