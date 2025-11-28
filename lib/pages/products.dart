import 'dart:convert';
import 'package:badges/badges.dart' as badges;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../helpers/app_theme.dart';
import '../helpers/size_config.dart';
import '../helpers/other_helpers.dart';
import '../locale/my_localizations.dart';
import '../models/product_model.dart';
import '../models/sell.dart';
import '../models/system.dart';
import '../models/variations.dart';

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  ProductsState createState() => ProductsState();
}

class ProductsState extends State<Products> {
  List products = [];
  List addedProducts = [];
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  bool changeLocation = false,
      changePriceGroup = false,
      canChangeLocation = true,
      canMakeSell = false,
      inStock = true,
      gridView = false,
      canAddSell = false,
      canViewProducts = false,
      usePriceGroup = true;

  int selectedLocationId = 0,
      categoryId = 0,
      subCategoryId = 0,
      brandId = 0,
      cartCount = 0,
      sellingPriceGroupId = 0,
      offset = 0;
  int? byAlphabets, byPrice;

  final List<DropdownMenuItem<int>> _categoryMenuItems = [], _brandsMenuItems = [];
  List<DropdownMenuItem<int>> _subCategoryMenuItems = [];
  List<DropdownMenuItem<bool>> _priceGroupMenuItems = [];
  Map? argument;
  List<Map<String, dynamic>> locationListMap = [
    {'id': 0, 'name': 'Set Location', 'selling_price_group_id': 0}
  ];

