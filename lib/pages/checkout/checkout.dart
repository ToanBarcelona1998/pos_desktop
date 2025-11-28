import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/checkout/view_model_manger/checkout_cubit.dart';

import 'widgets/add_payment_button.dart';
import 'widgets/invoice_type_section.dart';
import 'widgets/invoice_summary_widget.dart';
import 'widgets/payment_box.dart';
import 'widgets/payment_date_section.dart';
import 'widgets/shipping_section.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CheckoutCubit()
        ..init(ModalRoute.of(context)!.settings.arguments as Map),
      child: const CheckoutView(),
    );
  }
}

class CheckoutView extends StatelessWidget {
  const CheckoutView({super.key});

  static ThemeData themeData = AppTheme.getThemeFromThemeMode(1);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).translate('checkout')),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(MySize.size6!),
              child: Column(
                children: [
                  const PaymentDateSection(),
                  const PaymentBox(),
                  const AddPaymentButton(),
                  const ShippingSection(),
                  const InvoiceSummaryWidget(),
                  const InvoiceTypeSection(),
                  ElevatedButton(
                      onPressed: () async {
                        if (state.pendingAmount >= 0.01) {
                          String stat = await showDialog(
                              context: context,
                              builder: (BuildContext _) {
                                return AlertDialog(
                                  content: Text(
                                      AppLocalizations.of(context)
                                          .translate('pending_message'),
                                      style: AppTheme.getTextStyle(
                                          themeData.textTheme.bodyMedium,
                                          color:
                                              themeData.colorScheme.onSurface,
                                          fontWeight: 500,
                                          muted: true)),
                                  actions: <Widget>[
                                    TextButton(
                                        style: TextButton.styleFrom(
                                            foregroundColor:
                                                themeData.colorScheme.onPrimary,
                                            backgroundColor:
                                                themeData.colorScheme.primary),
                                        onPressed: () {
                                          Navigator.pop(context, 'ok');
                                        },
                                        child: Text(AppLocalizations.of(context)
                                            .translate('ok'))),
                                    TextButton(
                                        style: TextButton.styleFrom(
                                            foregroundColor:
                                                themeData.colorScheme.primary,
                                            backgroundColor: themeData
                                                .colorScheme.onPrimary),
                                        onPressed: () {
                                          Navigator.pop(context, 'cancel');
                                        },
                                        child: Text(AppLocalizations.of(context)
                                            .translate('cancel')))
                                  ],
                                );
                              });
                          if (stat == 'ok') {
                            await context
                                .read<CheckoutCubit>()
                                .finishInvoice(context);
                          } else {
                            return;
                          }
                        } else {
                          await context
                              .read<CheckoutCubit>()
                              .finishInvoice(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: themeData.colorScheme.primary,
                          elevation: 5),
                      child: Text(
                        AppLocalizations.of(context)
                            .translate('create_invoice'),
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.titleMedium,
                          fontWeight: 700,
                          color: themeData.colorScheme.onPrimary,
                        ),
                      ))
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
