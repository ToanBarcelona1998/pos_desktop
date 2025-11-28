import 'package:flutter/material.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/locale/my_localizations.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = AppTheme.getThemeFromThemeMode(1);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).translate('Categories'),
          style: AppTheme.getTextStyle(themeData.textTheme.titleLarge,
              fontWeight: 600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 90,
                  decoration: BoxDecoration(
                      color: const Color(0xffedecf2),
                      borderRadius: BorderRadius.circular(5)),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/BrandsScreen');
                    },
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)
                                .translate('brands'),
                            style: const TextStyle(
                                color: Color(0xff4c53a5), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),


              ],
            ),
          ],
        ),
      ),
    );
  }
}
