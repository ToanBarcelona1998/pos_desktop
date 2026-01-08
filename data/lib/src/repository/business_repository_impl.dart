import 'dart:convert';

import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../data_source/local/system_local_data_source.dart';
import '../data_source/remote/business_remote_data_source.dart';
import '../model/business_model.dart';

/// Implementation of [BusinessRepository]
class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessRemoteDataSource _remoteDataSource;
  final SystemLocalDataSource _localDataSource;

  const BusinessRepositoryImpl({
    required BusinessRemoteDataSource remoteDataSource,
    required SystemLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Result<BusinessEntity>> getBusinessDetails() async {
    final localResult = await getLocalBusinessDetails();

    return localResult.fold(
      onSuccess: (business) async{
        if (business == null) {
          try{
            final business = await _remoteDataSource.getBusinessDetails();
            return Success(_mapToEntity(business));
          }catch(e){
            return Error(ExceptionHandler.handleException(e));
          }
        }
        return Success(business);
      },
      onError: (failure) => Error(ExceptionHandler.handleException(failure)),
    );
  }

  @override
  Future<Result<void>> syncBusinessDetails() async {
    try {
      final business = await _remoteDataSource.getBusinessDetails();
      await _localDataSource.insert('business', jsonEncode([business.toJson()]));
      return const Success(null);
    } catch (e) {
      Logger.logE('Error syncing business details', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<BusinessEntity?>> getLocalBusinessDetails() async {
    try {
      final data = await _localDataSource.get('business');
      if (data == null) {
        return const Success(null);
      }

      final List<dynamic> businessList = data is String ? jsonDecode(data) : data;
      if (businessList.isEmpty) {
        return const Success(null);
      }

      final model = BusinessModel.fromJson(businessList.first as Map<String, dynamic>);
      return Success(_mapToEntity(model));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  BusinessEntity _mapToEntity(BusinessModel model) {
    return BusinessEntity(
      id: model.id,
      name: model.name,
      currencyId: model.currencyId,
      currencySymbol: model.currencySymbol,
      currencyPrecision: model.currencyPrecision,
      logo: model.logo,
      timeZone: model.timeZone,
      fiscalYearStartMonth: model.fiscalYearStartMonth,
      accountingMethod: model.accountingMethod,
      defaultSalesDiscount: model.defaultSalesDiscount,
      sellPriceTax: model.sellPriceTax,
      defaultProfitPercent: model.defaultProfitPercent,
      ownerId: model.ownerId,
      isActive: model.isActive == 1,
      createdAt: model.createdAt != null ? DateTime.tryParse(model.createdAt!) : null,
      updatedAt: model.updatedAt != null ? DateTime.tryParse(model.updatedAt!) : null,
      quantityPrecision: model.quantityPrecision,
      dateFormat: model.dateFormat,
      timeFormat: model.timeFormat,
      currencySymbolPlacement: model.currencySymbolPlacement,
      startDate: model.startDate,
      taxNumber1: model.taxNumber1,
      taxLabel1: model.taxLabel1,
      taxNumber2: model.taxNumber2,
      taxLabel2: model.taxLabel2,
      defaultSalesTax: model.defaultSalesTax,
      skuPrefix: model.skuPrefix,
      enableProductExpiry: (model.enableProductExpiry ?? 0) == 1,
      expiryType: model.expiryType,
      onProductExpiry: model.onProductExpiry,
      stopSellingBefore: model.stopSellingBefore,
      enableTooltip: (model.enableTooltip ?? 0) == 1,
      purchaseInDiffCurrency: (model.purchaseInDiffCurrency ?? 0) == 1,
      purchaseCurrencyId: model.purchaseCurrencyId,
      pExchangeRate: model.pExchangeRate,
      transactionEditDays: model.transactionEditDays,
      stockExpiryAlertDays: model.stockExpiryAlertDays,
      enableBrand: (model.enableBrand ?? 0) == 1,
      enableCategory: (model.enableCategory ?? 0) == 1,
      enableSubCategory: (model.enableSubCategory ?? 0) == 1,
      enablePriceTax: (model.enablePriceTax ?? 0) == 1,
      enablePurchaseStatus: (model.enablePurchaseStatus ?? 0) == 1,
      enableLotNumber: (model.enableLotNumber ?? 0) == 1,
      defaultUnit: model.defaultUnit,
      enableSubUnits: (model.enableSubUnits ?? 0) == 1,
      enableRacks: (model.enableRacks ?? 0) == 1,
      enableRow: (model.enableRow ?? 0) == 1,
      enablePosition: (model.enablePosition ?? 0) == 1,
      enableEditingProductFromPurchase: (model.enableEditingProductFromPurchase ?? 0) == 1,
      salesCmsnAgnt: model.salesCmsnAgnt,
      itemAdditionMethod: model.itemAdditionMethod,
      enableInlineTax: (model.enableInlineTax ?? 0) == 1,
      enabledModules: model.enabledModules,
      refNoPrefixes: model.refNoPrefixes,
      themeColor: model.themeColor,
      createdBy: model.createdBy,
      enableRp: (model.enableRp ?? 0) == 1,
      rpName: model.rpName,
      amountForUnitRp: model.amountForUnitRp,
      minOrderTotalForRp: model.minOrderTotalForRp,
      maxRpPerOrder: model.maxRpPerOrder,
      redeemAmountPerUnitRp: model.redeemAmountPerUnitRp,
      minOrderTotalForRedeem: model.minOrderTotalForRedeem,
      minRedeemPoint: model.minRedeemPoint,
      maxRedeemPoint: model.maxRedeemPoint,
      rpExpiryPeriod: model.rpExpiryPeriod,
      rpExpiryType: model.rpExpiryType,
    );
  }
}












