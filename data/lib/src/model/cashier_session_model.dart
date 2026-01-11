import 'dart:convert';

import 'base_model.dart';

/// Cashier session model
class CashierSessionModel extends BaseModel {
  final int? id;
  final int userId;
  final int locationId;
  final double openingAmount;
  final double? closingAmount;
  final double? closingAmountOnStaff;
  final double? totalCardSlips;
  final double? totalCheques;
  final String? closingNote;
  final Map<String, int>? denominations;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status;
  final bool isSynced;

  CashierSessionModel({
    this.id,
    required this.userId,
    required this.locationId,
    required this.openingAmount,
    this.closingAmount,
    this.closingAmountOnStaff,
    this.totalCardSlips,
    this.totalCheques,
    this.closingNote,
    this.denominations,
    this.startTime,
    this.endTime,
    this.status = 'active',
    this.isSynced = false,
  });

  factory CashierSessionModel.fromJson(Map<String, dynamic> json) {
    return CashierSessionModel(
      id: json['id'] as int?,
      userId: json['user_id'] as int? ?? 0,
      locationId: json['location_id'] as int? ?? 0,
      openingAmount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      closingAmount: json['closing_amount'] != null
          ? double.tryParse(
              json['closing_amount'].toString().replaceAll(',', ''))
          : null,
      closingAmountOnStaff: json['closing_amount_on_staff'] != null
          ? double.tryParse(
              json['closing_amount_on_staff'].toString().replaceAll(',', ''))
          : null,
      totalCardSlips: json['total_card_slips'] != null
          ? double.tryParse(
              json['total_card_slips'].toString().replaceAll(',', ''))
          : null,
      totalCheques: json['total_cheques'] != null
          ? double.tryParse(
              json['total_cheques'].toString().replaceAll(',', ''))
          : null,
      closingNote: json['closing_note'] as String?,
      denominations: json['denominations'] != null
          ? Map<String, int>.from(
              (json['denominations'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ),
            )
          : null,
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'].toString())
          : null,
      endTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'].toString())
          : null,
      status: json['status'] as String? ?? 'active',
      isSynced: (json['is_synced'] as int?) == 1 || (json['is_synced'] as bool?) == true,
    );
  }

  factory CashierSessionModel.fromDatabaseJson(Map<String, dynamic> json) {
    return CashierSessionModel(
      id: json['id'] as int?,
      userId: json['user_id'] as int? ?? 0,
      locationId: json['location_id'] as int? ?? 0,
      openingAmount: (json['opening_amount'] as num?)?.toDouble() ?? 0.0,
      closingAmount: json['closing_amount'] != null
          ? double.tryParse(json['closing_amount'].toString())
          : null,
      closingAmountOnStaff: json['closing_amount_on_staff'] != null
          ? double.tryParse(json['closing_amount_on_staff'].toString())
          : null,
      totalCardSlips: json['total_card_slips'] != null
          ? double.tryParse(json['total_card_slips'].toString())
          : null,
      totalCheques: json['total_cheques'] != null
          ? double.tryParse(json['total_cheques'].toString())
          : null,
      closingNote: json['closing_note'] as String?,
      denominations: json['denominations'] != null
          ? Map<String, int>.from(
              jsonDecode(json['denominations'] as String) as Map,
            )
          : null,
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.tryParse(json['end_time'] as String)
          : null,
      status: json['status'] as String? ?? 'active',
      isSynced: (json['is_synced'] as int?) == 1,
    );
  }

  CashierSessionModel copyWith({
    int? id,
    int? userId,
    int? locationId,
    double? openingAmount,
    double? closingAmount,
    double? closingAmountOnStaff,
    double? totalCardSlips,
    double? totalCheques,
    String? closingNote,
    Map<String, int>? denominations,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    bool? isSynced,
  }) {
    return CashierSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      locationId: locationId ?? this.locationId,
      openingAmount: openingAmount ?? this.openingAmount,
      closingAmount: closingAmount ?? this.closingAmount,
      closingAmountOnStaff: closingAmountOnStaff ?? this.closingAmountOnStaff,
      totalCardSlips: totalCardSlips ?? this.totalCardSlips,
      totalCheques: totalCheques ?? this.totalCheques,
      closingNote: closingNote ?? this.closingNote,
      denominations: denominations ?? this.denominations,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toDatabaseJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'location_id': locationId,
      'opening_amount': openingAmount,
      'closing_amount': closingAmount?.toString(),
      'closing_amount_on_staff': closingAmountOnStaff?.toString(),
      'total_card_slips': totalCardSlips?.toString(),
      'total_cheques': totalCheques?.toString(),
      'closing_note': closingNote,
      'denominations': denominations != null
          ? jsonEncode(denominations)
          : null,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status,
      'is_synced': isSynced ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'location_id': locationId,
      'amount': openingAmount,
      'closing_amount': closingAmount?.toString(),
      'closing_amount_on_staff': closingAmountOnStaff?.toString(),
      'total_card_slips': totalCardSlips?.toString(),
      'total_cheques': totalCheques?.toString(),
      'closing_note': closingNote,
      'denominations': denominations,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status,
    };
  }
}
