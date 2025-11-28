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
import 'package:pos_final/pages/warranties/warranties.dart';
import 'package:pos_final/pages/warranties/widgets/warranty_form_dialog.dart';

class WarrantiesLogic {
  final WarrantiesPageState _state;
  final HomeLogic homeLogic;
  List<Map<String, dynamic>> warranties = [];
  List<Map<String, dynamic>> filteredWarranties = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  String? filterDurationType; // فلتر حسب النوع (day, month, year)
  int? filterMinDuration; // فلتر حسب الحد الأدنى للمدة

  WarrantiesLogic(this._state, this.homeLogic);

  void init() {
    fetchWarranties();
    searchController.addListener(_applyFilters);
  }

  void dispose() {
    searchController.dispose();
  }

  Future<void> fetchWarranties() async {
    if (_state.mounted) _state.setState(() => isLoading = true);
    try {
      final token = await System().getToken();
      if (token == null) {
        _showError('لا يوجد رمز وصول');
        return;
      }
      final response = await http.get(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/warranty'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        warranties = data.cast<Map<String, dynamic>>();
        await _fetchLinkedProductsCounts(); // جلب عدد المنتجات المرتبطة
        _applyFilters();
        if (_state.mounted) _state.setState(() => isLoading = false);
      } else {
        _showError('فشل تحميل الضمانات');
      }
    } catch (e) {
      _showError('خطأ: $e');
    }
  }

  Future<void> _fetchLinkedProductsCounts() async {
    final token = await System().getToken();
    for (var warranty in warranties) {
      final response = await http.get(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/product?warranty_id=${warranty['id']}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        warranty['linked_products_count'] = data.length;
      } else {
        warranty['linked_products_count'] = 0;
      }
    }
  }

  void _applyFilters() {
    final query = searchController.text.toLowerCase();
    filteredWarranties = warranties.where((warranty) {
      bool matchesQuery = (warranty['name']?.toLowerCase().contains(query) ?? false) ||
          (warranty['description']?.toLowerCase().contains(query) ?? false);
      bool matchesType = filterDurationType == null || warranty['duration_type'] == filterDurationType;
      bool matchesDuration = filterMinDuration == null || (warranty['duration'] ?? 0) >= filterMinDuration;
      return matchesQuery && matchesType && matchesDuration;
    }).toList();
    if (_state.mounted) _state.setState(() {});
  }

  void updateFilters({String? type, int? minDuration}) {
    filterDurationType = type ?? filterDurationType;
    filterMinDuration = minDuration ?? filterMinDuration;
    _applyFilters();
  }

  void showWarrantyFormDialog(BuildContext context, {bool isEdit = false, Map<String, dynamic>? warranty}) {
    showDialog(
      context: context,
      builder: (dialogContext) => WarrantyFormDialog(
        logic: this,
        isEdit: isEdit,
        warranty: warranty,
      ),
    );
  }

  void showWarrantyDetails(BuildContext context, Map<String, dynamic> warranty) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المعرف: ${warranty['id']}'),
            Text('الاسم: ${warranty['name']}'),
            Text('الوصف: ${warranty['description'] ?? 'غير متوفر'}'),
            Text('المدة: ${warranty['duration']} ${warranty['duration_type']}'),
            Text('المنتجات المرتبطة: ${warranty['linked_products_count'] ?? 0}'),
          ],
        ),
      ),
    );
  }

  Future<void> exportToCSV() async {
    try {
      List<List<dynamic>> csvData = [
        ['المعرف', 'الاسم', 'الوصف', 'المدة', 'نوع المدة', 'المنتجات المرتبطة'],
      ];
      for (var warranty in warranties) {
        csvData.add([
          warranty['id'],
          warranty['name'],
          warranty['description'] ?? 'غير متوفر',
          warranty['duration'],
          warranty['duration_type'],
          warranty['linked_products_count'] ?? 0,
        ]);
      }
      String csv = const ListToCsvConverter().convert(csvData);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/warranties_export.csv';
      final file = File(path);
      await file.writeAsString(csv);
      _showSuccess('تم التصدير إلى $path');
    } catch (e) {
      _showError('فشل التصدير: $e');
    }
  }

  Future<void> addWarranty(Map<String, dynamic> data) async {
    try {
      final token = await System().getToken();
      if (token == null) {
        _showError('لا يوجد رمز وصول');
        return;
      }
      final response = await http.post(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/warranty'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        fetchWarranties();
        _showSuccess('تم إضافة الضمان بنجاح');
      } else {
        _showError('فشل إضافة الضمان: ${response.body}');
      }
    } catch (e) {
      _showError('خطأ: $e');
    }
  }

  Future<void> updateWarranty(int id, Map<String, dynamic> data) async {
    try {
      final token = await System().getToken();
      if (token == null) {
        _showError('لا يوجد رمز وصول');
        return;
      }
      final response = await http.put(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/warranty/$id'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        fetchWarranties();
        _showSuccess('تم تحديث الضمان بنجاح');
      } else {
        _showError('فشل تحديث الضمان: ${response.body}');
      }
    } catch (e) {
      _showError('خطأ: $e');
    }
  }

  Future<void> deleteWarranty(int id) async {
    try {
      final token = await System().getToken();
      if (token == null) {
        _showError('لا يوجد رمز وصول');
        return;
      }
      final response = await http.delete(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/warranty/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        fetchWarranties();
        _showSuccess('تم حذف الضمان بنجاح');
      } else {
        _showError('فشل حذف الضمان: ${response.body}');
      }
    } catch (e) {
      _showError('خطأ: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(_state.context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  void _showError(String message) {
    showDialog(
      context: _state.context,
      builder: (context) => AlertDialog(
        title: Text('خطأ'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('موافق')),
        ],
      ),
    );
    if (_state.mounted) _state.setState(() => isLoading = false);
  }
}