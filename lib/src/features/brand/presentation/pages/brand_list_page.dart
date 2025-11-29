import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app_config/di.dart';
import '../cubit/brand_list_cubit.dart';
import '../cubit/brand_list_state.dart';
import '../widgets/brand_item_widget.dart';
import '../widgets/brand_search_widget.dart';

/// Brand list page using clean architecture
class BrandListPage extends StatelessWidget {
  const BrandListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BrandListCubit(
        getBrandsUseCase: sl.get<GetBrandsUseCase>(),
        createBrandUseCase: sl.get<CreateBrandUseCase>(),
        deleteBrandUseCase: sl.get<DeleteBrandUseCase>(),
      )..loadBrands(),
      child: const BrandListView(),
    );
  }
}

class BrandListView extends StatelessWidget {
  const BrandListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brands'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBrandDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<BrandListCubit>().refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          const BrandSearchWidget(),
          Expanded(
            child: BlocBuilder<BrandListCubit, BrandListState>(
              builder: (context, state) {
                return switch (state) {
                  BrandListInitial() => const SizedBox.shrink(),
                  BrandListLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  BrandListLoaded(:final filteredBrands) => filteredBrands.isEmpty
                      ? const Center(child: Text('No brands match your search'))
                      : RefreshIndicator(
                          onRefresh: () => context.read<BrandListCubit>().refresh(),
                          child: ListView.builder(
                            itemCount: filteredBrands.length,
                            itemBuilder: (context, index) {
                              return BrandItemWidget(
                                brand: filteredBrands[index],
                                onDelete: () => _deleteBrand(
                                  context,
                                  filteredBrands[index].id,
                                ),
                              );
                            },
                          ),
                        ),
                  BrandListError(:final message) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(message),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.read<BrandListCubit>().refresh(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  BrandListEmpty() => const Center(
                      child: Text('No brands available'),
                    ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBrandDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Brand'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final cubit = context.read<BrandListCubit>();
              final result = await cubit.createBrand(
                name: nameController.text,
                description: descriptionController.text,
              );

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                _showOperationResult(context, result);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBrand(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Brand'),
        content: const Text('Are you sure you want to delete this brand?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final result = await context.read<BrandListCubit>().deleteBrand(id);
      if (context.mounted) {
        _showOperationResult(context, result);
      }
    }
  }

  void _showOperationResult(BuildContext context, BrandOperationState result) {
    switch (result) {
      case BrandOperationSuccess(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
        break;
      case BrandOperationError(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red,
          ),
        );
        break;
      default:
        break;
    }
  }
}
