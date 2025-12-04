import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/icon_wrapper_widget.dart';

/// Customer selector dialog widget
class PosCustomerSelectorWidget extends StatefulWidget {
  final List<ContactEntity> customers;
  final ContactEntity? selectedCustomer;
  final bool isLoading;
  final String searchQuery;
  final ValueChanged<String>? onSearch;
  final ValueChanged<ContactEntity?>? onCustomerSelected;
  final VoidCallback? onAddCustomer;

  const PosCustomerSelectorWidget({
    super.key,
    required this.customers,
    this.selectedCustomer,
    this.isLoading = false,
    this.searchQuery = '',
    this.onSearch,
    this.onCustomerSelected,
    this.onAddCustomer,
  });

  @override
  State<PosCustomerSelectorWidget> createState() =>
      _PosCustomerSelectorWidgetState();
}

class _PosCustomerSelectorWidgetState
    extends State<PosCustomerSelectorWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    _searchController.addListener(() {
      widget.onSearch?.call(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      child: Container(
        width: 500,
        height: 600,
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconWrapper(
                  icon: Icons.person,
                  iconColor: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  onTap: null,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n?.translate(LocaleKeys.selectCustomer) ??
                        'Select Customer',
                    style: AppTypography.titleLarge,
                  ),
                ),
                if (widget.onAddCustomer != null)
                  IconButton(
                    icon: Icon(Icons.person_add, color: theme.colorScheme.primary),
                    onPressed: widget.onAddCustomer,
                    tooltip: l10n?.translate('add_customer') ?? 'Add Customer',
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n?.translate(LocaleKeys.search) ?? 'Search...',
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.borderRadiusSm,
                ),
                filled: true,
                fillColor: theme.cardColor,
              ),
              style: AppTypography.bodyMedium,
            ),
            SizedBox(height: AppSpacing.md),
            // Customer list
            Expanded(
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.customers.isEmpty
                      ? _EmptyCustomers(l10n: l10n)
                      : _CustomerList(
                          customers: widget.customers,
                          selectedCustomer: widget.selectedCustomer,
                          onCustomerSelected: (customer) {
                            widget.onCustomerSelected?.call(customer);
                            Navigator.of(context).pop();
                          },
                          theme: theme,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCustomers extends StatelessWidget {
  final AppLocalizations? l10n;

  const _EmptyCustomers({this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            l10n?.translate(LocaleKeys.noCustomersFound) ??
                'No customers found',
            style: AppTypography.bodyLarge.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _CustomerList extends StatelessWidget {
  final List<ContactEntity> customers;
  final ContactEntity? selectedCustomer;
  final ValueChanged<ContactEntity> onCustomerSelected;
  final ThemeData theme;

  const _CustomerList({
    required this.customers,
    this.selectedCustomer,
    required this.onCustomerSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        final isSelected = selectedCustomer?.id == customer.id;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.person,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(
            customer.name,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: customer.mobile != null
              ? Text(
                  customer.mobile!,
                  style: AppTypography.bodySmall,
                )
              : null,
          trailing: isSelected
              ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
              : null,
          selected: isSelected,
          selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
          onTap: () => onCustomerSelected(customer),
        );
      },
    );
  }
}




