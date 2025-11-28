import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/purchases/view_model_manger/purchases_cubit/purchases_cubit.dart';
import 'package:pos_final/pages/purchases/widgets/purchases_widget.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PurchasesCubit()..getPurchases(context),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(AppLocalizations.of(context).translate('purchases')),
        ),
        body: BlocBuilder<PurchasesCubit, PurchasesState>(
          builder: (context, state) {
            if (state is PurchasesGetDataFailed) {
              return Helper().noDataWidget(context);
            } else if (state is PurchasesGetDataSuccessful) {
              List<PurchaseWidgetParameters> parameters =
              BlocProvider.of<PurchasesCubit>(context)
                  .makeParameters(context, state.purchases);
              return ListView.builder(
                itemCount: state.purchases.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: PurchaseWidget(parameters: parameters[index]),
                  );
                },
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/add_purchases');
            },
            child: const Icon(Icons.add)),
      ),
    );
  }
}
