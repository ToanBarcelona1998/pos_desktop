import 'package:flutter/material.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/models/system.dart';

class BranchSelector extends StatefulWidget {
  final Function(int?) onBranchSelected;
  final int? selectedBranchId;

  const BranchSelector({
    super.key,
    required this.onBranchSelected,
    this.selectedBranchId,
  });

  @override
  BranchSelectorState createState() => BranchSelectorState();
}

class BranchSelectorState extends State<BranchSelector> {
  List<Map<String, dynamic>> branchList = [
    {'id': 0, 'name': 'Select Branch', 'selling_price_group_id': 0}
  ];
  int? selectedBranchId;
  bool isLoading = true;
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    selectedBranchId = widget.selectedBranchId;
    fetchBranches();
  }

  Future<void> fetchBranches() async {
    setState(() {
      isLoading = true;
    });
    try {
      await System().get('location').then((value) {
        if (mounted) {
          setState(() {
            branchList.clear();
            branchList.add({'id': 0, 'name': 'Select Branch', 'selling_price_group_id': 0});
            if (value != null) {
              for (var element in value) {
                if (element['is_active']?.toString() == '1' &&
                    element['id'] != null &&
                    element['name'] != null) {
                  branchList.add({
                    'id': element['id'] as int,
                    'name': element['name'] as String,
                    'selling_price_group_id':
                    element['selling_price_group_id'] as int? ?? 0,
                  });
                }
              }
            }
            if (branchList.length == 2 && selectedBranchId == null) {
              selectedBranchId = branchList[1]['id'] as int;
              widget.onBranchSelected(selectedBranchId);
            }
            isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);

    if (isLoading) {
      return Container(
        padding: EdgeInsets.all((MySize.size8 ?? 8.0).toDouble()),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all((MySize.size8 ?? 8.0).toDouble()),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular((MySize.size12 ?? 12.0).toDouble()),
        boxShadow: [
          BoxShadow(
            color: themeData.cardTheme.shadowColor?.withAlpha(48) ?? Colors.grey.withAlpha(48),
            blurRadius: (MySize.size8 ?? 8.0).toDouble(),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            size: (MySize.size24 ?? 24.0).toDouble(),
            color: themeData.colorScheme.primary,
          ),
          SizedBox(width: (MySize.size12 ?? 12.0).toDouble()),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: selectedBranchId,
                hint: Text(
                  'Select Branch',
                  style: TextStyle(
            fontFamily: 'Cairo',
                    fontSize: (MySize.size16 ?? 16.0).toDouble(),
                    color: themeData.colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                items: branchList.map<DropdownMenuItem<int>>((Map branch) {
                  return DropdownMenuItem<int>(
                    value: branch['id'],
                    child: Text(
                      branch['name'],
                      style: TextStyle(
            fontFamily: 'Cairo',
                        fontSize: (MySize.size16 ?? 16.0).toDouble(),
                        color: themeData.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    selectedBranchId = newValue;
                    widget.onBranchSelected(newValue);
                  });
                },
                dropdownColor: Colors.white,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: themeData.colorScheme.primary,
                  size: (MySize.size24 ?? 24.0).toDouble(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}