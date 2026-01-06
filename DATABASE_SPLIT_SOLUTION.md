# Giải Pháp Tách Database: Global Database và User Database

## 📋 Tổng Quan

Hiện tại, ứng dụng sử dụng một database duy nhất (`PosDemo{userId}.db`) chứa cả dữ liệu global (products, contacts, variations) và dữ liệu user-specific (sells, sell_lines, sell_payments). Mỗi khi user đăng nhập/đăng xuất, database được tạo mới hoặc xóa, dẫn đến việc mất dữ liệu global và phải sync lại từ đầu.

**Giải pháp:** Tách thành 2 database riêng biệt:
1. **Global Database** (`PosGlobal.db`): Chứa dữ liệu chung, có thể tái sử dụng
2. **User Database** (`PosUser{userId}.db`): Chứa dữ liệu riêng của từng user

---

## 🗂️ Phân Loại Tables

### Global Database Tables (Shared Data)

Các bảng này chứa dữ liệu chung, không phụ thuộc vào user cụ thể:

1. **`system`** - System configuration
   - **Lưu ý:** Cần phân biệt keys global vs user-specific
   - Global keys: `brand`, `taxonomy`, `sub_categories`, `payment_methods`, `location`, `payment_accounts`, `active-subscription`
   - User-specific keys: `token`, `loggedInUser`, `user_permissions` → **Chuyển sang User DB**

2. **`contact`** - Customer/Contact information
   - Dữ liệu khách hàng chung, tất cả users có thể truy cập

3. **`variations`** - Product variations/SKUs
   - Thông tin sản phẩm chung

4. **`variations_location_details`** - Stock quantities per location
   - Số lượng tồn kho theo location

5. **`product_locations`** - Product-location mappings
   - Mapping sản phẩm với các location

### User Database Tables (User-Specific Data)

Các bảng này chứa dữ liệu riêng của từng user:

1. **`sell`** - Sales transactions
   - Giao dịch bán hàng của user

2. **`sell_lines`** - Sale line items
   - Chi tiết các dòng trong giao dịch

3. **`sell_payments`** - Payment transactions
   - Thông tin thanh toán

4. **`system_user`** (Mới) - User-specific system data
   - Chứa các keys từ `system` table cũ như: `token`, `loggedInUser`, `user_permissions`
   - Format tương tự `system` table

---

## 🏗️ Kiến Trúc Mới

### 1. Database Helper Structure

```
DatabaseHelper (Singleton)
├── GlobalDatabaseHelper
│   ├── database: Database (PosGlobal.db)
│   ├── initGlobalDatabase()
│   └── closeGlobalDatabase()
│
└── UserDatabaseHelper
    ├── database: Database (PosUser{userId}.db)
    ├── initUserDatabase(userId)
    └── closeUserDatabase()
```

### 2. File Structure

```
data/lib/src/data_source/local/database/
├── database_helper.dart (Main helper - deprecated, giữ lại để migration)
├── global_database_helper.dart (NEW)
├── user_database_helper.dart (NEW)
└── database_manager.dart (NEW - Quản lý cả 2 databases)
```

---

## 📝 Chi Tiết Implementation

### 1. Global Database Helper

**File:** `data/lib/src/data_source/local/database/global_database_helper.dart`

```dart
class GlobalDatabaseHelper {
  static GlobalDatabaseHelper? _instance;
  static Database? _database;
  static const int _version = 1;
  static const String _dbName = 'PosGlobal.db';

  // Table creation scripts (chỉ global tables)
  static const String _createSystemTable = '''
    CREATE TABLE system (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      keyId INTEGER DEFAULT null,
      key TEXT NOT NULL,
      value TEXT,
      UNIQUE(key, keyId)
    )
  ''';

  static const String _createContactTable = '''...''';
  static const String _createVariationTable = '''...''';
  static const String _createVariationLocationTable = '''...''';
  static const String _createProductLocationsTable = '''...''';

  Future<Database> initGlobalDatabase() async {
    // Path: {documents}/PosGlobal.db (không có userId)
    // onCreate: chỉ tạo global tables
    // onUpgrade: migration cho global tables
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initGlobalDatabase();
    return _database!;
  }
}
```

