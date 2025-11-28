import 'package:flutter/material.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/brands/brands_logic.dart';

class BrandFormDialog extends StatefulWidget {
  final BrandsLogic logic;
  final bool isEdit;
  final Map<String, dynamic>? brand;

  const BrandFormDialog({super.key, required this.logic, required this.isEdit, this.brand});

  @override
  _BrandFormDialogState createState() => _BrandFormDialogState();
}

class _BrandFormDialogState extends State<BrandFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  bool useForRepair = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.brand?['name'] ?? '');
    descriptionController = TextEditingController(text: widget.brand?['description'] ?? '');
    useForRepair = widget.brand?['use_for_repair'] == 1;
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.isEdit ? localizations?.translate('edit_brand') ?? 'تعديل علامة تجارية' : localizations?.translate('add_brand') ?? 'إضافة علامة تجارية',
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
                    labelText: localizations?.translate('brand_name') ?? 'اسم العلامة التجارية',
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
                    labelText: localizations?.translate('short_description') ?? 'وصف قصير',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: useForRepair,
                  onChanged: (value) => setState(() => useForRepair = value!),
                  title: Text(localizations?.translate('use_for_repair') ?? 'استخدام للإصلاح'),
                  controlAffinity: ListTileControlAffinity.leading,
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
        'use_for_repair': useForRepair ? 1 : 0,
      };
      Navigator.pop(context);
      if (widget.isEdit) {
        widget.logic.updateBrand(widget.brand!['id'], data);
      } else {
        widget.logic.addBrand(data);
      }
    }
  }
}