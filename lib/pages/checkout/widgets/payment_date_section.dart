import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/checkout/view_model_manger/checkout_cubit.dart';

class PaymentDateSection extends StatelessWidget {
  const PaymentDateSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      buildWhen: (previous, current) =>
      previous.transactionDate != current.transactionDate,
      builder: (context, state) {
        return Card(
          shadowColor: Colors.blue,
          child: DateTimePicker(
            use24HourFormat: true,
            locale: const Locale('en', 'US'),
            initialValue: state.transactionDate,
            type: DateTimePickerType.dateTime,
            firstDate: DateTime.now().subtract(const Duration(days: 366)),
            lastDate: DateTime.now(),
            dateLabelText: "${AppLocalizations.of(context).translate('date')}:",
            style: AppTheme.getTextStyle(
              Theme.of(context).textTheme.bodyLarge,
              fontWeight: 700,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
            onChanged: (val) => context
                .read<CheckoutCubit>()
                .emitForTesting(state.copyWith(transactionDate: val)),
          ),
        );
      },
    );
  }
}