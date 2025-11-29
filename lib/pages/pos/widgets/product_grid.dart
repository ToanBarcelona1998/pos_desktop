import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/debouncer.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/models/product_model.dart';
import 'package:pos_final/models/system.dart';
import 'package:pos_final/models/variations.dart';
import 'custom_snackbar.dart';

class ProductGrid extends StatefulWidget {
  final int? branchId;
  final Function(dynamic) onProductAdded;
  final bool isBranchSelected;
  final List<dynamic> cartItems;

  const ProductGrid({
    super.key,
    this.branchId,
    required this.onProductAdded,
    required this.isBranchSelected,
    required this.cartItems,
  });

  @override
  ProductGridState createState() => ProductGridState();
}

class ProductGridState extends State<ProductGrid> {
  List products = [];
  String symbol = '';
  int offset = 0;
  int? sellingPriceGroupId;
  List<DropdownMenuItem<bool>> _priceGroupMenuItems = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);
  final Debouncer _debouncer = Debouncer(delay: const Duration(seconds: 1));
  bool usePriceGroup = true, changePriceGroup = false;
  List<dynamic> locationListMap = [];
  bool isLoading = false;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    if (widget.isBranchSelected && widget.branchId != null) {
      initializeData();
    }
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !isLoading) {
        loadMoreProducts();
      }
    });
  }

  Future<void> priceGroupList() async {
    if (!mounted) return;
    setState(() {
      _priceGroupMenuItems = [
        DropdownMenuItem(
          value: false,
          child: Text(AppLocalizations.of(context)?.translate('no_price_group_selected') ?? 'No Price Group Selected'),
        ),
      ];
      for (dynamic element in locationListMap) {
        if (element['id'] == widget.branchId && element['selling_price_group_id'] != null) {
          _priceGroupMenuItems.add(
            DropdownMenuItem(
              value: true,
              child: Text(AppLocalizations.of(context)?.translate('default_price_group') ?? 'Default Price Group'),
            ),
          );
        }
      }
    });
  }

  @override
  void didUpdateWidget(ProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.branchId != oldWidget.branchId && widget.isBranchSelected) {
      setState(() {
        products.clear();
        offset = 0;
        sellingPriceGroupId = null;
        isLoading = true;
      });
      initializeData();
    }
  }

  Future<void> initializeData() async {
    final value = await Helper().getFormattedBusinessDetails();
    if (mounted) {
      setState(() {
        symbol = value['symbol'] != null ? value['symbol'] + ' ' : '';
      });
    }
    await fetchSellingPriceGroupId();
    await fetchProducts();
  }

  Future<void> fetchSellingPriceGroupId() async {
    final value = await System().get('location');
    locationListMap = value ?? [];
    await priceGroupList();
    if (mounted && value != null) {
      for (var element in value) {
        if (element['id'] == widget.branchId && element['selling_price_group_id'] != null) {
          setState(() {
            sellingPriceGroupId = int.tryParse(element['selling_price_group_id'].toString()) ?? 0;
          });
          break;
        }
      }
    }
  }

  Future<void> fetchProducts({String searchTerm = '', bool forceRefresh = false}) async {
    if (!widget.isBranchSelected || widget.branchId == null) return;
    setState(() {
      isLoading = true;
    });

    String? lastSync = await System().getProductLastSync();
    final date2 = DateTime.now();
    if (forceRefresh || lastSync == null || (lastSync.isNotEmpty && date2.difference(DateTime.parse(lastSync)).inMinutes > 10)) {
      if (await Helper().checkConnectivity()) {
        await Variations().refresh();
        await System().insertProductLastSyncDateTimeNow();
      }
    }

    try {
      final element = await Variations().get(
        locationId: widget.branchId,
        searchTerm: searchTerm,
        offset: offset,
        inStock: true,
      );
      if (mounted && element != null) {
        final newProducts = <dynamic>[];
        final existingProductIds = products.map((p) => p['product_id']).toSet();
        for (var product in element) {
          double? price;
          if (product['selling_price_group'] != null && sellingPriceGroupId != null) {
            try {
              final priceGroup = jsonDecode(product['selling_price_group'] ?? '[]') as List;
              for (var group in priceGroup) {
                if (group['key'] == sellingPriceGroupId) {
                  price = double.tryParse(group['value']?.toString() ?? '0.0') ?? 0.0;
                  break;
                }
              }
            } catch (e) {
              price = double.tryParse(product['default_sell_price']?.toString() ?? '0.0') ?? 0.0;
            }
          } else {
            price = double.tryParse(product['default_sell_price']?.toString() ?? '0.0') ?? 0.0;
          }
          final productModel = ProductModel().product(product, price);
          if (productModel != null && !existingProductIds.contains(productModel['product_id'])) {
            newProducts.add(productModel);
            existingProductIds.add(productModel['product_id']);
          }
        }
        if (mounted) {
          setState(() {
            products.addAll(newProducts);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.translate('failed_to_load_products') ?? 'Failed to load products')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  Future<void> loadMoreProducts() async {
    if (!widget.isBranchSelected || widget.branchId == null) return;
    setState(() {
      offset++;
    });
    await fetchProducts(searchTerm: _searchController.text);
  }

  Future<void> searchProducts(String query) async {
    if (!widget.isBranchSelected || widget.branchId == null) return;
    setState(() {
      products.clear();
      offset = 0;
    });
    await fetchProducts(searchTerm: query);
  }

  Future<void> refreshProducts() async {
    if (!widget.isBranchSelected || widget.branchId == null) return;
    setState(() {
      isRefreshing = true;
      products.clear();
      offset = 0;
    });
    await fetchProducts(forceRefresh: true, searchTerm: _searchController.text);
  }

  Future<void> scanBarcode() async {
    if (!widget.isBranchSelected || widget.branchId == null) return;
    try {
      final barcode = await Helper().barcodeScan();
      final value = await Variations().get(
        locationId: widget.branchId,
        barcode: barcode,
        offset: 0,
        searchTerm: '',
      );
      if (mounted) {
        if (value.isNotEmpty) {
          double? price;
          final productData = value[0];
          if (productData['selling_price_group'] != null && sellingPriceGroupId != null) {
            try {
              final priceGroup = jsonDecode(productData['selling_price_group'] ?? '[]') as List;
              for (var group in priceGroup) {
                if (group['key'] == sellingPriceGroupId) {
                  price = double.tryParse(group['value']?.toString() ?? '0.0') ?? 0.0;
                  break;
                }
              }
            } catch (e) {
              price = double.tryParse(productData['default_sell_price']?.toString() ?? '0.0') ?? 0.0;
            }
          } else {
            price = double.tryParse(productData['default_sell_price']?.toString() ?? '0.0') ?? 0.0;
          }
          final product = ProductModel().product(productData, price);
          if (product != null && product['stock_available'] > 0) {
            if (Platform.isIOS || Platform.isAndroid) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)?.translate('added_to_cart') ?? 'Added to cart')),
              );
            } else {
              CustomSnackbarManager.show(
                context,
                AppLocalizations.of(context)?.translate('added_to_cart') ?? 'Added to cart',
              );
            }
            widget.onProductAdded(product);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)?.translate('out_of_stock') ?? 'Out of stock')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)?.translate('no_products_found') ?? 'No product found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.translate('failed_to_scan_barcode') ?? 'Failed to scan barcode')),
        );
      }
    }
  }

  @override
  void dispose() {
    _debouncer.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular((MySize.size12 ?? 12.0).toDouble()),
      ),
      child: Column(
        children: [
          // if (widget.branchId != null && sellingPriceGroupId != null)
          //   Padding(
          //     padding: EdgeInsets.only(left: 16, bottom: 16, right: 16),
          //     child: DropdownButtonHideUnderline(
          //       child: DropdownButton(
          //         isExpanded: true,
          //         dropdownColor: themeData.cardColor,
          //         icon: Icon(
          //           Icons.arrow_drop_down,
          //           color: themeData.colorScheme.onSurface,
          //         ),
          //         value: usePriceGroup,
          //         items: _priceGroupMenuItems,
          //         onChanged: (bool? newValue) async {
          //           if (newValue == usePriceGroup) return;
          //           await _showCartResetDialogForPriceGroup();
          //           if (mounted) {
          //             setState(() {
          //               usePriceGroup = newValue!;
          //               if (changePriceGroup) {
          //                 widget.cartItems.clear();
          //                 products.clear();
          //                 _searchController.clear();
          //                 offset = 0;
          //                 fetchProducts();
          //               }
          //             });
          //           }
          //         },
          //       ),
          //     ),
          //   ),
          // Padding(
          //   padding: EdgeInsets.all((MySize.size8 ?? 8.0).toDouble()),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: TextField(
          //           controller: _searchController,
          //           enabled: widget.isBranchSelected,
          //           decoration: InputDecoration(
          //             hintText: AppLocalizations.of(context)?.translate('search_products') ?? 'Tìm kiếm',
          //             hintStyle: TextStyle(
          //               fontFamily: 'Cairo',
          //               fontSize: (MySize.size14 ?? 14.0).toDouble(),
          //               color: themeData.colorScheme.onSurface.withAlpha(150),
          //             ),
          //             prefixIcon: Icon(
          //               Icons.search,
          //               color: themeData.colorScheme.primary,
          //             ),
          //             border: OutlineInputBorder(
          //               borderRadius: BorderRadius.circular((MySize.size8 ?? 8.0).toDouble()),
          //               borderSide: BorderSide.none,
          //             ),
          //             filled: true,
          //             fillColor: customAppTheme.bgLayer2,
          //           ),
          //           style: TextStyle(
          //             fontFamily: 'Cairo',
          //             fontSize: (MySize.size14 ?? 14.0).toDouble(),
          //             color: themeData.colorScheme.onSurface,
          //           ),
          //           onSubmitted: (value) => searchProducts(value),
          //           onChanged: (value) {
          //             _debouncer(() {
          //               if (mounted) {
          //                 searchProducts(value);
          //               }
          //             });
          //           },
          //         ),
          //       ),
          //       SizedBox(width: (MySize.size8 ?? 8.0).toDouble()),
          //       IconButton(
          //         icon: Icon(
          //           Icons.refresh,
          //           color: themeData.colorScheme.primary,
          //           size: (MySize.size24 ?? 24.0).toDouble(),
          //         ),
          //         onPressed: widget.isBranchSelected ? refreshProducts : null,
          //         tooltip: AppLocalizations.of(context)?.translate('refresh_products') ?? 'Refresh products',
          //       ),
          //     ],
          //   ),
          // ),
          Expanded(
            child: widget.isBranchSelected
                ? Stack(
              children: [
                if (isLoading || isRefreshing)
                  const Center(child: CircularProgressIndicator()),
                if (products.isEmpty && !isLoading)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          size: (MySize.size48 ?? 48.0).toDouble(),
                          color: themeData.colorScheme.onSurface.withAlpha(150),
                        ),
                        Text(
                          AppLocalizations.of(context)?.translate('no_products_found') ?? 'No products found',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: (MySize.size16 ?? 16.0).toDouble(),
                            color: themeData.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (products.isNotEmpty)
                  GridView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all((MySize.size8 ?? 8.0).toDouble()),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: (MySize.size8 ?? 8.0).toDouble(),
                      crossAxisSpacing: (MySize.size8 ?? 8.0).toDouble(),
                      childAspectRatio: 1,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return ProductCard(
                        product: products[index],
                        symbol: symbol,
                        themeData: themeData,
                        onTap: () {
                          if (products[index]['stock_available'] > 0) {
                            if (Platform.isIOS || Platform.isAndroid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)?.translate('added_to_cart') ?? 'Added to cart'),
                                ),
                              );
                            } else {
                              CustomSnackbarManager.show(
                                context,
                                AppLocalizations.of(context)?.translate('added_to_cart') ?? 'Added to cart',
                              );
                            }
                            widget.onProductAdded(products[index]);
                          } else {
                            if (Platform.isIOS || Platform.isAndroid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)?.translate('out_of_stock') ?? 'Out of stock'),
                                ),
                              );
                            } else {
                              CustomSnackbarManager.show(
                                context,
                                AppLocalizations.of(context)?.translate('out_of_stock') ?? 'Out of stock',
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
              ],
            )
                : Center(
              child: Text(AppLocalizations.of(context)?.translate('please_select_branch') ?? 'Please select a branch'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCartResetDialogForPriceGroup() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)?.translate('change_selling_price_group') ?? 'Change selling price group?'),
          content: Text(AppLocalizations.of(context)?.translate('all_items_in_cart_will_be_remove') ?? 'All items in cart will be removed'),
          actions: [
            TextButton(
              onPressed: () {
                changePriceGroup = false;
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)?.translate('no') ?? 'No'),
            ),
            TextButton(
              onPressed: () {
                changePriceGroup = true;
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)?.translate('yes') ?? 'Yes'),
            ),
          ],
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final dynamic product;
  final String symbol;
  final ThemeData themeData;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.symbol,
    required this.themeData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular((MySize.size8 ?? 8.0).toDouble()),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular((MySize.size8 ?? 8.0).toDouble()),
              ),
              child: CachedNetworkImage(
                imageUrl: product['product_image_url']?.toString() ?? '',
                height: (MySize.size60 ?? 60).toDouble(),
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Image.asset(
                  'assets/images/default_product.png',
                  height: (MySize.size60 ?? 60).toDouble(),
                  fit: BoxFit.cover,
                ),
                errorWidget: (context, url, error) => Image.asset(
                  'assets/images/default_product.png',
                  height: (MySize.size60 ?? 60).toDouble(),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all((MySize.size8 ?? 8.0).toDouble()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['display_name']?.toString() ?? '',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: (MySize.size14 ?? 14.0).toDouble(),
                        fontWeight: FontWeight.w600,
                        color: themeData.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: (MySize.size4 ?? 4.0).toDouble()),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$symbol${Helper().formatCurrency(product['unit_price'] ?? 0.0)}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: (MySize.size12 ?? 12.0).toDouble(),
                              fontWeight: FontWeight.w700,
                              color: themeData.colorScheme.primary,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: (MySize.size6 ?? 6.0).toDouble(),
                              vertical: (MySize.size2 ?? 2.0).toDouble(),
                            ),
                            decoration: BoxDecoration(
                              color: themeData.colorScheme.primary,
                              borderRadius: BorderRadius.circular((MySize.size4 ?? 4.0).toDouble()),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  MdiIcons.stocking,
                                  size: (MySize.size12 ?? 12.0).toDouble(),
                                  color: themeData.colorScheme.onPrimary,
                                ),
                                SizedBox(width: (MySize.size4 ?? 4.0).toDouble()),
                                Text(
                                  product['enable_stock'] != 0
                                      ? Helper().formatQuantity(product['stock_available']?.toString() ?? '0')
                                      : '-',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: (MySize.size10 ?? 10.0).toDouble(),
                                    color: themeData.colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}