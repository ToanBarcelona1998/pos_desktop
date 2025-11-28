import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/purchases/components/custom_drop_down_button.dart';
import 'package:pos_final/pages/purchases/components/custom_text_form_field.dart';
import 'package:pos_final/pages/purchases/view_model_manger/purchase_checkout_cubit/purchase_checkout_cubit.dart';

class CreditCardDataWidget extends StatelessWidget {
  const CreditCardDataWidget({super.key});

  @override
  Widget build(BuildContext context) {
    PurchaseCheckoutCubit cubit =
        BlocProvider.of<PurchaseCheckoutCubit>(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: CustomTextField(
            titleText: AppLocalizations.of(context).translate('card_number'),
            hintText: 'XXXX XXXX XXXX XXXX',
            inputType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              LengthLimitingTextInputFormatter(16),
              CardNumberInputFormatter()
            ],
            controller: cubit.cardNumberController,
            validator: (p0) {
              if (cubit.paymentWay != PaymentWay.card) return null;
              if (p0 == null || p0.isEmpty) {
                return AppLocalizations.of(context).translate('not_empty');
              }

              return null;
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Expanded(
                  child: CustomTextField(
                    inputType: TextInputType.number,
                titleText: AppLocalizations.of(context).translate('month'),
                hintText: '02',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  LengthLimitingTextInputFormatter(2),
                ],
                controller: cubit.cardExpiryMonthController,
                validator: (p0) {
                  if (cubit.paymentWay != PaymentWay.card) return null;
                  if (p0 == null || p0.isEmpty) {
                    return AppLocalizations.of(context).translate('not_empty');
                  }

                  return null;
                },
              )),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                  child: CustomTextField(
                inputType: TextInputType.number,
                controller: cubit.cardExpiryYearController,
                titleText: AppLocalizations.of(context).translate('year'),
                hintText: '28',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  LengthLimitingTextInputFormatter(2),
                ],
                validator: (p0) {
                  if (cubit.paymentWay != PaymentWay.card) return null;
                  if (p0 == null || p0.isEmpty) {
                    return AppLocalizations.of(context).translate('not_empty');
                  }

                  return null;
                },
              )),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                  child: CustomTextField(
                    inputType: TextInputType.number,
                titleText: AppLocalizations.of(context).translate('cvv'),
                hintText: 'XXX',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  LengthLimitingTextInputFormatter(3),
                ],
                controller: cubit.cardSecurityCodeController,
                validator: (p0) {
                  if (cubit.paymentWay != PaymentWay.card) return null;
                  if (p0 == null || p0.isEmpty) {
                    return AppLocalizations.of(context).translate('not_empty');
                  }

                  return null;
                },
              )),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: CustomTextField(
            titleText: AppLocalizations.of(context).translate('card_holder'),
            controller: cubit.cardHolderNameController,
            validator: (p0) {
              if (cubit.paymentWay != PaymentWay.card) return null;
              if (p0 == null || p0.isEmpty) {
                return AppLocalizations.of(context).translate('not_empty');
              }

              return null;
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: CustomDropDownButton<String>(
            titleText: AppLocalizations.of(context).translate('card_type'),
            items: const [
              DropdownMenuItem(
                value: 'credit',
                child: Text('Credit Card'),
              ),
              DropdownMenuItem(
                value: 'debit',
                child: Text('Debit Card'),
              ),
            ],
            onChanged: cubit.onCardTypeChange,
            validator: (p0) {
              if (cubit.paymentWay != PaymentWay.card) return null;
              if (p0 == null || p0.isEmpty) {
                return AppLocalizations.of(context).translate('not_empty');
              }

              return null;
            },
          ),
        )
      ],
    );
  }
}
