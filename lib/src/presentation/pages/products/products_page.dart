import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/app_config/di.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/localization/locale_keys.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_loading.dart';
import 'products_bloc.dart';
import 'products_event.dart';
import 'products_state.dart';
import 'widgets/products_grid_widget.dart';
import 'widgets/products_header_widget.dart';

/// Products page
class ProductsPage extends StatelessWidget {
  final int locationId;

  const ProductsPage({
    super.key,
    this.locationId = 1,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductsBloc(
        initialLocationId: locationId,
        productRepository: sl.get<ProductRepository>(),
        getProductsUseCase: sl.get<GetProductsUseCase>(),
        searchProductsUseCase: sl.get<SearchProductsUseCase>(),
      )..add(
          ProductsLoad(
            locationId: locationId,
          ),
        ),
      child: const _ProductsView(),
    );
  }
}

class _ProductsView extends StatelessWidget {
  const _ProductsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocConsumer<ProductsBloc, ProductsState>(
      listenWhen: (previous, current) => previous.failure != current.failure,
      listener: (context, state) {
        if (state.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure!.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n?.translate(LocaleKeys.products) ?? 'Products'),
            actions: [
              if (state.isSyncing)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: () =>
                      context.read<ProductsBloc>().add(const ProductsSync()),
                  tooltip: l10n?.translate(LocaleKeys.sync) ?? 'Sync',
                ),
            ],
          ),
          body: _buildBody(context, state, l10n),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProductsState state,
    AppLocalizations? l10n,
  ) {
    return Column(
      children: [
        // Header with search
        ProductsHeaderWidget(
          totalProducts: state.totalProducts,
          searchQuery: state.searchQuery,
          onSearch: (query) {
            context.read<ProductsBloc>().add(ProductsSearch(query));
          },
        ),
        // Products content
        Expanded(
          child: _buildContent(context, state, l10n),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProductsState state,
    AppLocalizations? l10n,
  ) {
    if (state.isLoading) {
      return const AppLoadingCenter();
    }

    if (state.products.isEmpty) {
      if (state.searchQuery.isNotEmpty) {
        return AppEmptyState.noResults(
          query: state.searchQuery,
          onClear: () {
            context.read<ProductsBloc>().add(const ProductsSearch(''));
          },
        );
      }
      return AppEmptyState.noData(
        title: l10n?.translate(LocaleKeys.noProductsAvailable) ?? 'No Products',
        message: 'Add products to get started',
        onRefresh: () =>
            context.read<ProductsBloc>().add(const ProductsRefresh()),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ProductsBloc>().add(const ProductsRefresh());
      },
      child: ProductsGridWidget(
        products: state.products,
        isLoadingMore: state.isLoadingMore,
        hasMore: state.hasMore,
        onLoadMore: () {
          context.read<ProductsBloc>().add(const ProductsLoadMore());
        },
      ),
    );
  }
}









