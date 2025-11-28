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
import 'package:pos_final/pages/brands/brands.dart';
import 'package:pos_final/pages/brands/widgets/brand_form_dialog.dart';

class BrandsLogic {
  final BrandsPageState _state;
  final HomeLogic homeLogic;
  List<Map<String, dynamic>> brands = [];
  List<Map<String, dynamic>> filteredBrands = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  bool? filterUseForRepair; // فلتر حسب use_for_repair

  BrandsLogic(this._state, this.homeLogic);

  void init() {
    fetchBrands();
    searchController.addListener(_applyFilters);
  }

  void dispose() {
    searchController.dispose();
  }

  Future<void> fetchBrands() async {
    if (_state.mounted) _state.setState(() => isLoading = true);
    try {
      final token = await System().getToken();
      if (token == null) {
        _showError('لا يوجد رمز وصول');
        return;
      }
      final response = await http.get(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/brand'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        brands = data.cast<Map<String, dynamic>>();
        await _fetchLinkedProductsCounts();
        _applyFilters();
        if (_state.mounted) _state.setState(() => isLoading = false);
      } else {
        _showError('فشل تحميل العلامات التجارية');
      }
    } catch (e) {
      _showError('خطأ: $e');
    }
  }

  Future<void> _fetchLinkedProductsCounts() async {
    final token = await System().getToken();
    for (var brand in brands) {
      final response = await http.get(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/product?brand_id=${brand['id']}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        brand['linked_products_count'] = data.length;
      } else {
        brand['linked_products_count'] = 0;
      }
    }
  }

  void _applyFilters() {
    final query = searchController.text.toLowerCase();
    filteredBrands = brands.where((brand) {
      bool matchesQuery = (brand['name']?.toLowerCase().contains(query) ?? false) ||
          (brand['description']?.toLowerCase().contains(query) ?? false);
      bool matchesRepair = filterUseForRepair == null || brand['use_for_repair'] == filterUseForRepair;
      return matchesQuery && matchesRepair;
    }).toList();
    if (_state.mounted) _state.setState(() {});
  }

  void updateFilters({bool? useForRepair}) {
    filterUseForRepair = useForRepair ?? filterUseForRepair;
    _applyFilters();
  }

  void showBrandFormDialog(BuildContext context, {bool isEdit = false, Map<String, dynamic>? brand}) {
    showDialog(
      context: context,
      builder: (dialogContext) => BrandFormDialog(
        logic: this,
        isEdit: isEdit,
        brand: brand,
      ),
    );
  }

  void showBrandDetails(BuildContext context, Map<String, dynamic> brand) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المعرف: ${brand['id']}'),
            Text('الاسم: ${brand['name']}'),
            Text('الوصف: ${brand['description'] ?? 'غير متوفر'}'),
            Text('استخدام للإصلاح: ${brand['use_for_repair'] == 1 ? 'نعم' : 'لا'}'),
            Text('المنتجات المرتبطة: ${brand['linked_products_count'] ?? 0}'),
          ],
        ),
      ),
    );
  }

  Future<void> exportToCSV() async {
    try {
      List<List<dynamic>> csvData = [
        ['المعرف', 'الاسم', 'الوصف', 'استخدام للإصلاح', 'المنتجات المرتبطة'],
      ];
      for (var brand in brands) {
        csvData.add([
          brand['id'],
          brand['name'],
          brand['description'] ?? 'غير متوفر',
          brand['use_for_repair'] == 1 ? 'نعم' : 'لا',
          brand['linked_products_count'] ?? 0,
        ]);
      }
      String csv = const ListToCsvConverter().convert(csvData);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/brands_export.csv';
      final file = File(path);
      await file.writeAsString(csv);
      _showSuccess('تم التصدير إلى $path');
    } catch (e) {
      _showError('فشل التصدير: $e');
    }
  }

  Future<void> addBrand(Map<String, dynamic> data) async {
    try {
      final token = await System().getToken();
      if (token == null) {
        _showError('لا يوجد رمز وصول');
        return;
      }
      final response = await http.post(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/brand'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        fetchBrands();
        _showSuccess('تم إضافة العلامة التجارية بنجاح');
      } else {
        _showError('فشل إضافة العلامة التجارية: ${response.body}');
      }
    } catch (e) {
      _showError('خطأ: $e');
    }
  }

  Future<void> updateBrand(int id, Map<String, dynamic> data) async {
    try {
      final token = await System().getToken();
      if (token == null) {
        _showError('لا يوجد رمز وصول');
        return;
      }
      final response = await http.put(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/brand/$id'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        fetchBrands();
        _showSuccess('تم تحديث العلامة التجارية بنجاح');
      } else {
        _showError('فشل تحديث العلامة التجارية: ${response.body}');
      }
    } catch (e) {
      _showError('خطأ: $e');
    }
  }

  Future<void> deleteBrand(int id) async {
    try {
      final token = await System().getToken();
      if (token == null) {
        _showError('لا يوجد رمز وصول');
        return;
      }
      final response = await http.delete(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/brand/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        fetchBrands();
        _showSuccess('تم حذف العلامة التجارية بنجاح');
      } else {
        final error = jsonDecode(response.body)['msg'] ?? 'فشل حذف العلامة التجارية';
        _showError(error);
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