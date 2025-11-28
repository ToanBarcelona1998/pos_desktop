import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/home/home_logic.dart';
import 'package:pos_final/pages/home/widgets/sidebar.dart';
import 'package:pos_final/pages/units/units_logic.dart';
import 'package:pos_final/pages/units/widgets/units_list_widget.dart';

class UnitsPage extends StatefulWidget {
  final HomeLogic homeLogic;

  const UnitsPage({super.key, required this.homeLogic});

  @override
  UnitsPageState createState() => UnitsPageState();
}

class UnitsPageState extends State<UnitsPage> with SingleTickerProviderStateMixin {
  late UnitsLogic _logic;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _logic = UnitsLogic(this, widget.homeLogic);
    _logic.init();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _logic.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        title: Row(
          children: [
            const Icon(FontAwesomeIcons.ruler, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              localizations?.translate('units') ?? 'Units',
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
            tooltip: localizations?.translate('refresh') ?? 'Refresh',
            onPressed: () => _logic.fetchUnits(),
            hoverColor: Colors.white.withOpacity(0.2),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _logic.showUnitFormDialog(context, isEdit: false),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(FontAwesomeIcons.plus, color: Colors.white),
        tooltip: localizations?.translate('add') ?? 'Add Unit',
        elevation: 6,
        hoverElevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              // Sidebar with responsive width
              SizedBox(
                width: constraints.maxWidth > 1200 ? 300 : 250,
                child: Sidebar(logic: widget.homeLogic),
              ),
              // Main content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    margin: const EdgeInsets.all(16),
                    child: UnitsListWidget(logic: _logic),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}