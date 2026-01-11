import '../core/entity.dart';

/// Cashier session entity representing a cashier work session
class CashierSessionEntity extends Entity {
  final int? id;
  final int userId;
  final int locationId;
  final double openingAmount; // Số tiền vào ca
  final double? closingAmount; // Tổng tiền đóng ca
  final double? closingAmountOnStaff; // Tiền mặt đóng ca
  final double? totalCardSlips; // Tổng thẻ
  final double? totalCheques; // Tổng séc
  final String? closingNote; // Ghi chú đóng ca
  final Map<String, int>? denominations; // Mệnh giá và số lượng
  final DateTime? startTime; // Thời gian vào ca
  final DateTime? endTime; // Thời gian đóng ca
  final String status; // "active", "closed"
  final bool isSynced; // Đã sync chưa

  const CashierSessionEntity({
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

  @override
  List<Object?> get props => [
        id,
        userId,
        locationId,
        openingAmount,
        closingAmount,
        closingAmountOnStaff,
        totalCardSlips,
        totalCheques,
        closingNote,
        status,
        isSynced,
      ];

  bool get isActive => status == 'active';

  CashierSessionEntity copyWith({
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
    return CashierSessionEntity(
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
}
