import 'package:flutter/material.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/warranties/warranties_logic.dart';

class WarrantyFormDialog extends StatefulWidget {
  final WarrantiesLogic logic;
  final bool isEdit;
  final Map<String, dynamic>? warranty;

  const WarrantyFormDialog({super.key, required this.logic, required this.isEdit, this.warranty});

  @override
  _WarrantyFormDialogState createState() => _WarrantyFormDialogState();
}

class _WarrantyFormDialogState extends State<WarrantyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController durationController;
  String? durationType;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.warranty?['name'] ?? '');
    descriptionController = TextEditingController(text: widget.warranty?['description'] ?? '');
    durationController = TextEditingController(text: widget.warranty?['duration']?.toString() ?? '');
    final allowedTypes = ['day', 'month', 'year'];
    final warrantyDurationType = widget.warranty?['duration_type'] as String?;
    durationType = allowedTypes.contains(warrantyDurationType) ? warrantyDurationType : 'year';
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.isEdit ? localizations?.translate('edit') ?? 'تعديل الضمان' : localizations?.translate('add') ?? 'إضافة ضمان',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: SizedBox(
        width: isDesktop ? MediaQuery.of(context).size.width * 0.4 : double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: localizations?.translate('name') ?? 'الاسم',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                  ),
                  validator: (value) => value!.isEmpty ? localizations?.translate('required') ?? 'مطلوب' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: localizations?.translate('description') ?? 'الوصف',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: durationController,
                  decoration: InputDecoration(
                    labelText: localizations?.translate('duration') ?? 'المدة',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return localizations?.translate('required') ?? 'مطلوب';
                    if (int.tryParse(value) == null) return localizations?.translate('invalid_number') ?? 'رقم غير صالح';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: durationType,
                  hint: Text(localizations?.translate('select_duration_type') ?? 'اختر نوع المدة'),
                  items: [
                    {'value': 'day', 'label': localizations?.translate('day') ?? 'يوم'},
                    {'value': 'month', 'label': localizations?.translate('month') ?? 'شهر'},
                    {'value': 'year', 'label': localizations?.translate('year') ?? 'سنة'},
                  ].map((item) {
                    return DropdownMenuItem<String>(
                      value: item['value'],
                      child: Text(item['label']!),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => durationType = value),
                  decoration: InputDecoration(
                    labelText: localizations?.translate('duration_type') ?? 'نوع المدة',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                  ),
                  validator: (value) => value == null ? localizations?.translate('required') ?? 'مطلوب' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localizations?.translate('cancel') ?? 'إلغاء'),
        ),
        ElevatedButton(
          onPressed: _saveForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            widget.isEdit ? localizations?.translate('update') ?? 'تحديث' : localizations?.translate('add') ?? 'إضافة',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'name': nameController.text,
        'description': descriptionController.text,
        'duration': int.parse(durationController.text),
        'duration_type': durationType!,
      };
      Navigator.pop(context);
      if (widget.isEdit) {
        widget.logic.updateWarranty(widget.warranty!['id'], data);
      } else {
        widget.logic.addWarranty(data);
      }
    }
  }
}