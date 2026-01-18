# Tổng Hợp Các Vấn Đề Database và Checkout - Review Ngày 18/01/2026

## 📋 Tổng Quan

Sau khi thực hiện database split, có 2 vấn đề chính:

1. **Lỗi `variations_location_details` table khi create sell**
2. **Không thể sync check-in/checkout khi nhấn nút kết ca**

---

## 🔴 Vấn Đề 1: Lỗi `variations_location_details` Table

### Error Message
```
DB Error: 1 "no such table: variations_location_details"
DB Query: UPDATE variations_location_details 
         SET qty_available = qty_available - ? 
         WHERE variation_id = ? AND location_id = ?
DB Path: /Users/toannv106/Library/Containers/com.ashal.pos.posFinal/Data/Documents/PosUser7.db
```

### Nguyên Nhân

Sau khi split database:
- **Global Database** (`PosGlobal.db`): Chứa bảng `variations_location_details` (theo `GlobalDatabaseHelper`)
- **User Database** (`PosUser{userId}.db`): Không có bảng `variations_location_details` (theo `UserDatabaseHelper`)

**Vấn đề:** Trong `SellLocalDataSource.saveSell()`, code đang cố UPDATE bảng `variations_location_details` trong **user database**, nhưng bảng này chỉ có trong **global database**.

### Code Hiện Tại (SAI)

**File:** `data/lib/src/data_source/local/sell_local_data_source.dart`

```dart
class SellLocalDataSourceImpl implements SellLocalDataSource {
  final UserDatabaseHelper _dbHelper;  // ❌ Chỉ có user database

  @override
  Future<int> saveSell({...}) async {
    return await _dbHelper.database.then((db) async {
      return await db.transaction((txn) async {
        // ... insert sell, sell_lines, sell_payments ...
        
        // ❌ SAI: Cố UPDATE bảng trong user database
        if (isFinalOrSuspended && sellData['location_id'] != null) {
          for (var line in sellLines) {
            await txn.rawUpdate(
              '''
              UPDATE variations_location_details  // ❌ Bảng này không tồn tại trong user DB
              SET qty_available = qty_available - ? 
              WHERE variation_id = ? AND location_id = ?
              ''',
              [line['quantity'], line['variation_id'], sellData['location_id']],
            );
          }
        }
      });
    });
  }
}
```

### Giải Pháp

Cần inject `GlobalDatabaseHelper` vào `SellLocalDataSource` để UPDATE stock trong global database.

**Cách 1: Inject cả 2 databases (Khuyến nghị)**

```dart
class SellLocalDataSourceImpl implements SellLocalDataSource {
  final UserDatabaseHelper _userDbHelper;  // ✅ User DB cho sell data
  final GlobalDatabaseHelper _globalDbHelper;  // ✅ Global DB cho stock update

  SellLocalDataSourceImpl({
    required UserDatabaseHelper userDbHelper,
    required GlobalDatabaseHelper globalDbHelper,  // ✅ Thêm global DB
  })  : _userDbHelper = userDbHelper,
        _globalDbHelper = globalDbHelper;

  @override
  Future<int> saveSell({...}) async {
    final userDb = await _userDbHelper.database;  // ✅ User DB
    
    return await userDb.transaction((txn) async {
      // Insert sell, sell_lines, sell_payments vào user DB
      // ...
      
      // Update stock trong global DB (sau khi commit user DB transaction)
      if (isFinalOrSuspended && sellData['location_id'] != null) {
        final globalDb = await _globalDbHelper.database;  // ✅ Global DB
        
        // Update stock trong global database
        for (var line in sellLines) {
          if (line['variation_id'] != null && line['quantity'] != null) {
            await globalDb.rawUpdate(
              '''
              UPDATE variations_location_details 
              SET qty_available = qty_available - ? 
              WHERE variation_id = ? AND location_id = ?
              ''',
              [
                line['quantity'],
                line['variation_id'],
                sellData['location_id'],
              ],
            );
          }
        }
      }
      
      return sellId;
    });
  }
}
```

**Cách 2: Tạo service riêng để update stock (Clean Architecture hơn)**

Tạo `StockUpdateService` để handle việc update stock, inject `GlobalDatabaseHelper` vào service.

### Files Cần Sửa

