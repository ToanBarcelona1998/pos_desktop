# POS Flow Review and Risks Analysis

## Tổng quan

Tài liệu này tổng hợp toàn bộ flow POS hiện tại, các risks/issues được phát hiện, và plan enhance/fix.

---

## 1. Checkout Flow

### 1.1. Flow hiện tại

```
User nhấn "Đóng ca" 
  → PosPage: onCloseSession() 
  → CashierSessionCubit.showCheckOutDialog()
  → CashierCheckOutDialog hiển thị
  → User điền thông tin checkout
  → CashierSessionCubit.checkOut()
  → CashierSessionRepositoryImpl.checkOut()
  → Step 1: Sync unsynced sessions (check-in nếu có)
  → Step 2: Sync unsynced sells
  → Step 3: Call remote checkout API
  → Step 4: Mark local session as synced
  → Success → CashierSessionCubit emits checkOutSuccess: true
  → PosPage: _logoutAfterCheckOut() 
  → AuthCubit.logout()
  → _cleanupOnLogout() → deleteUserDatabase(userId)
  → Emit Unauthenticated → Navigate to login
```

### 1.2. Vấn đề đã fix

✅ **Checkout logic đã được đơn giản hóa**:
- Sau khi checkout thành công trên server, chỉ cần `markSessionAsSynced()` (không cần update toàn bộ fields)
- Lý do: User database sẽ bị xóa ngay sau khi logout, nên không cần update phức tạp
- 409 Conflict được xử lý như checkout thành công (mark as synced và return success)

### 1.3. Risks còn lại

⚠️ **Risk 1: Race condition giữa checkout và logout**
- **Mô tả**: Nếu `markSessionAsSynced()` fail sau khi checkout API thành công, nhưng trước khi logout, có thể có inconsistent state
- **Impact**: Low - Database sẽ bị xóa ngay sau đó
- **Mitigation**: Đã wrap trong try-catch, log error nhưng không fail checkout

⚠️ **Risk 2: Checkout API success nhưng logout fail**
- **Mô tả**: Nếu checkout thành công nhưng `AuthCubit.logout()` fail, user sẽ vẫn ở POS page
- **Impact**: Medium - User có thể checkout nhiều lần
- **Mitigation**: Cần review `AuthCubit.logout()` để đảm bảo luôn success hoặc có error handling

---

## 2. Cashier Session Flow

### 2.1. Check-in Flow

```
POS Page initialize (location selected)
  → PosPage: _initializeCashierSession()
  → CashierSessionCubit.initialize()
  → CashierSessionRepository.getActiveSession()
  → No active session found
  → CashierSessionCubit emits showCheckInDialog: true
  → PosPage: _showCheckInDialog()
  → CashierCheckInDialog hiển thị
  → User nhập opening amount
  → CashierSessionCubit.checkIn()
  → CashierSessionRepository.checkIn()
  → Save to local DB (isSynced: false)
  → Call remote API
  → Update local session (isSynced: true)
  → Success → Session active
```

### 2.2. Check-in Risks

⚠️ **Risk 3: Check-in fail sau khi save local**
- **Mô tả**: Nếu save local thành công nhưng remote API fail, session sẽ remain `isSynced: false`
- **Impact**: Medium - Session sẽ được retry sync khi checkout, nhưng có thể có nhiều unsynced sessions
- **Mitigation**: Cần có retry mechanism hoặc cleanup unsynced sessions cũ

⚠️ **Risk 4: Multiple active sessions**
- **Mô tả**: Nếu user check-in nhiều lần (do UI bug hoặc network retry), có thể có nhiều active sessions
- **Impact**: Medium - Logic hiện tại chỉ get 1 active session, nhưng có thể conflict
- **Mitigation**: Cần validation trong `checkIn()` để close previous active sessions

---

## 3. Database Flow

### 3.1. Database Splitting

- **GlobalDatabase** (`PosGlobal.db`): Products, contacts, variations, variations_location_details (stock)
- **UserDatabase** (`PosUser{userId}.db`): Sells, cashier_sessions, sell_lines, sell_payments

### 3.2. Database Risks

✅ **Risk 5: Stock update trong wrong database (ĐÃ FIX)**
- **Mô tả**: `SellLocalDataSourceImpl.saveSell()` đã được fix để update stock trong `GlobalDatabaseHelper` thay vì `UserDatabaseHelper`
- **Status**: Fixed

⚠️ **Risk 6: Database migration issues**
- **Mô tả**: Migration từ old database có thể fail hoặc incomplete
- **Impact**: Medium - User có thể mất data khi migrate
- **Mitigation**: Cần có backup mechanism hoặc validation sau migration

⚠️ **Risk 7: User database không bị xóa khi logout fail**
- **Mô tả**: Nếu `deleteUserDatabase()` fail, data có thể còn lại
- **Impact**: Low - Chỉ ảnh hưởng đến data isolation
- **Mitigation**: Cần ensure `deleteUserDatabase()` luôn success hoặc có cleanup mechanism

---

## 4. POS Page Flow

### 4.1. Initialization Flow

```
PosPage initState()
  → Initialize BarcodeScannerService
  → Initialize WindowManager (desktop/Android)
  → PosBloc.add(PosInitialize)
  → Load locations, categories, brands, products, customers
  → State: pageStatus = idle
  → _initializeCashierSession() (if location selected)
  → Show check-in dialog if no active session
```

### 4.2. Location Change Flow

```
User changes location
  → PosBloc.add(PosSelectLocation(locationId))
  → Update selectedLocationId
  → _cashierSessionInitialized = false
  → _initializeCashierSession() for new location
```

### 4.3. POS Page Risks

