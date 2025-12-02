// import 'package:domain/domain.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
//
// import 'base_state.dart';
//
// /// Base cubit for handling common patterns
// abstract class BaseCubit<S extends BaseState> extends Cubit<S> {
//   BaseCubit(super.initialState);
//
//   /// Safely emits a state if the cubit is not closed
//   void safeEmit(S state) {
//     if (!isClosed) {
//       emit(state);
//     }
//   }
// }
//
// /// Base cubit for data operations (CRUD)
// abstract class DataCubit<T> extends BaseCubit<DataState<T>> {
//   DataCubit() : super(const DataInitial());
//
//   /// Handles a result and emits appropriate states
//   void handleResult(Result<T> result) {
//     result.fold(
//       onSuccess: (data) => safeEmit(DataSuccess(data)),
//       onError: (failure) => safeEmit(DataError(failure)),
//     );
//   }
//
//   /// Handles a list result with empty state support
//   void handleListResult<E>(Result<List<E>> result) {
//     result.fold(
//       onSuccess: (data) {
//         if (data.isEmpty) {
//           safeEmit(const DataEmpty());
//         } else {
//           safeEmit(DataSuccess(data as T));
//         }
//       },
//       onError: (failure) => safeEmit(DataError(failure)),
//     );
//   }
//
//   /// Shows loading state
//   void showLoading() => safeEmit(const DataLoading());
//
//   /// Shows error state
//   void showError(Failure failure) => safeEmit(DataError(failure));
//
//   /// Shows empty state
//   void showEmpty() => safeEmit(const DataEmpty());
//
//   /// Resets to initial state
//   void reset() => safeEmit(const DataInitial());
// }
//
// /// Mixin for cubits that need loading state management
// mixin LoadingMixin<S extends BaseState> on BaseCubit<S> {
//   bool _isLoading = false;
//
//   bool get isLoading => _isLoading;
//
//   void setLoading(bool loading) {
//     _isLoading = loading;
//   }
// }
//
// /// Mixin for cubits that need pagination
// mixin PaginationMixin<S extends BaseState> on BaseCubit<S> {
//   int _currentPage = 1;
//   int _totalPages = 1;
//   bool _hasMore = true;
//   bool _isLoadingMore = false;
//
//   int get currentPage => _currentPage;
//   int get totalPages => _totalPages;
//   bool get hasMore => _hasMore;
//   bool get isLoadingMore => _isLoadingMore;
//
//   void resetPagination() {
//     _currentPage = 1;
//     _totalPages = 1;
//     _hasMore = true;
//     _isLoadingMore = false;
//   }
//
//   void updatePagination({
//     required int currentPage,
//     required int totalPages,
//   }) {
//     _currentPage = currentPage;
//     _totalPages = totalPages;
//     _hasMore = currentPage < totalPages;
//   }
//
//   void setLoadingMore(bool loading) {
//     _isLoadingMore = loading;
//   }
//
//   void incrementPage() {
//     if (_hasMore) {
//       _currentPage++;
//     }
//   }
// }
//
//
//




