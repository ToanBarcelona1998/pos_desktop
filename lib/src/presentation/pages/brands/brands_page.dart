import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/localization/locale_keys.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_loading.dart';
import 'brands_bloc.dart';
import 'brands_event.dart';
import 'brands_state.dart';
import 'widgets/brand_form_dialog.dart';
import 'widgets/brand_list_widget.dart';
import 'widgets/brands_header_widget.dart';

/// Brands page
class BrandsPage extends StatelessWidget {
  const BrandsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BrandsBloc()..add(const BrandsLoad()),
      child: const _BrandsView(),
    );
  }
}

class _BrandsView extends StatelessWidget {
  const _BrandsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocConsumer<BrandsBloc, BrandsState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        if (state.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure!.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n?.translate(LocaleKeys.brands) ?? 'Brands'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddBrandDialog(context),
              ),
            ],
          ),
          body: _buildBody(context, state, l10n),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, BrandsState state, AppLocalizations? l10n) {
    if (state.isLoading) {
      return const AppLoadingCenter();
    }

    if (state.brands.isEmpty) {
      return AppEmptyState.noData(
        title: l10n?.translate(LocaleKeys.brands) ?? 'No Brands',
        message: 'Add your first brand to get started',
        onRefresh: () => context.read<BrandsBloc>().add(const BrandsRefresh()),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<BrandsBloc>().add(const BrandsRefresh());
      },
      child: Column(
        children: [
          // Header with search and statistics
          BrandsHeaderWidget(
            totalBrands: state.totalBrands,
            onSearch: (query) {
              context.read<BrandsBloc>().add(BrandsSearch(query));
            },
          ),
          // Brand list
          Expanded(
            child: state.filteredBrands.isEmpty
                ? AppEmptyState.noResults(
                    query: state.searchQuery,
                    onClear: () {
                      context.read<BrandsBloc>().add(const BrandsSearch(''));
                    },
                  )
                : BrandListWidget(
                    brands: state.filteredBrands,
                    isSubmitting: state.isSubmitting,
                    onEdit: (brand) => _showEditBrandDialog(context, brand),
                    onDelete: (brand) => _showDeleteDialog(context, brand),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddBrandDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BrandFormDialog(
        onSubmit: (name, description) {
          context.read<BrandsBloc>().add(BrandsAdd(
            name: name,
            description: description,
          ));
        },
      ),
    );
  }

  void _showEditBrandDialog(BuildContext context, dynamic brand) {
    showDialog(
      context: context,
      builder: (_) => BrandFormDialog(
        brand: brand,
        onSubmit: (name, description) {
          context.read<BrandsBloc>().add(BrandsUpdate(
            brand.copyWith(name: name, description: description),
          ));
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, dynamic brand) {
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.translate(LocaleKeys.delete) ?? 'Delete'),
        content: Text(
          l10n?.translate(LocaleKeys.areYouSureDelete) ?? 
              'Are you sure you want to delete this brand?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.translate(LocaleKeys.cancel) ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<BrandsBloc>().add(BrandsDelete(brand.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n?.translate(LocaleKeys.delete) ?? 'Delete'),
          ),
        ],
      ),
    );
  }
}





