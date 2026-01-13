# Cashier Session Integration Plan - POS Page

## 📋 Tổng Quan

Plan này mô tả cách integrate `CashierSessionCubit` vào `pos_page.dart` để quản lý check-in/check-out của cashier.

**⚠️ Lưu ý quan trọng về App Architecture:**
- App **KHÔNG sử dụng navigation stack** như bình thường
- App chỉ có **1 page active** tại một thời điểm: `pos_page.dart` (offline) hoặc `pos_online_page.dart` (online/webview)
- Khi logout, app gọi `AuthCubit.logout()` → emit `Unauthenticated` state
- App tự động handle `Unauthenticated` state (không cần navigate thủ công)
- `AuthCubit.logout()` sẽ tự động:
  - Clear token
  - Delete user database (bao gồm cashier sessions)
  - Clear cache
  - Emit `Unauthenticated` state

## 🎯 Mục Tiêu

- ✅ Check-in tự động khi mở POS page (nếu chưa có active session)
- ✅ Hiển thị check-in dialog khi cần
- ✅ Xử lý nút đóng ca (`onCloseSession`) trong `PosAppBarWidget`
- ✅ Hiển thị check-out dialog với đầy đủ thông tin
- ✅ **Gọi `AuthCubit.logout()` sau khi check-out thành công** (thay vì navigate)
- ✅ Sync session data khi online/offline

---

## 📦 Phase 1: Add CashierSessionCubit Provider

### 1.1 Add to MultiBlocProvider in pos_online_page.dart

**File:** `lib/src/presentation/pages/pos_online/pos_online_page.dart`

**Tasks:**
- [ ] Thêm `BlocProvider<CashierSessionCubit>` vào `MultiBlocProvider` trong `build()` method
- [ ] Tạo `CashierSessionCubit` instance (tương tự `PosBloc` và `PosOnlineBloc`)

**Current Structure:**
```dart
@override
Widget build(BuildContext context) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(create: (context) => _posOnlineBloc),
      BlocProvider(
        create: (context) => PosBloc(...),
      ),
    ],
    child: ...
  );
}
```

**Target Structure:**
```dart
@override
Widget build(BuildContext context) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(create: (context) => _posOnlineBloc),
      BlocProvider(
        create: (context) => PosBloc(...),
      ),
      BlocProvider(
        create: (context) => CashierSessionCubit(),
      ),
    ],
    child: ...
  );
}
```

**Note:**
- `CashierSessionCubit` sẽ available cho cả `PosOnlinePage` và `PosPage` (khi `showOfflinePos == true`)
- Không cần tạo ở route vì app không dùng route structure như bình thường

---

## 📦 Phase 2: Initialize Cashier Session After PosBloc is Ready

### 2.1 Add Initialize Logic in PosBloc Listener

**File:** `lib/src/presentation/pages/pos/pos_page.dart`

**Tasks:**
- [ ] **KHÔNG** init trong `initState()` - chờ PosBloc load xong
- [ ] Thêm listener trong `BlocConsumer<PosBloc, PosState>` để listen khi:
  - `pageStatus` chuyển từ `loading` sang `idle` (POS đã init xong)
  - `selectedLocationId` có giá trị (không null)
- [ ] Chỉ init một lần (dùng flag `_cashierSessionInitialized` để track)
- [ ] Lấy `userId` từ `AuthCubit`
- [ ] Lấy `locationId` từ `PosBloc.state.selectedLocationId`

**Implementation:**
```dart
class _PosPageState extends State<PosPage> {
  // ... existing fields ...
  bool _cashierSessionInitialized = false; // Track initialization
  
  @override
  void initState() {
    super.initState();
    // ... existing code ...
    context.read<PosBloc>().add(const PosInitialize());
    // DON'T init cashier session here - wait for PosBloc to be ready
  }
  
  // In BlocConsumer<PosBloc, PosState> listener:
  listenWhen: (previous, current) =>
      // ... existing conditions ...
      // Listen when POS is ready and location is selected
      (previous.pageStatus == PosPageStatus.loading && 
       current.pageStatus == PosPageStatus.idle) ||
      (previous.selectedLocationId != current.selectedLocationId &&
       current.selectedLocationId != null),
  listener: (context, state) {
    // ... existing listeners ...
    
    // Initialize cashier session when POS is ready and location is available
    if (!_cashierSessionInitialized &&
        state.pageStatus == PosPageStatus.idle &&
        state.selectedLocationId != null) {
      _initializeCashierSession(context, state.selectedLocationId!);
    }
  },
  
  Future<void> _initializeCashierSession(
    BuildContext context,
    int locationId,
  ) async {
    if (_cashierSessionInitialized) return; // Prevent multiple calls
    
    final authCubit = context.read<AuthCubit>();
    final user = authCubit.state is Authenticated 
        ? (authCubit.state as Authenticated).user 
        : null;
    
    if (user == null) {
      Logger.logI('User not authenticated, skipping cashier session init');
      return;
    }
    
    _cashierSessionInitialized = true; // Mark as initialized
    
    final cashierSessionCubit = context.read<CashierSessionCubit>();
    await cashierSessionCubit.initialize(
      userId: user.id,
      locationId: locationId,
    );
  }
}
```

