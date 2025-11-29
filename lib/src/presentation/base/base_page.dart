import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'base_cubit.dart';
import 'base_state.dart';

/// Base page widget with common functionality
abstract class BasePage<C extends BaseCubit<S>, S extends BaseState>
    extends StatelessWidget {
  const BasePage({super.key});

  /// Creates the cubit for this page
  C createCubit(BuildContext context);

  /// Builds the page content
  Widget buildContent(BuildContext context, S state);

  /// Called when cubit is created
  void onCubitCreated(BuildContext context, C cubit) {}

  @override
  Widget build(BuildContext context) {
    return BlocProvider<C>(
      create: (context) {
        final cubit = createCubit(context);
        onCubitCreated(context, cubit);
        return cubit;
      },
      child: BlocBuilder<C, S>(
        builder: (context, state) => buildContent(context, state),
      ),
    );
  }
}

/// Base stateful page widget
abstract class BaseStatefulPage<C extends BaseCubit<S>, S extends BaseState>
    extends StatefulWidget {
  const BaseStatefulPage({super.key});
}

/// Base state for stateful pages
abstract class BaseStatefulPageState<T extends BaseStatefulPage<C, S>,
    C extends BaseCubit<S>, S extends BaseState> extends State<T> {
  late C cubit;

  /// Creates the cubit for this page
  C createCubit();

  /// Builds the page content
  Widget buildContent(BuildContext context, S state);

  /// Called when cubit is created
  void onCubitCreated() {}

  /// Called when the widget is disposed
  void onDispose() {}

  @override
  void initState() {
    super.initState();
    cubit = createCubit();
    onCubitCreated();
  }

  @override
  void dispose() {
    onDispose();
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<C>.value(
      value: cubit,
      child: BlocBuilder<C, S>(
        builder: (context, state) => buildContent(context, state),
      ),
    );
  }
}

/// Extension for handling data states in widgets
extension DataStateWidgetExtension<T> on DataState<T> {
  Widget when({
    required Widget Function() initial,
    required Widget Function() loading,
    required Widget Function(T data) success,
    required Widget Function(String message) error,
    Widget Function()? empty,
  }) {
    return switch (this) {
      DataInitial() => initial(),
      DataLoading() => loading(),
      DataSuccess(:final data) => success(data),
      DataError(:final failure) => error(failure.message),
      DataEmpty() => empty?.call() ?? initial(),
    };
  }

  Widget maybeWhen({
    Widget Function()? initial,
    Widget Function()? loading,
    Widget Function(T data)? success,
    Widget Function(String message)? error,
    Widget Function()? empty,
    required Widget Function() orElse,
  }) {
    return switch (this) {
      DataInitial() => initial?.call() ?? orElse(),
      DataLoading() => loading?.call() ?? orElse(),
      DataSuccess(:final data) => success?.call(data) ?? orElse(),
      DataError(:final failure) => error?.call(failure.message) ?? orElse(),
      DataEmpty() => empty?.call() ?? orElse(),
    };
  }
}

