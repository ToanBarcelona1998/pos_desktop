import 'package:flutter/material.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/units/units_logic.dart';

class UnitFormDialog extends StatefulWidget {
  final UnitsLogic logic;
  final bool isEdit;
  final Map<String, dynamic>? unit;

  const UnitFormDialog({super.key, required this.logic, required this.isEdit, this.unit});

  @override
  _UnitFormDialogState createState() => _UnitFormDialogState();
}

class _UnitFormDialogState extends State<UnitFormDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController actualNameController;
  late TextEditingController shortNameController;
  late TextEditingController multiplierController;
  bool allowDecimal = false;
  int? baseUnitId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    actualNameController = TextEditingController(text: widget.unit?['actual_name'] ?? '');
    shortNameController = TextEditingController(text: widget.unit?['short_name'] ?? '');
    multiplierController = TextEditingController(text: widget.unit?['base_unit_multiplier']?.toString() ?? '');
    allowDecimal = widget.unit?['allow_decimal'] == 1;
    baseUnitId = widget.unit?['base_unit_id'];
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    actualNameController.dispose();
    shortNameController.dispose();
    multiplierController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          widget.isEdit ? localizations?.translate('edit') ?? 'Edit Unit' : localizations?.translate('add') ?? 'Add Unit',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: actualNameController,
                  decoration: InputDecoration(
                    labelText: localizations?.translate('actual_name') ?? 'Actual Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: shortNameController,
                  decoration: InputDecoration(
                    labelText: localizations?.translate('short_name') ?? 'Short Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(
                    localizations?.translate('allow_decimal') ?? 'Allow Decimal',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                  ),
                  value: allowDecimal,
                  onChanged: (value) => setState(() => allowDecimal = value),
                  activeColor: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: baseUnitId,
                  hint: Text(
                    localizations?.translate('base_unit') ?? 'Base Unit (Optional)',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  items: widget.logic.units.where((u) => u['id'] != widget.unit?['id']).map((u) {
                    return DropdownMenuItem<int>(
                      value: u['id'],
                      child: Text(
                        u['actual_name'],
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => baseUnitId = value),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  ),
                  dropdownColor: theme.colorScheme.surface, // لون خلفية القائمة المنسدلة
                ),
                if (baseUnitId != null) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: multiplierController,
                    decoration: InputDecoration(
                      labelText: localizations?.translate('base_unit_multiplier') ?? 'Multiplier',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Required if base unit selected' : null,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localizations?.translate('cancel') ?? 'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            onPressed: _saveForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              widget.isEdit ? 'Update' : 'Add',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'actual_name': actualNameController.text,
        'short_name': shortNameController.text,
        'allow_decimal': allowDecimal ? 1 : 0,
        if (baseUnitId != null) 'base_unit_id': baseUnitId,
        if (baseUnitId != null) 'base_unit_multiplier': double.parse(multiplierController.text),
      };
      Navigator.pop(context);
      if (widget.isEdit) {
        widget.logic.updateUnit(widget.unit!['id'], data);
      } else {
        widget.logic.addUnit(data);
      }
    }
  }
}