**Why this approach:**
- ✅ Đảm bảo `PosBloc` đã load xong locations
- ✅ Đảm bảo `selectedLocationId` không null
- ✅ Chỉ init một lần (tránh duplicate calls)
- ✅ Handle case khi location thay đổi (re-init nếu cần)

---

## 📦 Phase 3: Handle Check-in Dialog

### 3.1 Add BlocConsumer for CashierSessionCubit

**File:** `lib/src/presentation/pages/pos/pos_page.dart`

**Tasks:**
- [ ] Wrap existing `BlocConsumer<PosBloc, PosState>` với `BlocConsumer<CashierSessionCubit, CashierSessionState>`
- [ ] Listen for `showCheckInDialog` state
- [ ] Show `CashierCheckInDialog` khi `showCheckInDialog == true`
- [ ] Handle check-in callback

**Implementation:**
```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);

  return BlocConsumer<CashierSessionCubit, CashierSessionState>(
    listenWhen: (previous, current) =>
        previous.showCheckInDialog != current.showCheckInDialog ||
        previous.showCheckOutDialog != current.showCheckOutDialog ||
        previous.checkOutSuccess != current.checkOutSuccess ||
        previous.errorMessage != current.errorMessage,
    listener: (context, sessionState) {
      // Show check-in dialog
      if (sessionState.showCheckInDialog) {
        _showCheckInDialog(context);
      }
      
      // Show check-out dialog (handled in Phase 4)
      if (sessionState.showCheckOutDialog) {
        _showCheckOutDialog(context, sessionState);
      }
      
      // Logout after successful check-out
      if (sessionState.checkOutSuccess) {
        _logoutAfterCheckOut(context);
      }
      
      // Show error if any
      if (sessionState.errorMessage != null) {
        ToastManager.showError(context, sessionState.errorMessage!);
      }
    },
    builder: (context, sessionState) {
      // Return existing POS BlocConsumer
      return BlocConsumer<PosBloc, PosState>(
        // ... existing code ...
      );
    },
  );
}

void _showCheckInDialog(BuildContext context) {
  final authCubit = context.read<AuthCubit>();
  final posBloc = context.read<PosBloc>();
  final cashierSessionCubit = context.read<CashierSessionCubit>();
  
  final user = authCubit.state is Authenticated 
      ? (authCubit.state as Authenticated).user 
      : null;
  final locationId = posBloc.state.selectedLocationId;
  
  if (user == null || locationId == null) {
    ToastManager.showError(context, 'User or location not available');
    return;
  }
  
  DialogProvider.showDialog(
    context: context,
    dialog: CashierCheckInDialog(
      onCheckIn: (amount) async {
        await cashierSessionCubit.checkIn(
          userId: user.id,
          locationId: locationId,
          amount: amount,
        );
      },
    ),
  );
}
```

---

## 📦 Phase 4: Handle Check-out Dialog (Nút Đóng Ca)

### 4.1 Connect onCloseSession to CashierSessionCubit

**File:** `lib/src/presentation/pages/pos/pos_page.dart`

**Tasks:**
- [ ] Update `onCloseSession` callback trong `PosAppBarWidget`
- [ ] Gọi `cashierSessionCubit.showCheckOutDialog()` khi click nút đóng ca
- [ ] Validate có active session trước khi show dialog

**Implementation:**
```dart
// In build method, update PosAppBarWidget
appBar: PosAppBarWidget(
  // ... existing props ...
  onCloseSession: () {
    final cashierSessionCubit = context.read<CashierSessionCubit>();
    final sessionState = cashierSessionCubit.state;
    
    // Check if there's an active session
    if (sessionState.activeSession == null) {
      ToastManager.showInfo(
        context,
        'No active session to close',
      );
      return;
    }
    
    // Show check-out dialog
    cashierSessionCubit.showCheckOutDialog();
  },
),
```

### 4.2 Implement Check-out Dialog Handler

**File:** `lib/src/presentation/pages/pos/pos_page.dart`

**Tasks:**
- [ ] Implement `_showCheckOutDialog()` method
- [ ] Lấy thông tin từ `activeSession`, `AuthCubit`, và `PosBloc`
- [ ] Pass đầy đủ params cho `CashierCheckOutDialog`
- [ ] Handle check-out callback