**Đặc điểm:**
- Database file: `PosGlobal.db` (không có userId)
- Chỉ tạo global tables
- Không bao giờ bị xóa (trừ khi user manually clear app data)
- Version riêng cho global database

### 2. User Database Helper

**File:** `data/lib/src/data_source/local/database/user_database_helper.dart`

```dart
class UserDatabaseHelper {
  static UserDatabaseHelper? _instance;
  static Database? _database;
  static int? _userId;
  static const int _version = 1;
  
  // Table creation scripts (chỉ user-specific tables)
  static const String _createSystemUserTable = '''
    CREATE TABLE system_user (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      keyId INTEGER DEFAULT null,
      key TEXT NOT NULL,
      value TEXT,
      UNIQUE(key, keyId)
    )
  ''';

  static const String _createSellTable = '''...''';
  static const String _createSellLineTable = '''...''';
  static const String _createSellPaymentsTable = '''...''';

  Future<Database> initUserDatabase(int userId) async {
    _userId = userId;
    _database = null; // Reset
    
    // Path: {documents}/PosUser{userId}.db
    // onCreate: chỉ tạo user-specific tables
    // onUpgrade: migration cho user tables
  }

  Future<Database> get database async {
    if (_database != null && _userId != null) return _database!;
    throw Exception('User database not initialized. Call initUserDatabase(userId) first.');
  }

  Future<void> deleteUserDatabase(int userId) async {
    // Xóa file PosUser{userId}.db khi user logout
  }
}
```

**Đặc điểm:**
- Database file: `PosUser{userId}.db`
- Chỉ tạo user-specific tables
- Có thể xóa khi user logout
- Version riêng cho user database

### 3. Database Manager

**File:** `data/lib/src/data_source/local/database/database_manager.dart`

```dart
class DatabaseManager {
  final GlobalDatabaseHelper _globalDb;
  final UserDatabaseHelper _userDb;

  DatabaseManager({
    required GlobalDatabaseHelper globalDb,
    required UserDatabaseHelper userDb,
  }) : _globalDb = globalDb, _userDb = userDb;

  // Get global database
  Future<Database> get globalDatabase => _globalDb.database;

  // Get user database
  Future<Database> get userDatabase => _userDb.database;

  // Initialize both databases
  Future<void> initialize(int userId) async {
    await _globalDb.initGlobalDatabase();
    await _userDb.initUserDatabase(userId);
  }

  // Close both databases
  Future<void> close() async {
    await _globalDb.close();
    await _userDb.close();
  }

  // Delete user database (on logout)
  Future<void> deleteUserDatabase(int userId) async {
    await _userDb.deleteUserDatabase(userId);
  }
}
```

---

## 🔄 Migration Strategy

### Phase 1: Migration từ Database Cũ

**File:** `data/lib/src/data_source/local/database/migration_helper.dart`

