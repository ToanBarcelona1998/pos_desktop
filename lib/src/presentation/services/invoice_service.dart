import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;

import '../../../../app_config/di.dart';

/// Service for fetching invoice HTML from URL
class InvoiceService {
  final SellRepository _sellRepository;

  InvoiceService({SellRepository? sellRepository})
      : _sellRepository = sellRepository ?? sl.get<SellRepository>();

  /// Fetch invoice HTML from URL if available
  /// Returns the HTML string if successful, null otherwise
  Future<String?> fetchInvoiceHtml(int sellId) async {
    try {
      // Get sell from repository
      final sellResult = await _sellRepository.getSellById(sellId);
      
      return await sellResult.fold(
        onSuccess: (sell) async {
          if (sell.invoiceUrl != null && sell.invoiceUrl!.isNotEmpty) {
            try {
              // Fetch HTML from URL
              final response = await http.Client().get(Uri.parse(sell.invoiceUrl!));
              if (response.statusCode == 200) {
                return response.body;
              }
            } catch (e) {
              // If fetching fails, return null to use local generation
              return null;
            }
          }
          return null;
        },
        onError: (_) => null,
      );
    } catch (e) {
      // If any error occurs, return null to use local generation
      return null;
    }
  }
}

