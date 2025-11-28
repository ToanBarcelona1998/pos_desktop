import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/purchases/parameters_model/add_purchase_parameters.dart';
import 'package:pos_final/pages/purchases/view_model_manger/product_selection_cubit/product_selection_cubit.dart';
import 'package:pos_final/pages/purchases/widgets/product_widget.dart';

class ProductsSelectionScreen extends StatelessWidget {
  const ProductsSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    PurchasesParameters purchasesParameters =
        ModalRoute.of(context)!.settings.arguments as PurchasesParameters;
    return BlocProvider(
      create: (context) => ProductSelectionCubit()
        ..getProducts(purchasesParameters.locationId, false),
      child: Builder(builder: (context) {
        var cubit = BlocProvider.of<ProductSelectionCubit>(context);
        cubit.scrollController.addListener(() {
          if (cubit.scrollController.position.atEdge &&
              cubit.scrollController.position.pixels != 0) {
            if (cubit.scrollController.position.pixels ==
                cubit.scrollController.position.maxScrollExtent) {
              if (cubit.canPaginate) {
                cubit.getProducts(purchasesParameters.locationId, true);
              }
            }
          }
        });
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(AppLocalizations.of(context).translate('products')),
          ),
          body: BlocBuilder<ProductSelectionCubit, ProductSelectionState>(
            builder: (context, state) {
              if (state is ProductsGetDataFailedState) {
                return Helper().noDataWidget(context);
              } else if (state is ProductsGetDataLoadingState ||
                  state is ProductSelectionInitial) {
                return Helper().loadingIndicator(context);
              }
              ProductSelectionCubit cubit = BlocProvider.of(context);
              if (cubit.productItem.data!.isEmpty) {
                return Helper().noDataWidget(context);
              }
              return ListView.builder(
                padding: const EdgeInsets.all(5),
                controller: cubit.scrollController,
                itemCount: cubit.canPaginate
                    ? cubit.productItem.data!.length + 1
                    : cubit.productItem.data!.length,
                itemBuilder: (context, index) {
                  if (index < cubit.productItem.data!.length) {
                    var productItem = cubit.productItem.data![index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ProductItem(
                        productName: productItem.name!,
                        productPrice: productItem.productVariations![0]
                            .variations![0].defaultPurchasePrice!,
                        productImage: productItem.imageUrl ?? '',
                        productQuantity: productItem
                                .productVariations![0]
                                .variations![0]
                                .variationLocationDetails!
                                .isEmpty
                            ? '0'
                            : productItem.productVariations![0].variations![0]
                                .variationLocationDetails![0].qtyAvailable!,
                        selectedProductQuantity:
                            cubit.selectedProductQuantity(productItem),
                        onIncreasePressed: () {
                          cubit.increaseProductQuantity(productItem);
                        },
                        onDecreasePressed: () {
                          cubit.decreaseProductQuantity(productItem);
                        },
                      ),
                    );
                  } else {
                    return Helper().loadingIndicator(context);
                  }
                },
              );
            },
          ),
          bottomNavigationBar:
              BlocBuilder<ProductSelectionCubit, ProductSelectionState>(
            builder: (context, state) {
              return cubit.selectedProducts.isNotEmpty
                  ? ElevatedButton(
                      onPressed: () {
                        cubit.navigateToCheckOutScreen(
                            context, purchasesParameters);
                      },
                      child:
                          Text(AppLocalizations.of(context).translate('next')))
                  : const SizedBox.shrink();
            },
          ),
        );
      }),
    );
  }
}