1. **`data/lib/src/data_source/local/sell_local_data_source.dart`**
   - Thêm `GlobalDatabaseHelper` vào constructor
   - Sửa logic update stock để dùng global database

2. **`lib/app_config/di.dart`**
   - Update DI để inject `GlobalDatabaseHelper` vào `SellLocalDataSource`

3. **`data/lib/src/data_source/local/sell_local_data_source.dart`** - Method `updateSellLine()` cũng cần sửa (nếu có)

---

## 🔴 Vấn Đề 2: Không Thể Sync Check-in/Checkout

### Nguyên Nhân

Trong `CashierSessionRepositoryImpl.checkOut()`, logic sync sells có **syntax error**:

**File:** `data/lib/src/repository/cashier_session_repository_impl.dart` (dòng 102-129)

```dart
// ❌ SAI: Syntax error
final syncResult = await _sellRepository.syncSells();
final result = syncResult.fold(
  onSuccess: (_) async{  // ❌ async ở đây nhưng không await được
    // Step 3: Try remote check-out
    final remoteSession = await _remoteDataSource.checkOut(...);
    // ...
    return Success(_mapper.toEntity(remoteSession));
  },
  onError: (failure) {
    Logger.logE('Failed to sync some sells before checkout: ${failure.message}', null);
    throw Error(failure);  // ❌ throw Error() không đúng
  },
);

return result;  // ❌ result là Future, cần await
```

**Vấn đề:**
1. `syncResult.fold()` trả về `Future`, nhưng không được `await`
2. `onSuccess` callback có `async` nhưng không thể await được
3. `throw Error(failure)` không đúng - cần `return Error(failure)`

### Code Đúng

```dart
@override
Future<Result<CashierSessionEntity>> checkOut({...}) async {
  try {
    // Step 1: Sync unsynced sessions first
    await syncUnsyncedSessions();

    // Step 2: Sync unsynced sells before checkout
    final syncResult = await _sellRepository.syncSells();
    
    // ✅ Sửa: Handle result đúng cách
    final syncSuccess = await syncResult.fold(
      onSuccess: (_) async => true,
      onError: (failure) async {
        Logger.logE(
          'Failed to sync some sells before checkout: ${failure.message}',
          null,
        );
        // Continue with checkout even if sync fails (optional)
        // Hoặc return false để block checkout
        return false;
      },
    );

    // ✅ Nếu muốn bắt buộc sync phải thành công:
    if (!syncSuccess) {
      return Error(NetworkFailure(
        message: 'Failed to sync sells before checkout. Please check your network connection.',
      ));
    }

    // Step 3: Try remote check-out - BẮT BUỘC phải thành công
    final remoteSession = await _remoteDataSource.checkOut(
      closingAmount: closingAmount,
      closingAmountOnStaff: closingAmountOnStaff,
      totalCardSlips: totalCardSlips,
      totalCheques: totalCheques,
      closingNote: closingNote,
      denominations: denominations,
    );

    // Step 4: Update local session after successful remote check-out
    await _localDataSource.updateSession(remoteSession);
    if (remoteSession.id != null) {
      await _localDataSource.markSessionAsSynced(remoteSession.id!);
    }

    return Success(_mapper.toEntity(remoteSession));
  } catch (e) {
    Logger.logE('Check-out failed - must retry', e);
    return Error(ExceptionHandler.handleException(e));
  }
}
```

**Hoặc cách đơn giản hơn:**

```dart
@override
Future<Result<CashierSessionEntity>> checkOut({...}) async {
  try {
    // Step 1: Sync unsynced sessions first
    await syncUnsyncedSessions();

    // Step 2: Sync unsynced sells before checkout
    final syncResult = await _sellRepository.syncSells();
    
    // ✅ Handle sync result
    await syncResult.fold(
      onSuccess: (_) {
        Logger.logI('All unsynced sells synced successfully before checkout');
      },
      onError: (failure) {
        Logger.logE(
          'Failed to sync some sells before checkout: ${failure.message}',
          null,
        );
        // Có thể continue hoặc return error tùy business logic
      },
    );

    // ✅ Nếu muốn bắt buộc sync phải thành công, check kết quả:
    final syncSuccess = syncResult.fold(
      onSuccess: (_) => true,
      onError: (_) => false,
    );
    
    if (!syncSuccess) {
      return Error(NetworkFailure(
        message: 'Failed to sync sells before checkout. Please check your network connection.',
      ));
    }

    // Step 3: Try remote check-out
    final remoteSession = await _remoteDataSource.checkOut(...);

    // Step 4: Update local session
    await _localDataSource.updateSession(remoteSession);
    if (remoteSession.id != null) {
      await _localDataSource.markSessionAsSynced(remoteSession.id!);
    }

    return Success(_mapper.toEntity(remoteSession));
  } catch (e) {
    Logger.logE('Check-out failed - must retry', e);
    return Error(ExceptionHandler.handleException(e));
  }
}
```

