import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/checkout/view_model_manger/checkout_cubit.dart';

class InvoiceTypeSection extends StatelessWidget {
  const InvoiceTypeSection({super.key});

  static ThemeData themeData = AppTheme.getThemeFromThemeMode(1);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      buildWhen: (previous, current) =>
          previous.invoiceType != current.invoiceType ||
          previous.printInvoice != current.printInvoice ||
          previous.printWebInvoice != current.printWebInvoice,
      builder: (context, state) {
        return Card(
          margin: EdgeInsets.all(MySize.size5!),
          child: Padding(
            padding: EdgeInsets.all(MySize.size8!),
            child: Column(
              children: [
                Row(
                  spacing: MySize.size10!,
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)
                              .translate('sell_note'),
                        ),
                        onChanged: (value) => context
                            .read<CheckoutCubit>()
                            .updateSellNote(value),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)
                              .translate('staff_note'),
                        ),
                        onChanged: (value) => context
                            .read<CheckoutCubit>()
                            .updateStaffNote(value),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(
                          AppLocalizations.of(context)
                              .translate('mobile_layout'),
                          maxLines: 2,
                          style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyMedium,
                              color:
                              themeData.colorScheme.onSurface,
                              fontWeight: 600),
                        ),
                        value: 'Mobile',
                        groupValue: state.invoiceType,
                        onChanged: (value) => context
                            .read<CheckoutCubit>()
                            .updateInvoiceType(value!),
                        toggleable: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(
                          AppLocalizations.of(context)
                              .translate('web_layout'),
                          maxLines: 2,
                          style: AppTheme.getTextStyle(
                              themeData.textTheme.bodyMedium,
                              color:
                              themeData.colorScheme.onSurface,
                              fontWeight: 600),
                        ),
                        value: 'Web',
                        groupValue: state.invoiceType,
                        onChanged: (value) => context
                            .read<CheckoutCubit>()
                            .updateInvoiceType(value!),
                        toggleable: true,
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  title: Text(
                    AppLocalizations.of(context).translate('print_invoice'),
                  ),
                  value: state.printInvoice,
                  onChanged: (value) =>
                      context.read<CheckoutCubit>().setPrintInvoice(value!),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
