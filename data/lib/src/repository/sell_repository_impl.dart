import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/local/sell_local_data_source.dart';
import '../data_source/remote/sell_remote_data_source.dart';
import '../model/sell_model.dart';

/// Implementation of [SellRepository]
/// Implements offline-first approach: always saves locally first, then syncs if online
class SellRepositoryImpl implements SellRepository {
  final SellRemoteDataSource _remoteDataSource;
  final SellLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  const SellRepositoryImpl({
    required SellRemoteDataSource remoteDataSource,
    required SellLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Result<SellEntity>> createSell(SellEntity sell) async {
    try {
      // Always save locally first (offline-first)
      final sellData = _entityToMap(sell);
      final sellLines = sell.sellLines.map(_sellLineToMap).toList();
      final payments = sell.payments.map(_paymentToMap).toList();

      // Determine if this is a final or suspended sale (affects stock update)
      final isFinalOrSuspended = (sell.status == 'final' || sell.isSuspend);

      // Save to local database
      final sellId = await _localDataSource.saveSell(
        sellData: sellData,
        sellLines: sellLines,
        payments: payments,
        isFinalOrSuspended: isFinalOrSuspended,
      );

      // Get the saved sell
      final savedSell = await _localDataSource.getSellById(sellId);
      if (savedSell == null) {
        return const Error(UnknownFailure(message: 'Failed to save sell locally'));
      }

      // Map to entity
      final sellLinesData = await _localDataSource.getSellLines(sellId);
      final paymentsData = await _localDataSource.getPayments(sellId);
      final entity = _mapToEntityFromLocal(savedSell, sellLinesData, paymentsData);

      // Sync to API in background if online (non-blocking)
      if (await _networkInfo.isConnected) {
        _syncSellInBackground(sellId);
      }

      return Success(entity);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  /// Sync a sell to API in background
  void _syncSellInBackground(int sellId) {
    syncSellById(sellId).catchError((e) {
      print('Background sell sync error: $e');
    });
  }

  /// Sync a specific sell by ID
  Future<void> syncSellById(int sellId) async {
    try {
      if (!await _networkInfo.isConnected) return;

      final sell = await _localDataSource.getSellById(sellId);
      if (sell == null || sell['is_synced'] == 1) return;

      final sellLines = await _localDataSource.getSellLines(sellId);
      final payments = await _localDataSource.getPayments(sellId);

      // Format products for API (like old code)
      final formattedProducts = sellLines.map((p) => {
        'product_id': p['product_id'],
        'variation_id': p['variation_id'],
        'quantity': p['quantity'],
        'unit_price': p['unit_price'],
        'tax_rate_id': p['tax_rate_id'] == 0 ? null : p['tax_rate_id'],
        'discount_amount': p['discount_amount'] ?? 0.0,
        'discount_type': p['discount_type'] ?? 'fixed',
      }).toList();

      // Format payments for API
      final formattedPayments = payments.map((p) => {
        'method': p['method'],
        'amount': p['amount'],
        'note': p['note'] ?? '',
        'account_id': p['account_id'],
        'is_return': p['is_return'] ?? 0,
        'card_number': p['card_number'],
        'card_type': p['card_type'],
        'card_holder_name': p['card_holder_name'],
      }).toList();

      // Prepare API data (like old code format)
      final sellData = {
        'location_id': sell['location_id'],
        'contact_id': sell['contact_id'],
        'transaction_date': sell['transaction_date'],
        'invoice_no': sell['invoice_no'],
        'status': sell['status'],
        'sub_status': sell['is_quotation'] == 1 ? 'quotation' : null,
        'tax_rate_id': sell['tax_rate_id'] == 0 ? null : sell['tax_rate_id'],
        'discount_amount': sell['discount_amount'] ?? 0.0,
        'discount_type': sell['discount_type'] ?? 'fixed',
        'change_return': sell['change_return'] ?? 0.0,
        'products': formattedProducts,
        'sale_note': sell['sale_note'],
        'staff_note': sell['staff_note'],
        'is_quotation': sell['is_quotation'] ?? 0,
        'is_suspend': sell['is_suspend'] ?? 0,
        'payments': formattedPayments,
      };

      SellModel model;
      if (sell['transaction_id'] != null) {
        // Update existing
        model = await _remoteDataSource.updateSell(
          sell['transaction_id'] as int,
          sellData,
        );
      } else {
        // Create new - API expects {'sells': [sellData]}
        model = await _remoteDataSource.createSell({'sells': [sellData]});
      }

      // Update local sell after successful sync
      await _localDataSource.updateSellAfterSync(sellId, {
        'is_synced': 1,
        'transaction_id': model.id,
        'invoice_url': model.invoiceUrl,
        'status': model.status,
        'is_quotation': model.isQuotation,
        'is_suspend': model.isSuspend,
        'payment_lines': model.paymentLines,
      });
    } catch (e) {
      print('Error syncing sell $sellId: $e');
      // Don't throw - allow retry later
    }
  }

  @override
  Future<Result<SellEntity>> updateSell(SellEntity sell) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final data = _entityToMap(sell);
      final model = await _remoteDataSource.updateSell(sell.id, data);
      return Success(_mapToEntity(model));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> deleteSell(int id) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      await _remoteDataSource.deleteSell(id);
      await _localDataSource.deleteSell(id);
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<SellEntity>> getSellById(int id) async {
    // Try local first
    try {
      final localSell = await _localDataSource.getSellById(id);
      if (localSell != null) {
        final sellLines = await _localDataSource.getSellLines(id);
        final payments = await _localDataSource.getPayments(id);
        final entity = _mapToEntityFromLocal(localSell, sellLines, payments);
        return Success(entity);
      }
    } catch (e) {
      print('Error getting local sell: $e');
    }

    // If not found locally and online, try remote
    if (await _networkInfo.isConnected) {
      try {
        final sells = await _remoteDataSource.getSpecifiedSells([id]);
        if (sells.isNotEmpty) {
          return Success(_mapToEntity(sells.first));
        }
      } catch (e) {
        return Error(ExceptionHandler.handleException(e));
      }
    }

    return const Error(NotFoundFailure(message: 'Sell not found'));
  }

  @override
  Future<Result<List<SellEntity>>> getSellsByIds(List<int> ids) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final sells = await _remoteDataSource.getSpecifiedSells(ids);
      return Success(sells.map(_mapToEntity).toList());
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<SellEntity>>> getLocalSells() async {
    try {
      final sells = await _localDataSource.getUnsyncedSells();
      final entities = <SellEntity>[];

      for (var sell in sells) {
        final sellLines = await _localDataSource.getSellLines(sell['id'] as int);
        final payments = await _localDataSource.getPayments(sell['id'] as int);
        entities.add(_mapToEntityFromLocal(sell, sellLines, payments));
      }

      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> syncSells() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final unsyncedSells = await _localDataSource.getUnsyncedSells();
      for (var sell in unsyncedSells) {
        await syncSellById(sell['id'] as int);
      }
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<SellEntity>> saveSellLocally(SellEntity sell) async {
    try {
      final sellData = _entityToMap(sell);
      final sellLines = sell.sellLines.map(_sellLineToMap).toList();
      final payments = sell.payments.map(_paymentToMap).toList();

      final isFinalOrSuspended = (sell.status == 'final' || sell.isSuspend);

      final sellId = await _localDataSource.saveSell(
        sellData: sellData,
        sellLines: sellLines,
        payments: payments,
        isFinalOrSuspended: isFinalOrSuspended,
      );

      final savedSell = await _localDataSource.getSellById(sellId);
      if (savedSell == null) {
        return const Error(UnknownFailure(message: 'Failed to save sell locally'));
      }

      final sellLinesData = await _localDataSource.getSellLines(sellId);
      final paymentsData = await _localDataSource.getPayments(sellId);
      final entity = _mapToEntityFromLocal(savedSell, sellLinesData, paymentsData);

      return Success(entity);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<SellEntity>>> getDraftSells() async {
    // Drafts are sells with is_completed = 0 in sell_lines
    // For now, return empty - can be implemented if needed
    return const Success([]);
  }

  @override
  Future<Result<List<SellEntity>>> getQuotations() async {
    try {
      final quotations = await _localDataSource.getQuotations();
      final entities = <SellEntity>[];

      for (var quotation in quotations) {
        final sellLines = await _localDataSource.getSellLines(quotation['id'] as int);
        final payments = await _localDataSource.getPayments(quotation['id'] as int);
        entities.add(_mapToEntityFromLocal(quotation, sellLines, payments));
      }

      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<SellEntity>>> getSuspendedSells() async {
    try {
      final suspended = await _localDataSource.getSuspendedSells();
      final entities = <SellEntity>[];

      for (var sell in suspended) {
        final sellLines = await _localDataSource.getSellLines(sell['id'] as int);
        final payments = await _localDataSource.getPayments(sell['id'] as int);
        entities.add(_mapToEntityFromLocal(sell, sellLines, payments));
      }

      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  SellEntity _mapToEntity(SellModel model) {
    return SellEntity(
      id: model.id,
      transactionDate: model.transactionDate,
      invoiceNo: model.invoiceNo,
      contactId: model.contactId,
      locationId: model.locationId,
      status: model.status,
      discountAmount: model.discount,
      isQuotation: model.isQuotation == 1,
      isSuspend: model.isSuspend == 1,
      invoiceAmount: model.finalTotal,
      changeReturn: model.changeReturn,
      invoiceUrl: model.invoiceUrl,
      isSynced: true,
      transactionId: model.id,
    );
  }

  SellEntity _mapToEntityFromLocal(
    Map<String, dynamic> sell,
    List<Map<String, dynamic>> sellLines,
    List<Map<String, dynamic>> payments,
  ) {
    return SellEntity(
      id: sell['id'] as int,
      transactionDate: sell['transaction_date'] as String?,
      invoiceNo: sell['invoice_no'] as String?,
      contactId: sell['contact_id'] as int?,
      locationId: sell['location_id'] as int?,
      status: sell['status'] as String?,
      taxRateId: sell['tax_rate_id'] as int?,
      discountAmount: (sell['discount_amount'] as num?)?.toDouble(),
      discountType: sell['discount_type'] as String?,
      saleNote: sell['sale_note'] as String?,
      staffNote: sell['staff_note'] as String?,
      isQuotation: (sell['is_quotation'] as int? ?? 0) == 1,
      isSuspend: (sell['is_suspend'] as int? ?? 0) == 1,
      invoiceAmount: (sell['invoice_amount'] as num?)?.toDouble(),
      changeReturn: (sell['change_return'] as num?)?.toDouble(),
      pendingAmount: (sell['pending_amount'] as num?)?.toDouble(),
      isSynced: (sell['is_synced'] as int? ?? 0) == 1,
      transactionId: sell['transaction_id'] as int?,
      invoiceUrl: sell['invoice_url'] as String?,
      sellLines: sellLines.map((line) {
        return SellLineEntity(
          id: line['id'] as int,
          sellId: line['sell_id'] as int?,
          productId: line['product_id'] as int?,
          variationId: line['variation_id'] as int?,
          quantity: (line['quantity'] as num?)?.toDouble(),
          unitPrice: (line['unit_price'] as num?)?.toDouble(),
          taxRateId: line['tax_rate_id'] as int?,
          discountAmount: (line['discount_amount'] as num?)?.toDouble(),
          discountType: line['discount_type'] as String?,
          note: line['note'] as String?,
        );
      }).toList(),
      payments: payments.map((payment) {
        return SellPaymentEntity(
          id: payment['id'] as int,
          sellId: payment['sell_id'] as int?,
          paymentId: payment['payment_id'] as int?,
          method: payment['method'] as String?,
          amount: (payment['amount'] as num?)?.toDouble(),
          note: payment['note'] as String?,
          accountId: payment['account_id'] as int?,
          isReturn: (payment['is_return'] as int? ?? 0) == 1,
          transactionDate: payment['transaction_date'] as String?,
        );
      }).toList(),
    );
  }

  Map<String, dynamic> _entityToMap(SellEntity entity) {
    return {
      if (entity.transactionDate != null) 'transaction_date': entity.transactionDate,
      if (entity.invoiceNo != null) 'invoice_no': entity.invoiceNo,
      if (entity.contactId != null) 'contact_id': entity.contactId,
      if (entity.locationId != null) 'location_id': entity.locationId,
      if (entity.status != null) 'status': entity.status,
      if (entity.taxRateId != null) 'tax_rate_id': entity.taxRateId,
      if (entity.discountAmount != null) 'discount_amount': entity.discountAmount,
      if (entity.discountType != null) 'discount_type': entity.discountType,
      if (entity.invoiceAmount != null) 'invoice_amount': entity.invoiceAmount,
      if (entity.changeReturn != null) 'change_return': entity.changeReturn,
      if (entity.pendingAmount != null) 'pending_amount': entity.pendingAmount,
      if (entity.saleNote != null) 'sale_note': entity.saleNote,
      if (entity.staffNote != null) 'staff_note': entity.staffNote,
      'is_quotation': entity.isQuotation ? 1 : 0,
      'is_suspend': entity.isSuspend ? 1 : 0,
    };
  }

  Map<String, dynamic> _sellLineToMap(SellLineEntity line) {
    return {
      if (line.productId != null) 'product_id': line.productId,
      if (line.variationId != null) 'variation_id': line.variationId,
      if (line.quantity != null) 'quantity': line.quantity,
      if (line.unitPrice != null) 'unit_price': line.unitPrice,
      if (line.taxRateId != null) 'tax_rate_id': line.taxRateId,
      if (line.discountAmount != null) 'discount_amount': line.discountAmount,
      if (line.discountType != null) 'discount_type': line.discountType,
      if (line.note != null) 'note': line.note,
    };
  }

  Map<String, dynamic> _paymentToMap(SellPaymentEntity payment) {
    return {
      if (payment.method != null) 'method': payment.method,
      if (payment.amount != null) 'amount': payment.amount,
      if (payment.note != null) 'note': payment.note,
      if (payment.accountId != null) 'account_id': payment.accountId,
      'is_return': payment.isReturn ? 1 : 0,
      if (payment.transactionDate != null) 'transaction_date': payment.transactionDate,
      if (payment.paymentId != null) 'payment_id': payment.paymentId,
    };
  }
}
