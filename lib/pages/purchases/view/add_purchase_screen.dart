import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/purchases/components/custom_drop_down_button.dart';
import 'package:pos_final/pages/purchases/components/custom_text_form_field.dart';
import 'package:pos_final/pages/purchases/view_model_manger/add_purchase_cubit/add_purchase_cubit.dart';

class AddPurchasesScreen extends StatelessWidget {
  const AddPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddPurchaseCubit()..getData(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).translate('add_purchase')),
          centerTitle: true,
        ),
        body: BlocBuilder<AddPurchaseCubit, AddPurchaseState>(
          builder: (context, state) {
            AddPurchaseCubit cubit = BlocProvider.of(context);
            if (state is GetDataSuccessful) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Form(
                    key: cubit.formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomDropDownButton<int>(
                                titleText: AppLocalizations.of(context)
                                    .translate('select_supplier'),
                                items: cubit.supplierNameItems(),
                                onChanged: cubit.selectSupplier,
                                validator: (p0) {
                                if(p0 == null){
                                  return AppLocalizations.of(context).translate('not_empty');
                                }
                                return null;
                                },
                              ),
                            ),
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
                                                    onDateTimeChanged:
                                                        cubit.onDateTimeChanged),
                                              ),
                                              OverflowBar(
                                                alignment:
                                                    MainAxisAlignment.spaceAround,
                                                children: [
                                                  ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text(AppLocalizations
                                                              .of(context)
                                                          .translate('cancel'))),
                                                  ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text(
                                                          AppLocalizations.of(
                                                                  context)
                                                              .translate('ok'))),
                                                ],
                                              )
                                            ],
                                          ),
                                        ));
                              },
                              child: CustomTextField(
                                isEnabled: false,
                                filled: true,
                                controller: cubit.purchaseDateController,
                                hintText: DateFormat('yyyy-MM-dd hh:mm:ss')
                                    .format(DateTime.now()),
                                maxLines: 2,
                                titleText: AppLocalizations.of(context)
                                    .translate('purchase_date'),
                              ),
                            ))
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                  child: CustomDropDownButton<int>(
                                titleText: AppLocalizations.of(context)
                                    .translate('location_nname'),
                                items: cubit.locationNameItems(),
                                onChanged: cubit.selectLocation,
                                    validator: (p0) {
                                      if(p0 == null){
                                        return AppLocalizations.of(context).translate('not_empty');
                                      }
                                      return null;
                                    },
                              )),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                  child: CustomDropDownButton<String>(
                                titleText: AppLocalizations.of(context)
                                    .translate('invoice_status'),
                                items: cubit.invoiceStatusItems(context),
                                onChanged: cubit.selectInvoiceStatus,
                                    validator: (p0) {
                                      if(p0 == null){
                                        return AppLocalizations.of(context).translate('not_empty');
                                      }
                                      return null;
                                    },
                              ))
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: CustomTextField(
                            filled: false,
                            inputType: TextInputType.number,
                            controller: cubit.shippingChargesController,
                            titleText: AppLocalizations.of(context)
                                .translate('shipping_charges'),
                            hintText: '0.0',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: CustomDropDownButton<String>(
                                  titleText: AppLocalizations.of(context)
                                      .translate('discount_type'),
                                  items: cubit.discountTypeItems(context),
                                  onChanged: cubit.selectDiscountType,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: CustomTextField(
                                  filled: false,
                                  inputType: TextInputType.number,
                                  controller: cubit.discountController,
                                  titleText: AppLocalizations.of(context)
                                      .translate('discount_amount'),
                                  hintText: '0.0',
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 50,
                        ),
                        ElevatedButton(
                            onPressed: () {
                              cubit.navigateToProductsSelection(context);
                            },
                            child: Text(
                                AppLocalizations.of(context).translate('next')))
                      ],
                    ),
                  ),
                ),
              );
            } else if (state is GetDataFailed) {
              return Helper().noDataWidget(context);
            }
            return Helper().loadingIndicator(context);
          },
        ),
      ),
    );
  }
}
