import '../../core/api_client.dart';
import '../../model/cashier_session_model.dart';

/// Remote data source for cashier session operations
abstract class CashierSessionRemoteDataSource {
  /// Check-in (start session)
  Future<CashierSessionModel> checkIn({
    required int locationId,
    required double amount,
  });

  /// Check-out (end session)
  Future<CashierSessionModel> checkOut({
    required double closingAmount,
    required double closingAmountOnStaff,
    required double totalCardSlips,
    required double totalCheques,
    required String closingNote,
    required Map<String, int> denominations,
  });
}

/// Implementation of CashierSessionRemoteDataSource
class CashierSessionRemoteDataSourceImpl
    implements CashierSessionRemoteDataSource {
  final ApiClient _apiClient;
  final String _checkInEndpoint;
  final String _checkOutEndpoint;

  const CashierSessionRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String checkInEndpoint,
    required String checkOutEndpoint,
  })  : _apiClient = apiClient,
        _checkInEndpoint = checkInEndpoint,
        _checkOutEndpoint = checkOutEndpoint;

  @override
  Future<CashierSessionModel> checkIn({
    required int locationId,
    required double amount,
  }) async {
    final response = await _apiClient.post(
      _checkInEndpoint,
      body: {
        'location_id': locationId.toString(),
        'amount': amount.toString(),
      },
    );

    return CashierSessionModel.fromJson(response);
  }

  @override
  Future<CashierSessionModel> checkOut({
    required double closingAmount,
    required double closingAmountOnStaff,
    required double totalCardSlips,
    required double totalCheques,
    required String closingNote,
    required Map<String, int> denominations,
  }) async {
    final response = await _apiClient.post(
      _checkOutEndpoint,
      body: {
        'closing_amount': closingAmount.toString().replaceAll(',', ''),
        'closing_amount_on_staff':
            closingAmountOnStaff.toString().replaceAll(',', ''),
        'total_card_slips': totalCardSlips.toString().replaceAll(',', ''),
        'total_cheques': totalCheques.toString().replaceAll(',', ''),
        'closing_note': closingNote,
        'denominations': denominations,
      },
    );

    return CashierSessionModel.fromJson(response);
  }
}