⚠️ **Risk 8: Session initialization race condition**
- **Mô tả**: Nếu location change nhanh, có thể có multiple `_initializeCashierSession()` calls
- **Impact**: Low - Có flag `_cashierSessionInitialized` để prevent, nhưng không thread-safe
- **Mitigation**: Cần ensure flag được check và set atomically

⚠️ **Risk 9: Cart data không sync khi window close**
- **Mô tả**: Nếu customer window close đột ngột, cart data có thể không được sync lại
- **Impact**: Low - Cart data chỉ là display, không ảnh hưởng business logic
- **Mitigation**: Có thể cần cleanup mechanism

---

## 5. Sync Flow

### 5.1. Sell Sync Flow

```
Checkout process
  → Step 2: Sync unsynced sells
  → SellRepository.syncSells()
  → Get unsynced sells from local DB
  → For each sell: Call remote API
  → Update local sell (isSynced: true)
```

### 5.2. Session Sync Flow

```
Checkout process
  → Step 1: Sync unsynced sessions
  → Get unsynced sessions from local DB
  → For each session:
    - If status = 'active': Sync check-in
    - If status = 'closed': Sync check-out
  → Update local session (isSynced: true)
```

### 5.3. Sync Risks

⚠️ **Risk 10: Sync fail nhưng checkout vẫn proceed**
- **Mô tả**: Hiện tại, nếu sync sells fail, checkout vẫn tiếp tục (chỉ log warning)
- **Impact**: High - Có thể mất data sells nếu checkout success nhưng sells chưa sync
- **Mitigation**: Cần quyết định: Block checkout nếu sync fail, hoặc có retry mechanism sau checkout

⚠️ **Risk 11: Large sync data timeout**
- **Mô tả**: Nếu có nhiều unsynced sells/sessions, sync có thể timeout
- **Impact**: Medium - User experience bị ảnh hưởng
- **Mitigation**: Cần có progress indicator và batch sync

---

## 6. Window Management Flow

### 6.1. Desktop vs Android

- **Desktop**: `WindowManagerDesktop` sử dụng `desktop_multi_window`
- **Android**: `WindowManagerAndroid` sử dụng `flutter_presentation_display`

### 6.2. Window Risks

⚠️ **Risk 12: Window state không sync khi disconnect**
- **Mô tả**: Nếu secondary display disconnect, state có thể không được update
- **Impact**: Low - Chỉ ảnh hưởng UI state
- **Mitigation**: Cần listen to `connectedDisplaysChangedStream` và cleanup state

⚠️ **Risk 13: Cart sync delay**
- **Mô tả**: Cart data sync có delay 100ms sau khi open window, có thể miss updates
- **Impact**: Low - User experience
- **Mitigation**: Cần có mechanism để ensure cart data được sync đúng

---

## 7. Recommendations

### 7.1. Priority High

1. **Fix Risk 10**: Block checkout nếu sync sells fail, hoặc implement retry mechanism sau checkout
2. **Fix Risk 4**: Validation trong `checkIn()` để close previous active sessions
3. **Fix Risk 2**: Review `AuthCubit.logout()` để ensure luôn success hoặc có proper error handling

### 7.2. Priority Medium

1. **Fix Risk 3**: Implement retry mechanism cho check-in sync fail
2. **Fix Risk 8**: Ensure `_cashierSessionInitialized` flag được check và set atomically
3. **Fix Risk 11**: Implement progress indicator và batch sync cho large data

### 7.3. Priority Low

1. **Fix Risk 6**: Implement backup mechanism cho database migration
2. **Fix Risk 9**: Implement cleanup mechanism cho cart data khi window close
3. **Fix Risk 12**: Listen to display disconnect events và cleanup state

---

## 8. Code Quality Issues

### 8.1. Logging

✅ **Good**: Logging đã được improve với emoji và structured messages
⚠️ **Issue**: Một số log messages chưa consistent (một số dùng emoji, một số không)

### 8.2. Error Handling

✅ **Good**: Try-catch blocks đã được thêm ở critical paths
⚠️ **Issue**: Một số error handling chỉ log mà không có user feedback

### 8.3. State Management

✅ **Good**: BLoC pattern được sử dụng consistently
⚠️ **Issue**: Một số state flags như `_cashierSessionInitialized` không thread-safe

---

## 9. Testing Checklist

### 9.1. Checkout Flow

- [ ] Test checkout với session có unsynced check-in
- [ ] Test checkout với unsynced sells
- [ ] Test checkout với 409 Conflict
- [ ] Test checkout khi API response không có session id
- [ ] Test checkout fail → retry → success
- [ ] Test checkout success → logout success

### 9.2. Check-in Flow

- [ ] Test check-in khi chưa có session
- [ ] Test check-in khi đã có active session (should close previous)
- [ ] Test check-in fail → retry → success
- [ ] Test check-in khi location change

### 9.3. Sync Flow

- [ ] Test sync unsynced sessions trước checkout
- [ ] Test sync unsynced sells trước checkout
- [ ] Test sync fail → checkout should block (if implement fix)
- [ ] Test sync với large data (100+ sells)

### 9.4. Database Flow

- [ ] Test stock update trong GlobalDatabase khi create sell
- [ ] Test database migration từ old database
- [ ] Test user database delete khi logout
- [ ] Test multiple users login/logout

### 9.5. Window Management

- [ ] Test customer window open/close (desktop)
- [ ] Test presentation display (Android)
- [ ] Test cart sync khi window open
- [ ] Test window disconnect handling

---

## 10. Next Steps

1. **Immediate**: Review và approve risks priorities
2. **Short-term**: Implement fixes cho Priority High risks
3. **Medium-term**: Implement fixes cho Priority Medium risks
4. **Long-term**: Improve code quality và add comprehensive tests

---

**Last Updated**: 2026-01-18
**Author**: AI Assistant
**Review Status**: Pending
