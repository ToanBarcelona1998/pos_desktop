import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pos_final/api_end_points.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/models/system.dart';
import 'package:pos_final/pages/home/home_logic.dart';
import 'package:pos_final/pages/units/units.dart';
import 'package:pos_final/pages/units/widgets/unit_form_dialog.dart';

class UnitsLogic {
  final UnitsPageState _state;
  final HomeLogic homeLogic;
  List<Map<String, dynamic>> units = [];
  List<Map<String, dynamic>> filteredUnits = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  int totalUnits = 0;
  int baseUnits = 0;
  int subUnits = 0;
  int decimalUnits = 0;
  int wholeUnits = 0;
  bool filterDecimal = false; // فلتر متقدم للوحدات العشرية
  int? filterBaseUnitId; // فلتر للوحدة الأساسية

  UnitsLogic(this._state, this.homeLogic);

  void init() {
    fetchUnits();
    searchController.addListener(_applyFilters);
  }

  void dispose() {
    searchController.dispose();
  }

  Future<void> fetchUnits() async {
    if (_state.mounted) _state.setState(() => isLoading = true);
    try {
      final token = await System().getToken();
      if (token == null) {
        _showError('No token available');
        return;
      }
      final response = await http.get(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/unit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        units = data.cast<Map<String, dynamic>>();
        _applyFilters();
        _calculateStatistics();
        if (_state.mounted) _state.setState(() => isLoading = false);
      } else {
        _showError('Failed to load units');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _calculateStatistics() {
    totalUnits = units.length;
    baseUnits = units.where((u) => u['base_unit_id'] == null).length;
    subUnits = totalUnits - baseUnits;
    decimalUnits = units.where((u) => u['allow_decimal'] == 1).length;
    wholeUnits = totalUnits - decimalUnits;
  }

  void _applyFilters() {
    final query = searchController.text.toLowerCase();
    filteredUnits = units.where((unit) {
      bool matchesQuery = (unit['actual_name']?.toLowerCase().contains(query) ?? false) ||
          (unit['short_name']?.toLowerCase().contains(query) ?? false);
      bool matchesDecimal = !filterDecimal || unit['allow_decimal'] == 1;
      bool matchesBase = filterBaseUnitId == null || unit['base_unit_id'] == filterBaseUnitId;
      return matchesQuery && matchesDecimal && matchesBase;
    }).toList();
    if (_state.mounted) _state.setState(() {});
  }

  void updateFilters({bool? decimal, int? baseId}) {
    filterDecimal = decimal ?? filterDecimal;
    filterBaseUnitId = baseId ?? filterBaseUnitId;
    _applyFilters();
  }

  void showUnitFormDialog(BuildContext context, {bool isEdit = false, Map<String, dynamic>? unit}) {
    showDialog(
      context: context,
      builder: (dialogContext) => UnitFormDialog(
        logic: this,
        isEdit: isEdit,
        unit: unit,
      ),
    );
  }

  void showUnitDetails(BuildContext context, Map<String, dynamic> unit) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${unit['id']}'),
            Text('Name: ${unit['actual_name']}'),
            Text('Short Name: ${unit['short_name']}'),
            Text('Decimal: ${unit['allow_decimal'] == 1 ? 'Yes' : 'No'}'),
            Text('Base Unit: ${unit['base_unit']?['actual_name'] ?? 'N/A'}'),
            Text('Multiplier: ${unit['base_unit_multiplier'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  Future<void> exportToCSV() async {
    try {
      List<List<dynamic>> csvData = [
        ['ID', 'Actual Name', 'Short Name', 'Allow Decimal', 'Base Unit ID', 'Multiplier'],
      ];
      for (var unit in units) {
        csvData.add([
          unit['id'],
          unit['actual_name'],
          unit['short_name'],
          unit['allow_decimal'],
          unit['base_unit_id'],
          unit['base_unit_multiplier'],
        ]);
      }
      String csv = const ListToCsvConverter().convert(csvData);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/units_export.csv';
      final file = File(path);
      await file.writeAsString(csv);
      _showSuccess('Exported to $path');
    } catch (e) {
      _showError('Export failed: $e');
    }
  }

  Future<void> addUnit(Map<String, dynamic> data) async {
    try {
      final token = await System().getToken();
      if (token == null) {
        _showError('No token available');
        return;
      }
      final response = await http.post(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/unit'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        fetchUnits();
        _showSuccess('Unit added successfully');
      } else {
        _showError('Failed to add unit: ${response.body}');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> updateUnit(int id, Map<String, dynamic> data) async {
    try {
      final token = await System().getToken();
      if (token == null) {
        _showError('No token available');
        return;
      }
      final response = await http.put(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/unit/$id'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        fetchUnits();
        _showSuccess('Unit updated successfully');
      } else {
        _showError('Failed to update unit: ${response.body}');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> deleteUnit(int id) async {
    try {
      final token = await System().getToken();
      if (token == null) {
        _showError('No token available');
        return;
      }
      final response = await http.delete(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/unit/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        fetchUnits();
        _showSuccess('Unit deleted successfully');
      } else {
        _showError('Failed to delete unit: ${response.body}');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(_state.context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  void _showError(String message) {
    showDialog(
      context: _state.context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
        ],
      ),
    );
    if (_state.mounted) _state.setState(() => isLoading = false);
  }
}