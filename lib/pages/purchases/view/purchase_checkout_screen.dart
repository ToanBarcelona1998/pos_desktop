import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/purchases/components/custom_drop_down_button.dart';
import 'package:pos_final/pages/purchases/components/custom_text_form_field.dart';
import 'package:pos_final/pages/purchases/parameters_model/add_purchase_parameters.dart';
import 'package:pos_final/pages/purchases/view_model_manger/purchase_checkout_cubit/purchase_checkout_cubit.dart';
import 'package:pos_final/pages/purchases/widgets/credit_card_data_widget.dart';
import 'package:pos_final/pages/purchases/widgets/fixed_header_data_table_widget.dart';

class PurchaseCheckoutScreen extends StatelessWidget {
  const PurchaseCheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    PurchasesParameters purchasesParameters =
        ModalRoute.of(context)!.settings.arguments as PurchasesParameters;
    return BlocProvider(
      create: (context) => PurchaseCheckoutCubit(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).translate('checkout')),
          centerTitle: true,
        ),
        body: BlocConsumer<PurchaseCheckoutCubit, PurchaseCheckoutState>(
          listener: (context, state) {
            if (state is CheckOutFailedState) {
              Fluttertoast.showToast(
                  backgroundColor: Colors.red,
                  msg: AppLocalizations.of(context)
                      .translate('purchase_failed'));
            } else if (state is CheckOutSuccessState) {
              Fluttertoast.showToast(
                  backgroundColor: Colors.green,
                  msg: AppLocalizations.of(context)
                      .translate('purchase_success'));
            }
          },
          builder: (context, state) {
            PurchaseCheckoutCubit cubit = BlocProvider.of(context);
            cubit.purchaseParameters = purchasesParameters;
            return Form(
              key: cubit.formKey,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      FixedHeaderDataTableWidget(
                        columns: cubit.makeTableColumns(context),
                        cells:
                            cubit.makeTableCells(purchasesParameters.products!),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: CustomDropDownButton<PaymentWay>(
                          titleText: AppLocalizations.of(context)
                              .translate('payments'),
                          items: cubit.paymentItems(context),
                          onChanged: cubit.selectPaymentWay,
                        ),
                      ),
                      Visibility(
                        visible: cubit.paymentWay != PaymentWay.none,
                        child: Row(
                          children: [
                            Expanded(
                                child: CustomTextField(
                              controller: cubit.paymentAmountController,
                              hintText: '0.0',
                              maxLines: 1,
                              inputType: TextInputType.number,
                              titleText: AppLocalizations.of(context)
                                  .translate('payment_amount'),
                              validator: (p0) {
                                if (p0 == null || p0.isEmpty) {
                                  return AppLocalizations.of(context)
                                      .translate('not_empty');
                                }

                                return null;
                              },
                            )),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                                child: GestureDetector(
                              onTap: () {
                                showCupertinoModalPopup(
                                    context: context,
                                    builder: (_) => Container(
                                          height: 300,
                                          color: Colors.white,
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: 230,
                                                child: CupertinoDatePicker(
                                                    initialDateTime:
                                                        DateTime.now(),
                                                    onDateTimeChanged: cubit
                                                        .onDateTimeChanged),
                                                  ),
                                                  OverflowBar(
                                                    alignment: MainAxisAlignment
                                                        .spaceAround,
                                                    children: [
                                                  ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text(
                                                          AppLocalizations.of(
                                                                  context)
                                                              .translate(
                                                                  'cancel'))),
                                                  ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text(
                                                          AppLocalizations.of(
                                                                  context)
                                                              .translate(
                                                                  'ok'))),
                                                ],
                                              )
                                            ],
                                          ),
                                        ));
                              },
                              child: CustomTextField(
                                isEnabled: false,
                                filled: true,
                                controller: cubit.paymentDateController,
                                hintText: DateFormat('yyyy-MM-dd hh:mm:ss')
                                    .format(DateTime.now()),
                                maxLines: 2,
                                titleText: AppLocalizations.of(context)
                                    .translate('payment_date'),
                              ),
                            ))
                          ],
                        ),
                      ),
                      switch (cubit.paymentWay) {
                        PaymentWay.cheque => CustomTextField(
                            controller: cubit.chequeNumberController,
                            hintText: AppLocalizations.of(context)
                                .translate('cheque_number'),
                            validator: (p0) {
                              if (cubit.paymentWay != PaymentWay.cheque) {
                                return null;
                              }
                              if (p0 == null || p0.isEmpty) {
                                return AppLocalizations.of(context)
                                    .translate('not_empty');
                              }

                              return null;
                            },
                            maxLines: 1,
                            titleText: AppLocalizations.of(context)
                                .translate('cheque_number'),
                          ),
                        PaymentWay.bankTransfer => CustomTextField(
                            controller: cubit.bankAccountNumberController,
                            hintText: AppLocalizations.of(context)
                                .translate('bank_number'),
                            validator: (p0) {
                              if (cubit.paymentWay != PaymentWay.bankTransfer) {
                                return null;
                              }
                              if (p0 == null || p0.isEmpty) {
                                return AppLocalizations.of(context)
                                    .translate('not_empty');
                              }

                              return null;
                            },
                            maxLines: 1,
                            titleText: AppLocalizations.of(context)
                                .translate('bank_number'),
                          ),
                        PaymentWay.card => const CreditCardDataWidget(),
                        _ => const SizedBox.shrink()
                      },
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: state is CheckOutLoadingState
                            ? Helper().loadingIndicator(context)
                            : ElevatedButton(
                                onPressed: cubit.checkOutPressed,
                                child: Text(AppLocalizations.of(context)
                                    .translate('checkout'))),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