**Implementation:**
```dart
void _showCheckOutDialog(
  BuildContext context,
  CashierSessionState sessionState,
) {
  if (sessionState.activeSession == null) {
    return;
  }
  
  final authCubit = context.read<AuthCubit>();
  final posBloc = context.read<PosBloc>();
  final cashierSessionCubit = context.read<CashierSessionCubit>();
  
  final user = authCubit.state is Authenticated 
      ? (authCubit.state as Authenticated).user 
      : null;
  final locationId = posBloc.state.selectedLocationId;
  final location = posBloc.state.locations
      .firstWhere((l) => l.id == locationId, orElse: () => null);
  
  if (user == null || locationId == null) {
    ToastManager.showError(context, 'User or location not available');
    return;
  }
  
  DialogProvider.showDialog(
    context: context,
    dialog: CashierCheckOutDialog(
      session: sessionState.activeSession!,
      cashierName: user.fullName ?? user.name ?? 'Cashier',
      locationName: location?.name ?? 'Location',
      onCheckOut: ({
        required double closingAmount,
        required double closingAmountOnStaff,
        required double totalCardSlips,
        required double totalCheques,
        required String closingNote,
        required Map<String, int> denominations,
      }) async {
        await cashierSessionCubit.checkOut(
          closingAmount: closingAmount,
          closingAmountOnStaff: closingAmountOnStaff,
          totalCardSlips: totalCardSlips,
          totalCheques: totalCheques,
          closingNote: closingNote,
          denominations: denominations,
          userId: user.id,
          locationId: locationId,
        );
      },
    ),
  );
}
```

---

## 📦 Phase 5: Logout After Check-out (Thay vì Navigate)

### 5.1 Implement Logout Logic

**File:** `lib/src/presentation/pages/pos/pos_page.dart`

**Tasks:**
- [ ] Implement `_logoutAfterCheckOut()` method
- [ ] Gọi `AuthCubit.logout()` sau khi check-out thành công
- [ ] **KHÔNG navigate thủ công** - App sẽ tự động handle `Unauthenticated` state
- [ ] Optionally: Check unsynced sells trước khi logout (tương tự `PosOnlineBloc`)

**Implementation:**
```dart
Future<void> _logoutAfterCheckOut(BuildContext context) async {
  final authCubit = context.read<AuthCubit>();
  
  // Optionally: Check for unsynced sells before logout
  // (Similar to PosOnlineBloc logic)
  // For now, logout directly after check-out
  
  await authCubit.logout();
  
  // App will automatically handle Unauthenticated state
  // No manual navigation needed
}
```

**Note:** 
- `AuthCubit.logout()` sẽ tự động:
  - Delete user database (bao gồm cashier sessions)
  - Clear token và cache
  - Emit `Unauthenticated` state
- App architecture sẽ tự động redirect về login page khi `Unauthenticated`
- Không cần `Navigator.pushNamedAndRemoveUntil()` như các app khác

---

## 📦 Phase 6: Handle Location Change

### 6.1 Re-initialize Session When Location Changes

**File:** `lib/src/presentation/pages/pos/pos_page.dart`

**Tasks:**
- [ ] Location change đã được handle trong Phase 2 listener
- [ ] Khi `selectedLocationId` thay đổi, listener sẽ tự động trigger
- [ ] Cần reset `_cashierSessionInitialized = false` khi location thay đổi để cho phép re-init
- [ ] Handle case khi location thay đổi nhưng đang có active session (có thể show warning)

**Implementation:**
```dart
// In BlocConsumer<PosBloc, PosState> listener
listenWhen: (previous, current) =>
    // ... existing conditions ...
    previous.selectedLocationId != current.selectedLocationId,
listener: (context, state) {
  // ... existing listeners ...
  
  // Reset flag when location changes to allow re-initialization
  if (previous.selectedLocationId != current.selectedLocationId) {
    _cashierSessionInitialized = false;
    
    // If there's an active session from previous location, 
    // we might want to show a warning or handle it
    final cashierSessionCubit = context.read<CashierSessionCubit>();
    final sessionState = cashierSessionCubit.state;
    
    if (sessionState.activeSession != null) {
      // Optionally: Show warning that session is for different location
      // Or: Auto check-out previous session
      Logger.logI('Location changed but active session exists for previous location');
    }
    
    // Re-initialize for new location (if location is not null)
    if (current.selectedLocationId != null) {
      _initializeCashierSession(context, current.selectedLocationId!);
    }
  }
},
```

**Note:**
- Location change logic được tích hợp vào Phase 2 listener
- Có thể cần business logic để handle case: active session từ location cũ khi chuyển location mới

