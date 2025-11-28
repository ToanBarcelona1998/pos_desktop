import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/checkout/view_model_manger/checkout_cubit.dart';

class InvoiceSummaryWidget extends StatelessWidget {
  const InvoiceSummaryWidget({super.key});

  static ThemeData themeData = AppTheme.getThemeFromThemeMode(1);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      buildWhen: (previous, current) =>
          previous.invoiceAmount != current.invoiceAmount ||
          previous.totalPaying != current.totalPaying ||
          previous.changeReturn != current.changeReturn ||
          previous.pendingAmount != current.pendingAmount,
      builder: (context, state) {
        return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            padding: EdgeInsets.only(
                left: MySize.size16!,
                right: MySize.size16!,
                top: MySize.size16!),
            mainAxisSpacing: MySize.size16!,
            childAspectRatio: 8 / 3,
            crossAxisSpacing: MySize.size16!,
            children: [
              BlockItem(
                  subject:
                      '${AppLocalizations.of(context).translate('total_payble')} : ',
                  amount: Helper().formatCurrency(state.invoiceAmount),
                  symbol: state.symbol,
                  textColor: themeData.colorScheme.onSurface),
              BlockItem(
                  subject:
                      '${AppLocalizations.of(context).translate('total_paying')} : ',
                  amount: Helper().formatCurrency(state.totalPaying),
                  symbol: state.symbol,
                  textColor: themeData.colorScheme.onSurface),
              BlockItem(
                  subject:
                      '${AppLocalizations.of(context).translate('change_return')} : ',
                  amount: Helper().formatCurrency(state.changeReturn),
                  symbol: state.symbol,
                  textColor: (state.changeReturn >= 0.01)
                      ? Colors.red
                      : themeData.colorScheme.onSurface),
              BlockItem(
                  subject:
                      '${AppLocalizations.of(context).translate('balance')} : ',
                  amount: Helper().formatCurrency(state.pendingAmount),
                  symbol: state.symbol,
                  textColor: (state.pendingAmount >= 0.01)
                      ? Colors.red
                      : themeData.colorScheme.onSurface),
            ]);
      },
    );
  }
}

class BlockItem extends StatelessWidget {
  const BlockItem(
      {super.key,
      required this.subject,
      required this.amount,
      required this.symbol,
      required this.textColor});

  static ThemeData themeData = AppTheme.getThemeFromThemeMode(1);
  final String subject, amount, symbol;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MySize.size8!),
      ),
      child: SizedBox(
        height: MySize.size30,
        child: Container(
          padding: EdgeInsets.all(MySize.size2!),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                subject,
                style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge,
                    color: themeData.colorScheme.onSurface,
                    fontWeight: 800,
                    fontSize: 10,
                    muted: true),
              ),
              Text(
                "$amount $symbol",
                overflow: TextOverflow.ellipsis,
                style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge,
                    color: textColor, fontWeight: 600, muted: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