### Files Cần Sửa

1. **`data/lib/src/repository/cashier_session_repository_impl.dart`**
   - Sửa method `checkOut()` để handle sync result đúng cách

---

## 📝 Tóm Tắt Các Vấn Đề

| Vấn Đề | File | Dòng | Nguyên Nhân | Giải Pháp |
|--------|------|------|-------------|-----------|
| 1. `variations_location_details` table not found | `sell_local_data_source.dart` | ~130-144 | Cố UPDATE bảng trong user DB thay vì global DB | Inject `GlobalDatabaseHelper` và update stock trong global DB |
| 2. Checkout không sync | `cashier_session_repository_impl.dart` | 102-129 | Syntax error trong `fold()` - không await đúng | Sửa logic handle `syncSells()` result |

---

## ✅ Action Items

### Priority 1: Fix `variations_location_details` Error

- [ ] Inject `GlobalDatabaseHelper` vào `SellLocalDataSource`
- [ ] Sửa logic update stock trong `saveSell()` để dùng global database
- [ ] Kiểm tra method `updateSellLine()` có cần sửa không
- [ ] Update DI trong `di.dart`
- [ ] Test create sell và verify stock được update

### Priority 2: Fix Checkout Sync

- [ ] Sửa logic `checkOut()` trong `cashier_session_repository_impl.dart`
- [ ] Verify sync sells trước khi checkout
- [ ] Test checkout flow với unsynced sells
- [ ] Test checkout flow khi sync fails

---

## 🔍 Code Review Notes

### 1. Database Access Pattern

**Vấn đề:** Sau khi split database, cần xác định rõ:
- Bảng nào thuộc global DB?
- Bảng nào thuộc user DB?
- Khi nào cần truy cập cả 2 databases?

**Giải pháp:**
- Document rõ ràng database structure
- Tạo helper/service để handle cross-database operations
- Avoid direct database access trong business logic

### 2. Error Handling trong Checkout

**Vấn đề:** Logic checkout hiện tại có nhiều điểm có thể fail:
- Sync sessions fail
- Sync sells fail
- Checkout API fail

**Giải pháp:**
- Xác định rõ: bước nào là bắt buộc, bước nào có thể continue
- Log đầy đủ errors để debug
- User feedback rõ ràng khi fail

### 3. Testing Checklist

- [ ] Test create sell → verify stock được update trong global DB
- [ ] Test checkout với unsynced sells → verify sync trước checkout
- [ ] Test checkout khi sync fails → verify error handling
- [ ] Test checkout khi network fails → verify retry mechanism
- [ ] Test với multiple users → verify database isolation

---

## 📚 References

- Database Split Plan: `DATABASE_SPLIT_SOLUTION.md`
- Database Structure: `DATABASE.md`
- Migration Helper: `data/lib/src/data_source/local/database/migration_helper.dart`
- Global DB Helper: `data/lib/src/data_source/local/database/global_database_helper.dart`
- User DB Helper: `data/lib/src/data_source/local/database/user_database_helper.dart`

---

## 🚨 Critical Issues Summary

1. **`variations_location_details` table not found** - CRITICAL
   - Ảnh hưởng: Không thể create sell
   - Fix: Inject `GlobalDatabaseHelper` vào `SellLocalDataSource`

2. **Checkout sync fails** - HIGH
   - Ảnh hưởng: Không thể đóng ca
   - Fix: Sửa syntax error trong `checkOut()` method

---

*Review Date: 2026-01-18*
*Reviewer: AI Assistant*