  String symbol = '';
  final searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getPermission();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        productList();
      }
    });
    setLocationMap();
    categoryList();
    subCategoryList(categoryId);
    brandList();
    Helper().syncCallLogs();
  }

  @override
  Future<void> didChangeDependencies() async {
    argument = ModalRoute.of(context)!.settings.arguments as Map?;
    if (argument != null) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            selectedLocationId = argument!['locationId'];
            canChangeLocation = false;
          });
        }
      });
    } else {
      canChangeLocation = true;
    }
    await setInitDetails(selectedLocationId);
    super.didChangeDependencies();
  }

  setInitDetails(selectedLocationId) async {
    dynamic activeSubscriptionDetails = await System().get('active-subscription');
    if (activeSubscriptionDetails.length > 0) {
      setState(() {
        canMakeSell = true;
      });
    } else {
      Fluttertoast.showToast(msg: AppLocalizations.of(context).translate('no_subscription_found'));
    }
    await Helper().getFormattedBusinessDetails().then((value) {
      symbol = value['symbol'] + ' ';
    });
    await setDefaultLocation(selectedLocationId);
    products = [];
    offset = 0;
    productList();
  }

  getPermission() async {
    if (await Helper().getPermission("direct_sell.access")) {
      canAddSell = true;
    }
    if (await Helper().getPermission("product.view")) {
      canViewProducts = true;
    }
  }

  findSellingPriceGroupId(locId) {
    if (usePriceGroup) {
      for (dynamic element in locationListMap) {
        if (element['id'] == selectedLocationId && element['selling_price_group_id'] != null) {
          sellingPriceGroupId = int.parse(element['selling_price_group_id'].toString());
        } else if (element['id'] == selectedLocationId &&
            element['selling_price_group_id'] == null) {
          sellingPriceGroupId = 0;
        }
      }
    } else {
      sellingPriceGroupId = 0;
    }
  }

  productList() async {
    offset++;
    String? lastSync = await System().getProductLastSync();
    final date2 = DateTime.now();
    if (lastSync == null || (date2.difference(DateTime.parse(lastSync)).inMinutes > 10)) {
      if (await Helper().checkConnectivity()) {
        await Variations().refresh();
        await System().insertProductLastSyncDateTimeNow();
      }
    }

    findSellingPriceGroupId(selectedLocationId);
    await Variations()
        .get(
            brandId: brandId,
            categoryId: categoryId,
            subCategoryId: subCategoryId,
            inStock: inStock,
            locationId: selectedLocationId,
            searchTerm: searchController.text,
            offset: offset,
            byAlphabets: byAlphabets,
            byPrice: byPrice)
        .then((element) {
      element.forEach((product) {
        dynamic price;
        if (product['selling_price_group'] != null) {
          jsonDecode(product['selling_price_group']).forEach((element) {
            if (element['key'] == sellingPriceGroupId) {
              price = double.parse(element['value'].toString());
            }
          });
        }
        setState(() {
          products.add(ProductModel().product(product, price));
        });
      });
    });
  }

  categoryList() async {
    List categories = await System().getCategories();
    _categoryMenuItems.add(
      DropdownMenuItem(
        value: 0,
        child: Text(AppLocalizations.of(context).translate('select_category')),
      ),
    );
    for (dynamic category in categories) {
      _categoryMenuItems.add(
        DropdownMenuItem(
          value: category['id'],
          child: Text(category['name']),
        ),
      );
    }
  }

  subCategoryList(parentId) async {
    List subCategories = await System().getSubCategories(parentId);
    _subCategoryMenuItems = [];
    _subCategoryMenuItems.add(
      DropdownMenuItem(
        value: 0,
        child: Text(AppLocalizations.of(context).translate('select_sub_category')),
      ),
    );
    for (dynamic element in subCategories) {
      _subCategoryMenuItems.add(
        DropdownMenuItem(
          value: jsonDecode(element['value'])['id'],
          child: Text(jsonDecode(element['value'])['name']),
        ),
      );
    }
  }

  brandList() async {
    List brands = await System().getBrands();
    _brandsMenuItems.add(
      DropdownMenuItem(
        value: 0,
        child: Text(AppLocalizations.of(context).translate('select_brand')),
      ),
    );
    for (dynamic brand in brands) {
      _brandsMenuItems.add(
        DropdownMenuItem(
          value: brand['id'],
          child: Text(brand['name']),
        ),
      );
    }
  }

  priceGroupList() async {
    setState(() {
      _priceGroupMenuItems = [];
      _priceGroupMenuItems.add(
        DropdownMenuItem(
          value: false,
          child: Text(AppLocalizations.of(context).translate('no_price_group_selected')),
        ),
      );
      for (dynamic element in locationListMap) {
        if (element['id'] == selectedLocationId && element['selling_price_group_id'] != null) {
          _priceGroupMenuItems.add(
            DropdownMenuItem(
              value: true,
              child: Text(AppLocalizations.of(context).translate('default_price_group')),
            ),
          );
        }
      }
    });
  }

  Future<String> getCartItemCount({isCompleted, sellId}) async {
    dynamic counts = await Sell().cartItemCount(isCompleted: isCompleted, sellId: sellId);
    setState(() {
      cartCount = int.parse(counts);
    });
    return counts;
  }

  double findAspectRatio(double width) {
    return (width / 2 - MySize.size24!) / ((width / 2 - MySize.size24!) + 80);
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        backgroundColor: themeData.scaffoldBackgroundColor,
        endDrawer: _filterDrawer(),
        appBar: AppBar(
          elevation: 2,
          title: Text(
            AppLocalizations.of(context).translate('products'),
            style: AppTheme.getTextStyle(
              themeData.textTheme.headlineSmall,
              fontWeight: 700,
              color: themeData.colorScheme.onPrimary,
            ),
          ),
          backgroundColor: themeData.colorScheme.primary,
          actions: <Widget>[
            locations(),
            badges.Badge(
              badgeStyle: badges.BadgeStyle(
                badgeColor: Colors.redAccent,
                padding: EdgeInsets.all(8),
              ),
              position: badges.BadgePosition.topEnd(top: 0, end: 3),
              badgeContent: FutureBuilder(
                future: (argument != null && argument!['sellId'] != null)
                    ? getCartItemCount(sellId: argument!['sellId'])
                    : getCartItemCount(isCompleted: 0),
                builder: (context, AsyncSnapshot<String> snapshot) {
                  return Text(
                    snapshot.hasData ? '${snapshot.data}' : '0',
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.labelSmall,
                      color: Colors.white,
                      fontWeight: 600,
                    ),
                  );
                },
              ),
              child: IconButton(
                icon: Icon(
                  MdiIcons.cart,
                  size: 28,
                  color: themeData.colorScheme.onPrimary,
                ),
                onPressed: () {
                  if (argument != null) {
                    Navigator.pushReplacementNamed(context, '/cart',
                        arguments: Helper()
                            .argument(locId: argument!['locationId'], sellId: argument!['sellId']));
                  } else {
                    if (selectedLocationId != 0 && cartCount > 0) {
                      Navigator.pushNamed(context, '/cart',
                          arguments: Helper().argument(locId: selectedLocationId));
                    }
                    if (cartCount == 0) {
                      Fluttertoast.showToast(
                          msg: AppLocalizations.of(context).translate('no_items_added_to_cart'));
                    }
                  }
                },
              ),
            ),
            SizedBox(width: 16),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return canViewProducts
                ? SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        if (selectedLocationId != 0) filter(_scaffoldKey),
                        if (selectedLocationId != 0)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton(
                                isExpanded: true,
                                dropdownColor: themeData.cardColor,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: themeData.colorScheme.onSurface,
                                ),
                                value: usePriceGroup,
                                items: _priceGroupMenuItems,
                                onChanged: (bool? newValue) async {
                                  await _showCartResetDialogForPriceGroup();
                                  setState(() {
                                    usePriceGroup = newValue!;
                                    if (changePriceGroup) {
                                      Sell().resetCart();
                                      brandId = 0;
                                      categoryId = 0;
                                      searchController.clear();
                                      inStock = true;
                                      cartCount = 0;
                                      products = [];
                                      offset = 0;
                                      productList();
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        selectedLocationId == 0
                            ? SizedBox(
                                height: constraints.maxHeight,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 48,
                                        color: themeData.colorScheme.primary,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        AppLocalizations.of(context)
                                            .translate('please_set_a_location'),
                                        style: AppTheme.getTextStyle(
                                          themeData.textTheme.titleLarge,
                                          fontWeight: 600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : _productsList(constraints),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      AppLocalizations.of(context).translate('unauthorised'),
                      style: AppTheme.getTextStyle(
                        themeData.textTheme.titleLarge,
                        fontWeight: 600,
                        color: themeData.colorScheme.error,
                      ),
                    ),
                  );
          },
        ),
      ),
    );
  }

  Widget _filterDrawer() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      color: themeData.cardColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              AppLocalizations.of(context).translate('sort'),
              style: AppTheme.getTextStyle(
                themeData.textTheme.headlineSmall,
                fontWeight: 700,
                color: themeData.colorScheme.primary,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _SortButton(
                  isActive: byAlphabets != null,
                  onTap: () {
                    setState(() {
                      byAlphabets = byAlphabets == null
                          ? 0
                          : byAlphabets == 0
                              ? 1
                              : null;
                    });
                    products = [];
                    offset = 0;
                    productList();
                  },
                  child: Row(
                    children: [
                      Text(
                        "A",
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.titleMedium,
                          fontWeight: 700,
                          color: byAlphabets != null
                              ? themeData.colorScheme.primary
                              : themeData.colorScheme.onSurface.withAlpha((0.6 * 256).toInt()),
                        ),
                      ),
                      Icon(
                        byAlphabets == 1 ? MdiIcons.arrowLeftBold : MdiIcons.arrowRightBold,
                        color: byAlphabets != null
                            ? themeData.colorScheme.primary
                            : themeData.colorScheme.onSurface.withAlpha((0.6 * 256).toInt()),
                        size: 20,
                      ),
                      Text(
                        "Z",
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.titleMedium,
                          fontWeight: 700,
                          color: byAlphabets != null
                              ? themeData.colorScheme.primary
                              : themeData.colorScheme.onSurface.withAlpha((0.6 * 256).toInt()),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                _SortButton(
                  isActive: byPrice != null,
                  onTap: () {
                    setState(() {
                      byPrice = byPrice == null
                          ? 0
                          : byPrice == 0
                              ? 1
                              : null;
                    });
                    products = [];
                    offset = 0;
                    productList();
                  },
                  child: Row(
                    children: [
                      Text(
                        AppLocalizations.of(context).translate('price'),
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.titleMedium,
                          fontWeight: 700,
                          color: byPrice != null
                              ? themeData.colorScheme.primary
                              : themeData.colorScheme.onSurface.withAlpha((0.6 * 256).toInt()),
                        ),
                      ),
                      Icon(
                        byPrice == 1 ? MdiIcons.arrowDownBold : MdiIcons.arrowUpBold,
                        color: byPrice != null
                            ? themeData.colorScheme.primary
                            : themeData.colorScheme.onSurface.withAlpha((0.6 * 256).toInt()),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 32),
            Text(
              AppLocalizations.of(context).translate('filter'),
              style: AppTheme.getTextStyle(
                themeData.textTheme.headlineSmall,
                fontWeight: 700,
                color: themeData.colorScheme.primary,
              ),
            ),
            SizedBox(height: 16),
            CheckboxListTile(
              title: Text(
                AppLocalizations.of(context).translate('in_stock'),
                style: AppTheme.getTextStyle(
                  themeData.textTheme.titleMedium,
                  fontWeight: 600,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              value: inStock,
              onChanged: (newValue) {
                setState(() {
                  inStock = newValue!;
                });
                products = [];
                offset = 0;
                productList();
              },
            ),
            Divider(),
            _FilterSection(
              title: AppLocalizations.of(context).translate('categories'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
                  isExpanded: true,
                  dropdownColor: themeData.cardColor,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: themeData.colorScheme.onSurface,
                  ),
                  value: categoryId,
                  items: _categoryMenuItems,
                  onChanged: (int? newValue) {
                    setState(() {
                      subCategoryId = 0;
                      categoryId = newValue!;
                      subCategoryList(categoryId);
                    });
                    products = [];
                    offset = 0;
                    productList();
                  },
                ),
              ),
            ),
            Divider(),
            _FilterSection(
              title: AppLocalizations.of(context).translate('sub_categories'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
                  isExpanded: true,
                  dropdownColor: themeData.cardColor,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: themeData.colorScheme.onSurface,
                  ),
                  value: subCategoryId,
                  items: _subCategoryMenuItems,
                  onChanged: (int? newValue) {
                    setState(() {
                      subCategoryId = newValue!;
                    });
                    products = [];
                    offset = 0;
                    productList();
                  },
                ),
              ),
            ),
            Divider(),
            _FilterSection(
              title: AppLocalizations.of(context).translate('brands'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
                  isExpanded: true,
                  dropdownColor: themeData.cardColor,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: themeData.colorScheme.onSurface,
                  ),
                  value: brandId,
                  items: _brandsMenuItems,
                  onChanged: (int? newValue) {
                    setState(() {
                      brandId = newValue!;
                    });
                    products = [];
                    offset = 0;
                    productList();
                  },
                ),
              ),
            ),
            Divider(),
            Text(
              AppLocalizations.of(context).translate('group_prices'),
              style: AppTheme.getTextStyle(
                themeData.textTheme.headlineSmall,
                fontWeight: 700,
                color: themeData.colorScheme.primary,
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonHideUnderline(
              child: DropdownButton(
                isExpanded: true,
                dropdownColor: themeData.cardColor,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: themeData.colorScheme.onSurface,
                ),
                value: usePriceGroup,
                items: _priceGroupMenuItems,
                onChanged: (bool? newValue) async {
                  await _showCartResetDialogForPriceGroup();
                  setState(() {
                    usePriceGroup = newValue!;
                    if (changePriceGroup) {
                      Sell().resetCart();
                      brandId = 0;
                      categoryId = 0;
                      searchController.clear();
                      inStock = true;
                      cartCount = 0;
                      products = [];
                      offset = 0;
                      productList();
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget filter(scaffoldKey) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Form(
              key: _formKey,
              child: TextFormField(
                style: AppTheme.getTextStyle(
                  themeData.textTheme.titleMedium,
                  fontWeight: 500,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).translate('search'),
                  hintStyle: AppTheme.getTextStyle(
                    themeData.textTheme.titleMedium,
                    fontWeight: 500,
                    color: themeData.colorScheme.onSurface.withAlpha((0.6 * 256).toInt()),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: themeData.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: themeData.colorScheme.surface.withAlpha((0.1 * 256).toInt()),
                  prefixIcon: Icon(
                    MdiIcons.magnify,
                    size: 24,
                    color: themeData.colorScheme.onSurface.withAlpha((0.6 * 256).toInt()),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                controller: searchController,
                onEditingComplete: () {
                  products = [];
                  offset = 0;
                  productList();
                },
              ),
            ),
          ),
          SizedBox(width: 12),
          _ActionButton(
            icon: MdiIcons.barcode,
            onTap: () async {
              dynamic barcode = await Helper().barcodeScan();
              await getScannedProduct(barcode);
            },
          ),
          SizedBox(width: 12),
          _ActionButton(
            icon: MdiIcons.tune,
            onTap: () {
              scaffoldKey.currentState?.openEndDrawer();
            },
          ),
          SizedBox(width: 12),
          _ActionButton(
            icon: gridView ? MdiIcons.viewList : MdiIcons.viewGrid,
            onTap: () {
              setState(() {
                gridView = !gridView;
              });
            },
          ),
        ],
      ),
    );
  }

  getScannedProduct(String barcode) async {
    if (canMakeSell) {
      await Variations()
          .get(
              locationId: selectedLocationId,
              barcode: barcode,
              offset: 0,
              searchTerm: searchController.text)
          .then((value) async {
        if (canAddSell) {
          if (value.length > 0) {
            dynamic price;
            dynamic product;
            if (value[0]['selling_price_group'] != null) {
              jsonDecode(value[0]['selling_price_group']).forEach((element) {
                if (element['key'] == sellingPriceGroupId) {
                  price = element['value'];
                }
              });
            }
            setState(() {
              product = ProductModel().product(value[0], price);
            });
            if (product != null && product['stock_available'] > 0) {
              Fluttertoast.showToast(msg: AppLocalizations.of(context).translate('added_to_cart'));
              await Sell().addToCart(product, argument != null ? argument!['sellId'] : null);
              if (argument != null) {
                selectedLocationId = argument!['locationId'];
              }
            } else {
              Fluttertoast.showToast(msg: AppLocalizations.of(context).translate("out_of_stock"));
            }
          } else {
            Fluttertoast.showToast(msg: AppLocalizations.of(context).translate("no_product_found"));
          }
        } else {
          Fluttertoast.showToast(
              msg: AppLocalizations.of(context).translate("no_sells_permission"));
        }
      });
    } else {
      Fluttertoast.showToast(msg: AppLocalizations.of(context).translate('no_subscription_found'));
    }
  }

  Widget _productsList(BoxConstraints constraints) {
    return products.isEmpty
        ? SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 48,
                    color: themeData.colorScheme.primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).translate('no_products_found'),
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.titleLarge,
                      fontWeight: 600,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Padding(
            padding: EdgeInsets.all(16),
            child: gridView
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.maxWidth > 1200 ? 4 : 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: findAspectRatio(constraints.maxWidth),
                    ),
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () => onTapProduct(index),
                        child: _ProductGridWidget(
                          name: products[index]['display_name'],
                          image: products[index]['product_image_url'],
                          qtyAvailable: products[index]['enable_stock'] != 0
                              ? products[index]['stock_available'].toString()
                              : '-',
                          price: double.parse(products[index]['unit_price'].toString()),
                          symbol: symbol,
                        ),
                      );
                    },
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () => onTapProduct(index),
                        child: _ProductListWidget(
                          name: products[index]['display_name'],
                          image: products[index]['product_image_url'],
                          qtyAvailable: products[index]['enable_stock'] != 0
                              ? products[index]['stock_available'].toString()
                              : '-',
                          price: double.parse(products[index]['unit_price'].toString()),
                          symbol: symbol,
                          isAdded: addedProducts.contains(products[index]),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => SizedBox(height: 12),
                  ),
          );
  }

  onTapProduct(int index) async {
    if (canAddSell) {
      if (canMakeSell) {
        if (products[index]['stock_available'] > 0) {
          Fluttertoast.showToast(msg: AppLocalizations.of(context).translate('added_to_cart'));
          addedProducts.add(products[index]);
          await Sell().addToCart(products[index], argument != null ? argument!['sellId'] : null);
          if (argument != null) {
            selectedLocationId = argument!['locationId'];
          }
        } else {
          Fluttertoast.showToast(msg: AppLocalizations.of(context).translate("out_of_stock"));
        }
      } else {
        Fluttertoast.showToast(msg: AppLocalizations.of(context).translate("no_sells_permission"));
      }
    } else {
      Fluttertoast.showToast(msg: AppLocalizations.of(context).translate('no_subscription_found'));
    }
  }

  setLocationMap() async {
    await System().get('location').then((value) async {
      value.forEach((element) {
        if (element['is_active'].toString() == '1') {
          setState(() {
            locationListMap.add({
              'id': element['id'],
              'name': element['name'],
              'selling_price_group_id': element['selling_price_group_id']
            });
          });
        }
      });
      await priceGroupList();
    });
  }

  setDefaultLocation(defaultLocation) {
    if (defaultLocation != 0) {
      setState(() {
        selectedLocationId = defaultLocation;
      });
    } else if (locationListMap.length == 2) {
      setState(() {
        selectedLocationId = locationListMap[1]['id'] as int;
      });
    }
  }

  Widget locations() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          dropdownColor: themeData.cardColor,
          icon: Icon(
            Icons.arrow_drop_down,
            color: themeData.colorScheme.onPrimary,
          ),
          value: selectedLocationId,
          items: locationListMap.map<DropdownMenuItem<int>>((Map value) {
            return DropdownMenuItem<int>(
              value: value['id'],
              child: SizedBox(
                width: 200,
                child: Text(
                  '${value['name']}',
                  style: AppTheme.getTextStyle(
                    themeData.textTheme.titleMedium,
                    fontWeight: 600,
                    color: themeData.colorScheme.onPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
          onTap: () {
            if (locationListMap.length <= 2) {
              canChangeLocation = false;
            }
          },
          onChanged: (int? newValue) async {
            if (canChangeLocation) {
              if (selectedLocationId == newValue) {
                changeLocation = false;
              } else if (selectedLocationId != 0) {
                await _showCartResetDialogForLocation();
                await priceGroupList();
              } else {
                changeLocation = true;
                await priceGroupList();
              }
              setState(() {
                if (changeLocation) {
                  Sell().resetCart();
                  selectedLocationId = newValue!;
                  brandId = 0;
                  categoryId = 0;
                  searchController.clear();
                  inStock = true;
                  cartCount = 0;
                  products = [];
                  offset = 0;
                  productList();
                }
              });
            } else {
              Fluttertoast.showToast(
                  msg: AppLocalizations.of(context).translate('cannot_change_location'));
            }
          },
        ),
      ),
    );
  }

  Future<void> _showCartResetDialogForLocation() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).translate('change_location')),
          content: Text(AppLocalizations.of(context).translate('all_items_in_cart_will_be_remove')),
          actions: [
            TextButton(
              onPressed: () {
                changeLocation = false;
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context).translate('no')),
            ),
            TextButton(
              onPressed: () {
                changeLocation = true;
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context).translate('yes')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCartResetDialogForPriceGroup() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).translate('change_selling_price_group')),
          content: Text(AppLocalizations.of(context).translate('all_items_in_cart_will_be_remove')),
          actions: [
            TextButton(
              onPressed: () {
                changePriceGroup = false;
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context).translate('no')),
            ),
            TextButton(
              onPressed: () {
                changePriceGroup = true;
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context).translate('yes')),
            ),
          ],
        );
      },
    );
  }
}

