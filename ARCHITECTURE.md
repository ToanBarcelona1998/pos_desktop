# Clean Architecture Guide

This document explains the clean architecture structure implemented in this project.

## Overview

The project follows Clean Architecture principles with three main layers:
1. **Domain Layer** - Business logic and entities
2. **Data Layer** - Data sources and repository implementations
3. **Presentation Layer** - UI and state management

## Folder Structure

```
project/
├── domain/                    # Domain layer (pure Dart package)
│   └── lib/
│       ├── domain.dart        # Main export file
│       └── src/
│           ├── core/          # Core domain utilities
│           │   ├── entity.dart
│           │   ├── failure.dart
│           │   ├── result.dart
│           │   └── use_case.dart
│           ├── entity/        # Domain entities
│           │   ├── brand_entity.dart
│           │   ├── contact_entity.dart
│           │   └── user_entity.dart
│           ├── repository/    # Repository abstractions
│           │   ├── auth_repository.dart
│           │   └── brand_repository.dart
│           └── use_case/      # Use cases
│               ├── auth/
│               └── brand/
│
├── data/                      # Data layer (Flutter package)
│   └── lib/
│       ├── data.dart          # Main export file
│       └── src/
│           ├── core/          # Core data utilities
│           │   ├── api_client.dart
│           │   ├── exceptions.dart
│           │   └── network_info.dart
│           ├── model/         # DTOs (Data Transfer Objects)
│           │   ├── brand_model.dart
│           │   └── user_model.dart
│           ├── mapper/        # Entity <-> Model mappers
│           │   ├── brand_mapper.dart
│           │   └── user_mapper.dart
│           ├── data_source/   # Data sources
│           │   ├── local/
│           │   └── remote/
│           └── repository/    # Repository implementations
│               └── brand_repository_impl.dart
│
└── lib/                       # Presentation layer (Main app)
    ├── app_config/            # App configuration & DI
    │   ├── app_config.dart
    │   └── di.dart
    └── src/
        ├── features/          # Feature modules
        │   └── brand/
        │       └── presentation/
        │           ├── cubit/
        │           ├── pages/
        │           └── widgets/
        └── presentation/      # Shared presentation
            ├── base/
            └── widgets/
```

## Layer Details

### Domain Layer (`domain/`)

The innermost layer containing business logic. Has no dependencies on other layers.

#### Core
- `Entity` - Base class for all entities
- `Failure` - Base class for all failures (ServerFailure, NetworkFailure, etc.)
- `Result<T>` - Either success or error result type
- `UseCase` - Base interface for all use cases

#### Entities
Pure data classes representing business objects:
```dart
final class BrandEntity extends Entity {
  final int id;
  final String name;
  // ...
}
```

#### Repositories (Abstractions)
Interfaces defining data operations:
```dart
abstract class BrandRepository {
  Future<Result<List<BrandEntity>>> getBrands();
  Future<Result<BrandEntity>> createBrand({...});
}
```

#### Use Cases
Single-responsibility classes for business operations:
```dart
class GetBrandsUseCase implements UseCaseNoParams<List<BrandEntity>> {
  final BrandRepository _repository;
  
  Future<Result<List<BrandEntity>>> call() async {
    return await _repository.getBrands();
  }
}
```

### Data Layer (`data/`)

Implements domain layer abstractions. Handles data sources and transformations.

#### Models (DTOs)
Data classes for API/database communication:
```dart
class BrandModel extends BaseModel {
  factory BrandModel.fromJson(Map<String, dynamic> json) {...}
  Map<String, dynamic> toJson() {...}
}
```

#### Mappers
Convert between DTOs and Entities:
```dart
class BrandMapper implements ReadOnlyMapper<BrandModel, BrandEntity> {
  BrandEntity toEntity(BrandModel model) {...}
}
```

#### Data Sources
- **Remote**: API calls
- **Local**: Database/SharedPreferences

