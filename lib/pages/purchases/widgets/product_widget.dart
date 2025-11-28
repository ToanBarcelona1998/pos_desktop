import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/locale/my_localizations.dart';

class ProductItem extends StatelessWidget {
  const ProductItem(
      {super.key,
      required this.productName,
      required this.productPrice,
      required this.productQuantity,
      required this.productImage,
      required this.selectedProductQuantity,
      this.onDecreasePressed,
      this.onIncreasePressed});

  final String productName;
  final String productPrice;
  final String productImage;
  final String productQuantity;
  final int selectedProductQuantity;
  final void Function()? onDecreasePressed;
  final void Function()? onIncreasePressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selectedProductQuantity != 0 ? Colors.black45 : null,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(MySize.size30!),
          child: CachedNetworkImage(
              errorWidget: (context, url, error) =>
                  Image.asset('assets/images/default_product.png'),
              placeholder: (context, url) =>
                  Image.asset('assets/images/default_product.png'),
              imageUrl: productImage),
        ),
        title: Text(productName),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              Helper().formatCurrency(productPrice),
              style: AppTheme.getTextStyle(
                  Theme.of(context).textTheme.bodyMedium,
                  fontWeight: 700,
                  letterSpacing: 0),
            ),
            Container(
              width: MySize.size80,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius:
                      BorderRadius.all(Radius.circular(MySize.size4!))),
              padding: EdgeInsets.only(
                  left: MySize.size6!,
                  right: MySize.size8!,
                  top: MySize.size2!,
                  bottom: MySize.getScaledSizeHeight(3.5)),
              child: Row(
                children: <Widget>[
                  Icon(
                    MdiIcons.stocking,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: MySize.size12,
                  ),
                  Container(
                    margin: EdgeInsets.only(left: MySize.size4!),
                    child: Text(Helper().formatQuantity(productQuantity),
                        style: AppTheme.getTextStyle(
                            Theme.of(context).textTheme.bodySmall,
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: 600)),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Container(
          width: 115,
          height: 50,
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.all(Radius.circular(MySize.size12!))),
          child: Visibility(
            visible: selectedProductQuantity != 0,
            replacement: GestureDetector(
              onTap: onIncreasePressed,
              child: Center(
                  child: Text(
                AppLocalizations.of(context).translate('add').toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18),
              )),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed: onDecreasePressed,
                      icon: const Icon(
                        Icons.remove,
                        color: Colors.white,
                      )),
                  Container(
                    width: MySize.size20,
                    height: MySize.size30,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5)),
                    child: Center(
                      child: Text(selectedProductQuantity.toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ),
                  Visibility(
                    visible: selectedProductQuantity != int.parse(productQuantity),
                    child: IconButton(
                        onPressed: onIncreasePressed,
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                        )),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
