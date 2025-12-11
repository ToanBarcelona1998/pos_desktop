import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_responsive.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/localization/locale_keys.dart';
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

class _PosCustomerSelectorWidgetState extends State<PosCustomerSelectorWidget> {
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
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;
    final rSizes = context.rSizes;

    return Container(
      width: 500 * context.rScale,
      height: 600 * context.rScale,
      padding: rSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.translate(LocaleKeys.selectCustomer),
                  style: rTypography.titleLarge,
                ),
              ),
              if (widget.onAddCustomer != null)
                IconButton(
                  icon: Icon(
                    Icons.person_add,
                    color: Colors.black,
                    size: rSizes.iconMd,
                  ),
                  onPressed: widget.onAddCustomer,
                  tooltip: l10n.translate(LocaleKeys.addCustomer),
                ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.black, size: rSizes.iconMd),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          rSpacing.gapVerticalMd,
          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.translate(LocaleKeys.search),
              prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary, size: rSizes.iconMd),
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderRadiusSm,
              ),
              filled: true,
              fillColor: theme.cardColor,
            ),
            style: rTypography.bodyMedium,
          ),
          rSpacing.gapVerticalMd,
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
                        },
                        theme: theme,
                      ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCustomers extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyCustomers({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final rSpacing = context.rSpacing;
    final rTypography = context.rTypography;
    final rSizes = context.rSizes;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: rSizes.illustrationXs,
            color: Colors.grey[400],
          ),
          rSpacing.gapVerticalMd,
          Text(
            l10n.translate(LocaleKeys.noCustomersFound),
            style: rTypography.bodyLarge.copyWith(color: Colors.grey),
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
            backgroundColor:
                theme.colorScheme.primary.withAlpha((0.1 * 255).round()),
            child: Icon(
              Icons.person,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Builder(
            builder: (context) {
              final rTypography = context.rTypography;
              return Text(
                customer.name,
                style: rTypography.bodyLarge.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            },
          ),
          subtitle: customer.mobile != null
              ? Builder(
                  builder: (context) {
                    final rTypography = context.rTypography;
                    return Text(
                      customer.mobile!,
                      style: rTypography.bodySmall,
                    );
                  },
                )
              : null,
          trailing: isSelected
              ? Builder(
                  builder: (context) {
                    final rSizes = context.rSizes;
                    return Icon(Icons.check_circle, color: theme.colorScheme.primary, size: rSizes.iconMd);
                  },
                )
              : null,
          selected: isSelected,
          selectedTileColor:
              theme.colorScheme.primary.withAlpha((0.1 * 255).round()),
          onTap: () => onCustomerSelected(customer),
        );
      },
    );
  }
}