class _ProductGridWidget extends StatefulWidget {
  final String? name, image, symbol;
  final String? qtyAvailable;
  final double? price;

  const _ProductGridWidget({
    this.name,
    this.image,
    this.qtyAvailable,
    this.price,
    this.symbol,
  });

  @override
  _ProductGridWidgetState createState() => _ProductGridWidgetState();
}

class _ProductGridWidgetState extends State<_ProductGridWidget> {
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);
   // String key = Generator.randomString(10);
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: themeData.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: themeData.shadowColor.withAlpha((isHovered ? 0.3 : 0.1 * 256).toInt()),
              blurRadius: isHovered ? 12 : 8,
              spreadRadius: isHovered ? 2 : 1,
              offset: Offset(0, isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                imageUrl: widget.image ?? '',
                placeholder: (context, url) => Container(
                  color: themeData.colorScheme.surface.withAlpha((0.1 * 256).toInt()),
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Image.asset(
                  'assets/images/default_product.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.getTextStyle(
                      themeData.textTheme.titleMedium,
                      fontWeight: 600,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${Helper().formatCurrency(widget.price)}${widget.symbol}',
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyLarge,
                          fontWeight: 700,
                          color: themeData.colorScheme.primary,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeData.colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              MdiIcons.stocking,
                              color: themeData.colorScheme.onPrimary,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              widget.qtyAvailable != '-'
                                  ? Helper().formatQuantity(widget.qtyAvailable)
                                  : '-',
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodySmall,
                                color: themeData.colorScheme.onPrimary,
                                fontWeight: 600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductListWidget extends StatefulWidget {
  final String? name, image, symbol;
  final String? qtyAvailable;
  final double? price;
  final bool isAdded;

  const _ProductListWidget({
    this.name,
    this.image,
    this.qtyAvailable,
    this.price,
    this.symbol,
    required this.isAdded,
  });

  @override
  _ProductListWidgetState createState() => _ProductListWidgetState();
}

class _ProductListWidgetState extends State<_ProductListWidget> {
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color:
              widget.isAdded ? themeData.colorScheme.primary.withAlpha((0.1 * 256).toInt()) : themeData.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: themeData.shadowColor.withAlpha((isHovered ? 0.3 : 0.1 * 256).toInt()),
              blurRadius: isHovered ? 12 : 8,
              spreadRadius: isHovered ? 2 : 1,
              offset: Offset(0, isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                  child: CachedNetworkImage(
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    imageUrl: widget.image ?? '',
                    placeholder: (context, url) => Container(
                      color: themeData.colorScheme.surface.withAlpha((0.1 * 256).toInt()),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/images/default_product.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.titleMedium,
                            fontWeight: 600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${Helper().formatCurrency(widget.price)}${widget.symbol}',
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.bodyLarge,
                                fontWeight: 700,
                                color: themeData.colorScheme.primary,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: themeData.colorScheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    MdiIcons.stocking,
                                    color: themeData.colorScheme.onPrimary,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    widget.qtyAvailable != '-'
                                        ? Helper().formatQuantity(widget.qtyAvailable)
                                        : '-',
                                    style: AppTheme.getTextStyle(
                                      themeData.textTheme.bodySmall,
                                      color: themeData.colorScheme.onPrimary,
                                      fontWeight: 600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Icon(
                widget.isAdded ? Icons.check_circle : Icons.radio_button_unchecked,
                color: widget.isAdded ? Colors.green : Colors.grey,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  final Widget child;

  const _SortButton({
    required this.isActive,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary.withAlpha((0.1 * 256).toInt()) : theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withAlpha((0.2 * 256).toInt()),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withAlpha((0.1 * 256).toInt()),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withAlpha((0.1 * 256).toInt()),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.getTextStyle(
            theme.textTheme.titleLarge,
            fontWeight: 600,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 8),
        child,
      ],
    );
  }
}
