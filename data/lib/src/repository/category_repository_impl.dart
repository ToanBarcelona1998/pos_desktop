import 'dart:convert';

import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/local/system_local_data_source.dart';
import '../data_source/remote/category_remote_data_source.dart';
import '../model/category_model.dart';

/// Implementation of [CategoryRepository]
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource _remoteDataSource;
  final SystemLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  const CategoryRepositoryImpl({
    required CategoryRemoteDataSource remoteDataSource,
    required SystemLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Result<List<CategoryEntity>>> getCategories() async {
    if (!await _networkInfo.isConnected) {
      return getLocalCategories();
    }

    try {
      final categories = await _remoteDataSource.getCategories();
      final entities = categories.map(_mapToEntity).toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<CategoryEntity>> getCategoryById(int id) async {
    final result = await getCategories();
    return result.fold(
      onSuccess: (categories) {
        final category = _findCategoryById(categories, id);
        if (category == null) {
          return const Error(NotFoundFailure(message: 'Category not found'));
        }
        return Success(category);
      },
      onError: (failure) => Error(failure),
    );
  }

  @override
  Future<Result<void>> syncCategories() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final categories = await _remoteDataSource.getCategories();
      final categoriesJson = categories.map((c) => c.toJson()).toList();
      await _localDataSource.insert('taxonomy', jsonEncode(categoriesJson));

      // Store sub-categories separately
      for (final category in categories) {
        if (category.subCategories.isNotEmpty) {
          for (final subCategory in category.subCategories) {
            await _localDataSource.insert(
              'sub_categories',
              jsonEncode({'id': subCategory.id, 'name': subCategory.name}),
              category.id,
            );
          }
        }
      }
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<CategoryEntity>>> getLocalCategories() async {
    try {
      final data = await _localDataSource.get('taxonomy');
      if (data == null) {
        return const Success([]);
      }

      final List<dynamic> categoryList = data is String ? jsonDecode(data) : data;
      final entities = categoryList
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .map(_mapToEntity)
          .toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<CategoryEntity>>> getSubCategories(int parentId) async {
    final result = await getCategories();
    return result.fold(
      onSuccess: (categories) {
        final parent = _findCategoryById(categories, parentId);
        if (parent == null) {
          return const Success([]);
        }
        return Success(parent.subCategories);
      },
      onError: (failure) => Error(failure),
    );
  }

  CategoryEntity? _findCategoryById(List<CategoryEntity> categories, int id) {
    for (final category in categories) {
      if (category.id == id) return category;
      final subCategory = _findCategoryById(category.subCategories, id);
      if (subCategory != null) return subCategory;
    }
    return null;
  }

  CategoryEntity _mapToEntity(CategoryModel model) {
    return CategoryEntity(
      id: model.id,
      name: model.name,
      businessId: model.businessId,
      shortCode: model.shortCode,
      parentId: model.parentId,
      categoryType: model.categoryType,
      description: model.description,
      slug: model.slug,
      subCategories: model.subCategories.map(_mapToEntity).toList(),
      createdAt: model.createdAt != null ? DateTime.tryParse(model.createdAt!) : null,
      updatedAt: model.updatedAt != null ? DateTime.tryParse(model.updatedAt!) : null,
    );
  }
}

