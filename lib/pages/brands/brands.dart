import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/home/home_logic.dart';
import 'package:pos_final/pages/home/widgets/sidebar.dart';
import 'package:pos_final/pages/brands/brands_logic.dart';
import 'package:pos_final/pages/brands/widgets/brands_list_widget.dart';

class BrandsPage extends StatefulWidget {
  final HomeLogic homeLogic;

  const BrandsPage({super.key, required this.homeLogic});

  @override
  BrandsPageState createState() => BrandsPageState();
}

class BrandsPageState extends State<BrandsPage> {
  late BrandsLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = BrandsLogic(this, widget.homeLogic);
    _logic.init();
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
        title: Row(
          children: [
            const Icon(FontAwesomeIcons.tags, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              localizations?.translate('brands') ?? 'العلامات التجارية',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.sync, color: Colors.orangeAccent),
            tooltip: localizations?.translate('refresh') ?? 'تحديث',
            onPressed: () => _logic.fetchBrands(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _logic.showBrandFormDialog(context, isEdit: false),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(FontAwesomeIcons.plus, color: Colors.white),
        tooltip: localizations?.translate('add_brand') ?? 'إضافة علامة تجارية',
      ),
      body: Row(
        children: [
          if (isDesktop) Sidebar(logic: widget.homeLogic),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 32 : 16),
                  child: BrandsListWidget(logic: _logic),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}