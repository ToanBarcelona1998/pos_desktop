import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';

/// Brand form dialog for adding/editing brands
class BrandFormDialog extends StatefulWidget {
  final BrandEntity? brand;
  final void Function(String name, String? description)? onSubmit;

  const BrandFormDialog({
    super.key,
    this.brand,
    this.onSubmit,
  });

  @override
  State<BrandFormDialog> createState() => _BrandFormDialogState();
}

class _BrandFormDialogState extends State<BrandFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();

  bool get isEditing => widget.brand != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.brand?.name);
    _descriptionController = TextEditingController(text: widget.brand?.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                isEditing
                    ? (l10n?.translate(LocaleKeys.editBrand) ?? 'Edit Brand')
                    : (l10n?.translate(LocaleKeys.addBrand) ?? 'Add Brand'),
                style: theme.textTheme.headlineSmall,
              ),
              SizedBox(height: AppSpacing.lg),
              // Name field
              AppTextField(
                controller: _nameController,
                labelText: l10n?.translate(LocaleKeys.brandName) ?? 'Brand Name',
                hintText: 'Enter brand name',
                prefixIcon: Icons.label_outline,
              ),
              SizedBox(height: AppSpacing.md),
              // Description field
              AppTextField(
                controller: _descriptionController,
                labelText: l10n?.translate(LocaleKeys.description) ?? 'Description',
                hintText: 'Enter description (optional)',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),
              SizedBox(height: AppSpacing.xl),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppTextButton(
                    text: l10n?.translate(LocaleKeys.cancel) ?? 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: AppSpacing.md),
                  AppButton(
                    text: isEditing
                        ? (l10n?.translate(LocaleKeys.update) ?? 'Update')
                        : (l10n?.translate(LocaleKeys.add) ?? 'Add'),
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter brand name')),
      );
      return;
    }

    widget.onSubmit?.call(
      _nameController.text.trim(),
      _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    );
    Navigator.pop(context);
  }
}