```dart
class MigrationHelper {
  /// Migrate data from old single database to new split databases
  static Future<void> migrateFromOldDatabase({
    required Database oldDb,
    required Database globalDb,
    required Database userDb,
    required int userId,
  }) async {
    await oldDb.transaction((txn) async {
      // 1. Migrate global tables to global database
      await _migrateGlobalTables(txn, globalDb);
      
      // 2. Migrate user-specific tables to user database
      await _migrateUserTables(txn, userDb);
      
      // 3. Split system table
      await _migrateSystemTable(txn, globalDb, userDb, userId);
    });
  }

  static Future<void> _migrateGlobalTables(
    Transaction txn,
    Database globalDb,
  ) async {
    // Copy contact, variations, variations_location_details, product_locations
    // Use INSERT OR REPLACE to handle duplicates
  }

  static Future<void> _migrateUserTables(
    Transaction txn,
    Database userDb,
  ) async {
    // Copy sell, sell_lines, sell_payments
    // Filter by userId if needed
  }

  static Future<void> _migrateSystemTable(
    Transaction txn,
    Database globalDb,
    Database userDb,
    int userId,
  ) async {
    // Global keys → global database
    final globalKeys = [
      'brand', 'taxonomy', 'sub_categories', 'payment_methods',
      'location', 'payment_accounts', 'active-subscription',
      'products_last_sync', 'customers_last_sync', 'call_logs_last_sync',
    ];
    
    // User-specific keys → user database (system_user table)
    final userKeys = ['token', 'loggedInUser', 'user_permissions'];
    
    // Query old system table and split accordingly
  }
}
```

### Phase 2: Backward Compatibility

Trong giai đoạn chuyển đổi, có thể giữ `DatabaseHelper` cũ để:
- Đọc dữ liệu từ database cũ
- Migrate sang cấu trúc mới
- Sau đó deprecate và xóa

---

## 🔧 Thay Đổi Logic Cần Thiết

### 1. Data Sources

#### SystemLocalDataSource

**File:** `data/lib/src/data_source/local/system_local_data_source.dart`

**Thay đổi:**
- Phân biệt global keys vs user keys
- Global keys → `GlobalDatabaseHelper`
- User keys → `UserDatabaseHelper` (system_user table)

```dart
class SystemLocalDataSourceImpl implements SystemLocalDataSource {
  final GlobalDatabaseHelper _globalDb;
  final UserDatabaseHelper _userDb;

  // Determine if key is global or user-specific
  bool _isGlobalKey(String key) {
    const globalKeys = [
      'brand', 'taxonomy', 'sub_categories', 'payment_methods',
      'location', 'payment_accounts', 'active-subscription',
      'products_last_sync', 'customers_last_sync', 'call_logs_last_sync',
    ];
    return globalKeys.contains(key);
  }

  @override
  Future<void> insert(String key, String value, [int? keyId]) async {
    if (_isGlobalKey(key)) {
      final db = await _globalDb.database;
      await db.insert('system', {...}, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      final db = await _userDb.database;
      await db.insert('system_user', {...}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  @override
  Future<dynamic> get(String key) async {
    if (_isGlobalKey(key)) {
      final db = await _globalDb.database;
      // Query from global database
    } else {
      final db = await _userDb.database;
      // Query from user database
    }
  }
}
```

#### ContactLocalDataSource

**File:** `data/lib/src/data_source/local/contact_local_data_source.dart`

**Thay đổi:**
- Sử dụng `GlobalDatabaseHelper` thay vì `DatabaseHelper`

```dart
class ContactLocalDataSourceImpl implements ContactLocalDataSource {
  final GlobalDatabaseHelper _dbHelper;

  @override
  Future<void> insertContact(Map<String, dynamic> contact) async {
    final db = await _dbHelper.database; // Global database
    await db.insert('contact', contact, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
```

#### ProductLocalDataSource

**File:** `data/lib/src/data_source/local/product_local_data_source.dart`

**Thay đổi:**
- Sử dụng `GlobalDatabaseHelper` cho các bảng: `variations`, `variations_location_details`, `product_locations`

```dart
class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final GlobalDatabaseHelper _dbHelper;

  @override
  Future<void> insertVariation(Map<String, dynamic> variation) async {
    final db = await _dbHelper.database; // Global database
    await db.insert('variations', variation, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
```

#### SellLocalDataSource

**File:** `data/lib/src/data_source/local/sell_local_data_source.dart`

**Thay đổi:**
- Sử dụng `UserDatabaseHelper` cho các bảng: `sell`, `sell_lines`, `sell_payments`

