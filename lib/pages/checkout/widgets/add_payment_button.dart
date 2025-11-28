import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/checkout/view_model_manger/checkout_cubit.dart';

class AddPaymentButton extends StatelessWidget {
  const AddPaymentButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      buildWhen: (previous, current) =>
      previous.paymentMethods != current.paymentMethods,
      builder: (context, state) {
        return ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context).translate('add_payment')),
          onPressed: () {
            if (state.paymentMethods.isNotEmpty) {
              context.read<CheckoutCubit>().addPayment(
                0.0,
                state.paymentMethods[0]['name'],
                state.paymentMethods[0]['account_id'],
              );
            }
          },
        );
      },
    );
  }
}