import 'base_model.dart';

/// Subscription data model
class SubscriptionModel extends BaseModel {
  final int id;
  final int businessId;
  final int packageId;
  final String? packageName;
  final String startDate;
  final String endDate;
  final String? trialEndDate;
  final String status;
  final double? packagePrice;
  final String? packageInterval;
  final int? packageIntervalCount;
  final String? createdAt;
  final String? updatedAt;

  const SubscriptionModel({
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

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      packageId: json['package_id'] as int,
      packageName: json['package']?['name'] as String?,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      trialEndDate: json['trial_end_date'] as String?,
      status: json['status'] as String,
      packagePrice: _parseDouble(json['package']?['price']),
      packageInterval: json['package']?['interval'] as String?,
      packageIntervalCount: json['package']?['interval_count'] as int?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'package_id': packageId,
      'start_date': startDate,
      'end_date': endDate,
      'trial_end_date': trialEndDate,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