```dart
abstract class BrandRemoteDataSource {
  Future<List<BrandModel>> getBrands();
}
```

#### Repository Implementations
Implement domain repository interfaces:
```dart
class BrandRepositoryImpl implements BrandRepository {
  final BrandRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  
  Future<Result<List<BrandEntity>>> getBrands() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }
    try {
      final models = await _remoteDataSource.getBrands();
      return Success(_mapper.toEntityList(models));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }
}
```

### Presentation Layer (`lib/src/`)

UI components and state management using BLoC/Cubit.

#### Base Classes
- `BaseCubit` - Base cubit with safe emit
- `DataCubit` - Cubit for CRUD operations
- `BaseState` - Base state classes

#### Features
Each feature is organized in its own folder:
```
features/brand/
├── presentation/
│   ├── cubit/
│   │   ├── brand_list_cubit.dart
│   │   └── brand_list_state.dart
│   ├── pages/
│   │   └── brand_list_page.dart
│   └── widgets/
│       └── brand_item_widget.dart
```

## Dependency Injection

Dependencies are registered in `lib/app_config/di.dart`:

```dart
// Register repository
sl.registerLazy<BrandRepository>(() => BrandRepositoryImpl(
  remoteDataSource: sl.get<BrandRemoteDataSource>(),
  networkInfo: sl.get<NetworkInfo>(),
));

// Register use case
sl.registerLazy<GetBrandsUseCase>(
  () => GetBrandsUseCase(sl.get<BrandRepository>()),
);
```

## How to Add a New Feature

1. **Domain Layer**:
   - Create entity in `domain/lib/src/entity/`
   - Create repository interface in `domain/lib/src/repository/`
   - Create use cases in `domain/lib/src/use_case/`

2. **Data Layer**:
   - Create model (DTO) in `data/lib/src/model/`
   - Create mapper in `data/lib/src/mapper/`
   - Create data source in `data/lib/src/data_source/`
   - Implement repository in `data/lib/src/repository/`

3. **Presentation Layer**:
   - Create feature folder in `lib/src/features/`
   - Create cubit/state
   - Create pages and widgets

4. **DI**:
   - Register all dependencies in `lib/app_config/di.dart`

## Error Handling

Errors are handled using the `Result<T>` type:

```dart
final result = await getBrandsUseCase();
result.fold(
  onSuccess: (brands) => emit(BrandListLoaded(brands)),
  onError: (failure) => emit(BrandListError(failure)),
);
```

## Comparison: Old vs New Architecture

### Old Approach (BrandsLogic)
```dart
class BrandsLogic {
  // Mixed concerns: UI, API calls, state management
  Future<void> fetchBrands() async {
    final token = await System().getToken();
    final response = await http.get(...);
    // Direct UI updates
    _state.setState(() => isLoading = false);
  }
}
```

### New Approach (Clean Architecture)
```dart
// Domain: Use Case
class GetBrandsUseCase {
  Future<Result<List<BrandEntity>>> call() async {
    return await _repository.getBrands();
  }
}

// Data: Repository Implementation
class BrandRepositoryImpl {
  Future<Result<List<BrandEntity>>> getBrands() async {
    final models = await _remoteDataSource.getBrands();
    return Success(_mapper.toEntityList(models));
  }
}

// Presentation: Cubit
class BrandListCubit {
  Future<void> loadBrands() async {
    emit(BrandListLoading());
    final result = await _getBrandsUseCase();
    result.fold(
      onSuccess: (brands) => emit(BrandListLoaded(brands)),
      onError: (failure) => emit(BrandListError(failure)),
    );
  }
}
```

## Benefits

1. **Testability** - Each layer can be tested independently
2. **Maintainability** - Clear separation of concerns
3. **Scalability** - Easy to add new features
4. **Reusability** - Domain logic is framework-independent
5. **Flexibility** - Easy to swap implementations










