import 'package:domain/domain.dart';

/// Home page state
class HomeState {
  final bool isLoading;
  final bool isSyncing;
  final String? userName;
  final String? businessName;
  final int? selectedLocationId;
  final List<LocationEntity> locations;
  final double totalSales;
  final double totalPurchase;
  final double totalExpenses;
  final int numberOfSales;
  final Failure? failure;

  const HomeState({
    this.isLoading = false,
    this.isSyncing = false,
    this.userName,
    this.businessName,
    this.selectedLocationId,
    this.locations = const [],
    this.totalSales = 0,
    this.totalPurchase = 0,
    this.totalExpenses = 0,
    this.numberOfSales = 0,
    this.failure,
  });

  factory HomeState.initial() => const HomeState(isLoading: true);

  HomeState copyWith({
    bool? isLoading,
    bool? isSyncing,
    String? userName,
    String? businessName,
    int? selectedLocationId,
    List<LocationEntity>? locations,
    double? totalSales,
    double? totalPurchase,
    double? totalExpenses,
    int? numberOfSales,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      userName: userName ?? this.userName,
      businessName: businessName ?? this.businessName,
      selectedLocationId: selectedLocationId ?? this.selectedLocationId,
      locations: locations ?? this.locations,
      totalSales: totalSales ?? this.totalSales,
      totalPurchase: totalPurchase ?? this.totalPurchase,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      numberOfSales: numberOfSales ?? this.numberOfSales,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}





