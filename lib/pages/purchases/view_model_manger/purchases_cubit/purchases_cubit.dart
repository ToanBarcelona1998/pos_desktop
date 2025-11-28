import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/apis/purchases.dart';
import 'package:pos_final/helpers/api_handler/api_response.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/models/purchases_model.dart';
import 'package:pos_final/pages/purchases/widgets/purchases_widget.dart';
import 'package:provider/provider.dart';

part 'purchases_state.dart';

class PurchasesCubit extends Cubit<PurchasesState> {
  PurchasesCubit() : super(PurchasesInitial());

  Future<void> getPurchases(BuildContext context) async {
    emit(PurchasesGetDataLoading());
    ApiResponse apiResponse = await PurchasesService().getPurchases();
    if (apiResponse.response?.statusCode == 200) {
      List<Purchase> purchases =
          PurchaseData.fromJson(apiResponse.response!.data).purchases;
      emit(PurchasesGetDataSuccessful(purchases));
    } else {
      emit(PurchasesGetDataFailed());
    }
  }

  List<PurchaseWidgetParameters> makeParameters(
      BuildContext context, List<Purchase> purchases) {
    bool isEnglish =
        Provider.of<AppLanguage>(context, listen: false).appLocal ==
            const Locale('en');
    onTap() {}
    List<PurchaseWidgetParameters> parameters = [];
    for (Purchase purchaseItem in purchases) {
      parameters.add(PurchaseWidgetParameters(
          isEnglish: isEnglish,
          invoiceStatus: purchaseItem.paymentStatus,
          addedFrom: purchaseItem.addedBy,
          dueBill: purchaseItem.finalTotal,
          refNo: purchaseItem.refNo,
          onTap: onTap));
    }
    return parameters;
  }
}