```dart
class SellLocalDataSourceImpl implements SellLocalDataSource {
  final UserDatabaseHelper _dbHelper;

  @override
  Future<int> saveSell({...}) async {
    final db = await _dbHelper.database; // User database
    // Insert into sell, sell_lines, sell_payments
  }
}
```

### 2. Repository Layer

Không cần thay đổi nhiều ở repository layer vì chúng chỉ gọi data sources. Data sources sẽ tự động route đến đúng database.

### 3. Authentication Flow

**File:** `lib/src/application/auth/auth_cubit.dart`

**Thay đổi:**

```dart
Future<void> _initializeDatabase(int userId) async {
  try {
    // Initialize global database (chỉ cần 1 lần, hoặc check nếu đã có)
    await _databaseManager.initializeGlobalDatabase();
    
    // Initialize user database
    await _databaseManager.initializeUserDatabase(userId);
  } catch (e) {
    Logger.logE('Database initialization error', e);
  }
}

Future<void> _cleanupOnLogout(int? userId) async {
  if (userId != null) {
    // Chỉ xóa user database, giữ nguyên global database
    await _databaseManager.deleteUserDatabase(userId);
  }
  // Close connections
  await _databaseManager.close();
}
```

### 4. Sync Service

**File:** `data/lib/src/service/system_sync_service.dart`

**Thay đổi:**
- Sync global data → Global database
- Sync user-specific data → User database (nếu có)

```dart
class SystemSyncService {
  final GlobalDatabaseHelper _globalDb;
  final UserDatabaseHelper _userDb;

  Future<void> syncAll() async {
    // Sync global data (products, contacts, etc.)
    await syncGlobalData();
    
    // Sync user-specific data (if any)
    // await syncUserData();
  }

  Future<void> syncGlobalData() async {
    final db = await _globalDb.database;
    // Sync products, contacts, variations, etc.
  }
}
```

---

## 📦 Dependency Injection

**File:** `lib/app_config/di.dart`

**Thay đổi:**

```dart
void _registerDatabase() {
  // Register database helpers
  sl.registerLazySingleton<GlobalDatabaseHelper>(
    () => GlobalDatabaseHelper.instance,
  );

  sl.registerLazySingleton<UserDatabaseHelper>(
    () => UserDatabaseHelper.instance,
  );

  sl.registerLazySingleton<DatabaseManager>(
    () => DatabaseManager(
      globalDb: sl<GlobalDatabaseHelper>(),
      userDb: sl<UserDatabaseHelper>(),
    ),
  );

  // Update existing registrations
  sl.registerLazySingleton<SystemLocalDataSource>(
    () => SystemLocalDataSourceImpl(
      globalDbHelper: sl<GlobalDatabaseHelper>(),
      userDbHelper: sl<UserDatabaseHelper>(),
    ),
  );

  sl.registerLazySingleton<ContactLocalDataSource>(
    () => ContactLocalDataSourceImpl(
      dbHelper: sl<GlobalDatabaseHelper>(), // Changed
    ),
  );

  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(
      dbHelper: sl<GlobalDatabaseHelper>(), // Changed
    ),
  );

  sl.registerLazySingleton<SellLocalDataSource>(
    () => SellLocalDataSourceImpl(
      dbHelper: sl<UserDatabaseHelper>(), // Changed
    ),
  );
}
```

---

## ✅ Lợi Ích

1. **Tái sử dụng dữ liệu global:**
   - Products, contacts, variations không cần sync lại mỗi lần đăng nhập
   - Giảm thời gian khởi động app
   - Giảm tải cho server

2. **Bảo mật dữ liệu user:**
   - Dữ liệu user được tách biệt hoàn toàn
   - Dễ dàng xóa dữ liệu user khi logout
   - Không lo lẫn lộn dữ liệu giữa các users

3. **Hiệu suất:**
   - Global database có thể cache lâu dài
   - User database nhỏ hơn, query nhanh hơn
   - Có thể optimize riêng cho từng database

