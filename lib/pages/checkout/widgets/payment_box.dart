import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/checkout/view_model_manger/checkout_cubit.dart';



class PaymentBox extends StatelessWidget {
  const PaymentBox({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        return ListView.builder(
          physics: const ScrollPhysics(),
          shrinkWrap: true,
          itemCount: state.payments.length,
          itemBuilder: (context, index) {
            return Card(
              shadowColor: Colors.blue,
              margin: EdgeInsets.all(MySize.size5!),
              child: Padding(
                padding: EdgeInsets.all(MySize.size8!),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: MySize.size10!,
                  children: [
                    PaymentAmount(index: index),
                    PaymentMethodRow(
                      payment: state.payments[index],
                      index: index,
                      paymentAccounts: state.paymentAccounts,
                      paymentMethods: state.paymentMethods,
                    ),
                    PaymentNoteField(
                      payment: state.payments[index],
                      index: index,
                      canDelete: index != 0,
                      onDelete: () {
                        context
                            .read<CheckoutCubit>()
                            .removePayment(index, state.payments[index]['id']);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class PaymentAmount extends StatelessWidget {
  const PaymentAmount({super.key, required this.index});

  static ThemeData themeData = AppTheme.getThemeFromThemeMode(1);
  final int index;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      buildWhen: (previous, current) =>
      previous.payments[index]['amount'] !=
          current.payments[index]['amount'],
      builder: (context, state) {
        return Column(
          spacing: MySize.size2!,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('${AppLocalizations.of(context).translate('amount')} : ',
                style: AppTheme.getTextStyle(themeData.textTheme.bodyLarge,
                    color: themeData.colorScheme.onSurface,
                    fontWeight: 600,
                    muted: true)),
            SizedBox(
                height: MySize.size40,
                width: MySize.safeWidth! * 0.50,
                child: TextFormField(
                    decoration: InputDecoration(
                      suffix: Text(state.symbol),
                    ),
                    textAlign: TextAlign.center,
                    initialValue:
                    state.payments[index]['amount'].toStringAsFixed(2),
                    //input formatter will allow only 2 digits after decimal
                    inputFormatters: [
                      // ignore: deprecated_member_use
                      FilteringTextInputFormatter(RegExp(r'^(\d+)?\.?\d{0,2}'),
                          allow: true)
                    ],
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      context
                          .read<CheckoutCubit>()
                          .updatePaymentAmount(index, value);
                    }))
          ],
        );
      },
    );
  }
}

class PaymentMethodRow extends StatelessWidget {
  final Map<String, dynamic> payment;
  final int index;
  final List<Map<String, dynamic>> paymentMethods;
  final List<Map<String, dynamic>> paymentAccounts;

  static ThemeData themeData = AppTheme.getThemeFromThemeMode(1);

  const PaymentMethodRow({
    super.key,
    required this.payment,
    required this.index,
    required this.paymentMethods,
    required this.paymentAccounts,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${AppLocalizations.of(context).translate('payment_method')} : ',
                style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyLarge,
                    color: themeData.colorScheme.onSurface,
                    fontWeight: 600,
                    muted: true)),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: payment['method'],
                items: paymentMethods.map((method) {
                  return DropdownMenuItem<String>(
                    value: method['name'],
                    child: Text(method['value']),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    context.read<CheckoutCubit>().updatePaymentMethod(index, value);
                  }
                },
                dropdownColor: Colors.white,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${AppLocalizations.of(context).translate('payment_account')} : ',
                style: AppTheme.getTextStyle(
                    themeData.textTheme.bodyLarge,
                    color: themeData.colorScheme.onSurface,
                    fontWeight: 600,
                    muted: true)),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: payment['account_id'],
                items: paymentAccounts.map((account) {
                  return DropdownMenuItem<int>(
                    value: account['id'],
                    child: Text(account['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    context
                        .read<CheckoutCubit>()
                        .updatePaymentAccount(index, value);
                  }
                },
                dropdownColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PaymentNoteField extends StatelessWidget {
  final Map<String, dynamic> payment;
  final int index;
  final bool canDelete;
  final VoidCallback onDelete;

  const PaymentNoteField({
    super.key,
    required this.payment,
    required this.index,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: payment['note'],
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).translate('payment_note'),
            ),
            onChanged: (value) {
              final updatedPayment = Map<String, dynamic>.from(payment);
              updatedPayment['note'] = value;
              context.read<CheckoutCubit>().emitForTesting(
                context.read<CheckoutCubit>().state.copyWith(
                    payments: List.from(
                        context.read<CheckoutCubit>().state.payments)
                      ..[index] = updatedPayment),
              );
            },
          ),
        ),
        if (canDelete)
          IconButton(
            icon: const Icon(Icons.delete,color: Colors.black,),
            onPressed: onDelete,
          ),
      ],
    );
  }
}