---

## 📦 Phase 7: Error Handling & Edge Cases

### 7.1 Handle Edge Cases

**Tasks:**
- [ ] Handle case khi user chưa login
- [ ] Handle case khi location chưa được chọn
- [ ] Handle case khi check-in/check-out fails
- [ ] Show appropriate error messages
- [ ] Prevent multiple dialogs from showing

**Implementation Notes:**
- Check `mounted` trước khi show dialogs
- Use `DialogProvider.showDialog()` để prevent multiple dialogs
- Show loading state khi đang process check-in/check-out
- Handle network errors gracefully

---

## 📋 Implementation Checklist

### Phase 1: Provider Setup
- [ ] Add `CashierSessionCubit` provider to `MultiBlocProvider` in `pos_online_page.dart`
- [ ] Test provider is available in both `PosPage` and `PosOnlinePage`

### Phase 2: Initialize Session
- [ ] Add `_cashierSessionInitialized` flag
- [ ] Add `_initializeCashierSession()` method
- [ ] Add listener condition in `BlocConsumer<PosBloc>` to listen when POS is ready
- [ ] Call `_initializeCashierSession()` when `pageStatus == idle` and `selectedLocationId != null`
- [ ] Test check-in dialog shows when no active session

### Phase 3: Check-in Dialog
- [ ] Add `BlocConsumer<CashierSessionCubit>`
- [ ] Implement `_showCheckInDialog()`
- [ ] Test check-in flow

### Phase 4: Check-out Dialog
- [ ] Connect `onCloseSession` to `showCheckOutDialog()`
- [ ] Implement `_showCheckOutDialog()`
- [ ] Test check-out flow

### Phase 5: Logout After Check-out
- [ ] Implement `_logoutAfterCheckOut()`
- [ ] Test logout after check-out
- [ ] Verify app redirects to login automatically

### Phase 6: Location Change
- [ ] Listen to location changes
- [ ] Re-initialize session
- [ ] Test location change flow

### Phase 7: Error Handling
- [ ] Handle all edge cases
- [ ] Test error scenarios
- [ ] Test network failures

---

## 🚨 Important Notes

1. **Timing**: Initialize cashier session sau khi POS đã load xong (dùng `addPostFrameCallback`)

2. **State Management**: 
   - `CashierSessionCubit` state độc lập với `PosBloc`
   - Cần sync khi location thay đổi

3. **Dialog Management**:
   - Sử dụng `DialogProvider.showDialog()` để prevent multiple dialogs
   - Check `mounted` trước khi show dialogs

4. **Data Requirements**:
   - `userId` từ `AuthCubit`
   - `locationId` từ `PosBloc.state.selectedLocationId`
   - Cả hai phải có trước khi initialize session

5. **Check-out Flow**:
   - User click nút đóng ca → Show check-out dialog
   - User nhập thông tin → Call `checkOut()`
   - Success → Call `AuthCubit.logout()` (app tự động redirect về login)
   - Error → Show error message

6. **App Architecture**:
   - App không dùng navigation stack
   - Chỉ có 1 page active: `pos_page` hoặc `pos_online_page`
   - Logout = `AuthCubit.logout()` → `Unauthenticated` state
   - App tự động handle `Unauthenticated` state (không cần navigate thủ công)

7. **Session Persistence**:
   - Session được lưu local (SQLite)
   - Sync với server khi online
   - Clear session khi logout (đã implement trong `AuthCubit._cleanupOnLogout()`)
   - `AuthCubit.logout()` sẽ delete user database → cashier sessions cũng bị xóa

---

## 📚 Related Files

### Core Files
- `lib/src/presentation/pages/pos/cashier_session/cashier_session_cubit.dart`
- `lib/src/presentation/pages/pos/cashier_session/cashier_session_state.dart`
- `lib/src/presentation/pages/pos/widgets/cashier_checkin_dialog.dart`
- `lib/src/presentation/pages/pos/widgets/cashier_checkout_dialog.dart`

### Pages
- `lib/src/presentation/pages/pos/pos_page.dart`
- `lib/src/core/navigation/app_navigator.dart`

### Services
- `domain/lib/src/repository/cashier_session_repository.dart`
- `data/lib/src/repository/cashier_session_repository_impl.dart`

---

## 🎯 Success Criteria

✅ Check-in dialog shows automatically when opening POS page without active session
✅ Check-in works and session is saved
✅ Nút đóng ca triggers check-out dialog
✅ Check-out dialog shows correct session information
✅ Check-out works and session is closed
✅ **Logout after successful check-out** (app auto-redirects to login)
✅ Error handling works correctly
✅ Location change re-initializes session
✅ No crashes or memory leaks