4. **Maintainability:**
   - Code rõ ràng hơn, dễ maintain
   - Migration dễ dàng hơn
   - Có thể scale từng phần riêng biệt

---

## 🚀 Implementation Steps

### Step 1: Tạo Global Database Helper
- [ ] Tạo `global_database_helper.dart`
- [ ] Implement table creation cho global tables
- [ ] Implement migration logic

### Step 2: Tạo User Database Helper
- [ ] Tạo `user_database_helper.dart`
- [ ] Implement table creation cho user tables
- [ ] Implement delete logic

### Step 3: Tạo Database Manager
- [ ] Tạo `database_manager.dart`
- [ ] Implement initialization và cleanup

### Step 4: Update Data Sources
- [ ] Update `SystemLocalDataSource` để phân biệt global/user keys
- [ ] Update `ContactLocalDataSource` → dùng Global DB
- [ ] Update `ProductLocalDataSource` → dùng Global DB
- [ ] Update `SellLocalDataSource` → dùng User DB

### Step 5: Migration Helper
- [ ] Tạo `migration_helper.dart`
- [ ] Implement migration từ old database
- [ ] Test migration với data thật

### Step 6: Update DI
- [ ] Update `di.dart` với các dependencies mới
- [ ] Update `auth_cubit.dart` để initialize databases

### Step 7: Testing
- [ ] Test login/logout flow
- [ ] Test data persistence
- [ ] Test migration từ old database
- [ ] Test sync service

### Step 8: Cleanup
- [ ] Deprecate `DatabaseHelper` cũ
- [ ] Remove old database files sau migration
- [ ] Update documentation

---

## ⚠️ Lưu Ý

1. **System Table Split:**
   - Cần xác định rõ keys nào là global, keys nào là user-specific
   - Có thể cần thêm logic để handle edge cases

2. **Migration:**
   - Cần backup data trước khi migrate
   - Test kỹ migration với nhiều scenarios
   - Có rollback plan nếu migration fail

3. **Backward Compatibility:**
   - Giữ old `DatabaseHelper` trong giai đoạn transition
   - Có thể cần support cả 2 cấu trúc trong một thời gian

4. **Performance:**
   - Monitor performance sau khi split
   - Có thể cần optimize queries nếu cần

5. **Error Handling:**
   - Handle trường hợp global database bị corrupt
   - Handle trường hợp user database không tồn tại
   - Có recovery mechanism

---

## 📚 Files Cần Tạo Mới

1. `data/lib/src/data_source/local/database/global_database_helper.dart`
2. `data/lib/src/data_source/local/database/user_database_helper.dart`
3. `data/lib/src/data_source/local/database/database_manager.dart`
4. `data/lib/src/data_source/local/database/migration_helper.dart`

## 📝 Files Cần Sửa Đổi

1. `data/lib/src/data_source/local/system_local_data_source.dart`
2. `data/lib/src/data_source/local/contact_local_data_source.dart`
3. `data/lib/src/data_source/local/product_local_data_source.dart`
4. `data/lib/src/data_source/local/sell_local_data_source.dart`
5. `lib/app_config/di.dart`
6. `lib/src/application/auth/auth_cubit.dart`
7. `data/lib/src/service/system_sync_service.dart`

---

## 🔍 Testing Checklist

- [ ] Global database được tạo đúng khi app khởi động lần đầu
- [ ] User database được tạo đúng khi user login
- [ ] Global data persist qua các lần login/logout
- [ ] User data bị xóa khi logout
- [ ] Migration từ old database hoạt động đúng
- [ ] Sync service sync vào đúng database
- [ ] System keys được route đúng (global vs user)
- [ ] Performance không bị ảnh hưởng
- [ ] Error handling hoạt động đúng

---

## 📖 References

- Current database structure: `data/lib/src/data_source/local/database/database_helper.dart`
- Current data sources: `data/lib/src/data_source/local/`
- Current sync service: `data/lib/src/service/system_sync_service.dart`

