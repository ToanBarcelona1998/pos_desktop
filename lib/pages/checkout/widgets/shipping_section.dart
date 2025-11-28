import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/checkout/view_model_manger/checkout_cubit.dart';

class ShippingSection extends StatelessWidget {
  const ShippingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      buildWhen: (previous, current) =>
      previous.shippingCharges != current.shippingCharges ||
          previous.shippingDetails != current.shippingDetails,
      builder: (context, state) {
        return Card(
          margin: EdgeInsets.all(MySize.size5!),
          child: Padding(
            padding: EdgeInsets.all(MySize.size8!),
            child: Column(
              spacing: MySize.size8!,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)
                        .translate('shipping_charges'),
                  ),
                  initialValue: state.shippingCharges?.toString() ?? '0.00',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  onChanged: (value) => context
                      .read<CheckoutCubit>()
                      .updateShippingCharges(value),
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)
                        .translate('shipping_details'),
                  ),
                  initialValue: state.shippingDetails,
                  onChanged: (value) => context.read<CheckoutCubit>().emitForTesting(
                    state.copyWith(shippingDetails: value),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}