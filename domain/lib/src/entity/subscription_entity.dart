import '../core/entity.dart';

/// Active subscription entity
class SubscriptionEntity extends Entity {
  final int id;
  final int businessId;
  final int packageId;
  final String? packageName;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? trialEndDate;
  final String status;
  final double? packagePrice;
  final String? packageInterval;
  final int? packageIntervalCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubscriptionEntity({
    required this.id,
    required this.businessId,
    required this.packageId,
    this.packageName,
    required this.startDate,
    required this.endDate,
    this.trialEndDate,
    required this.status,
    this.packagePrice,
    this.packageInterval,
    this.packageIntervalCount,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == 'active';
  bool get isExpired => DateTime.now().isAfter(endDate);
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  @override
  List<Object?> get props => [
        id,
        businessId,
        packageId,
        packageName,
        startDate,
        endDate,
        trialEndDate,
        status,
        packagePrice,
        packageInterval,
        packageIntervalCount,
        createdAt,
        updatedAt,
      ];
}












