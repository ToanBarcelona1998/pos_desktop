import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:pos_final/locale/my_localizations.dart';

class PurchaseWidget extends StatelessWidget {
  const PurchaseWidget({
    super.key,
    required this.parameters,
  });

  final PurchaseWidgetParameters parameters;

  @override
  Widget build(BuildContext context) {
    Color color = switch (parameters.invoiceStatus) {
      'paid' => Colors.lightGreen,
      _ => Colors.orangeAccent,
    };
    return Stack(
      children: [
        Card(
            child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          title: Text(parameters.addedFrom),
          subtitle: Text(parameters.refNo),
          trailing: Text(parameters.dueBill),
          onTap: parameters.onTap,
        )),
        Positioned(
          right: parameters.isEnglish ? 5 : null,
          top: 4,
          left: parameters.isEnglish ? null : 5,
          child: Container(
            width: 80,
            height: 21.5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              AppLocalizations.of(context).translate(parameters.invoiceStatus),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ),
        )
      ],
    );
  }
}

class PurchaseWidgetParameters extends Equatable {
  final bool isEnglish;
  final String invoiceStatus, addedFrom, dueBill, refNo;
  final void Function()? onTap;

  const PurchaseWidgetParameters(
      {required this.isEnglish,
      required this.invoiceStatus,
      required this.addedFrom,
      required this.dueBill,
      required this.refNo,
      required this.onTap});

  factory PurchaseWidgetParameters.fromJson(Map<String, dynamic> json) {
    return PurchaseWidgetParameters(
        isEnglish: json['isEnglish'],
        invoiceStatus: json['invoiceStatus'],
        addedFrom: json['addedFrom'],
        dueBill: json['dueBill'],
        refNo: json['refNo'],
        onTap: json['onTap']);
  }

  @override
  List<Object?> get props => [
        isEnglish,
        addedFrom,
        dueBill,
        invoiceStatus,
        onTap,
      ];
}
