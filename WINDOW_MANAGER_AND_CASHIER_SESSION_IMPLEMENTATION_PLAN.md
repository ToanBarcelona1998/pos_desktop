# Window Manager & Cashier Session Implementation Plan

## 📋 Tổng Quan

Plan này giải quyết 3 vấn đề chính:
1. **Window Manager Android chưa được implement đầy đủ** - Logic `WindowManagerAndroid` hiện chỉ có placeholder code
2. **Sync data giữa 2 màn hình** - Logic sync data vẫn nằm trong `OfflineCustomerService` thay vì trong window manager abstraction
3. **Cashier Session chưa được apply vào POS page** - Chưa integrate check-in/check-out vào `pos_page.dart`

---

## 🎯 Mục Tiêu

- ✅ Hoàn thiện `WindowManagerAndroid` với logic đầy đủ cho `flutter_presentation_display`
- ✅ Move sync data logic vào `WindowManagerAbstract` interface để hỗ trợ cả desktop và Android
- ✅ Integrate `CashierSessionCubit` vào `pos_page.dart` với check-in on init và check-out on checkout button
- ✅ Update customer pages (offline/online) để sử dụng window manager abstraction
- ✅ Update POS online page để sử dụng window manager abstraction

---

## 🏗️ Architecture Changes

### Current Architecture:
```
POS Page
  ├── WindowController (desktop_multi_window)
  └── OfflineCustomerService (sync data via WindowMethodChannel)
        └── Customer Page (receives via WindowMethodChannel)
```

### Target Architecture:
```
POS Page
  ├── WindowManagerAbstract (platform-agnostic)
  │     ├── WindowManagerDesktop (desktop_multi_window)
  │     └── WindowManagerAndroid (flutter_presentation_display)
  │           ├── openCustomerWindow()
  │           ├── syncCartData() [NEW]
  │           └── listenToCartUpdates() [NEW]
  └── CashierSessionCubit (check-in/check-out)
```

---

## 📦 Phase 1: Complete WindowManagerAndroid Implementation

### 1.1 Uncomment and Complete WindowManagerAndroid

**File:** `lib/src/core/utils/window_manager_android.dart`

**Tasks:**
- [ ] Uncomment all `FlutterPresentationDisplay` imports and code
- [ ] Implement `openCustomerWindow()` method with proper router names
- [ ] Implement `transferDataToCustomer()` method for syncing cart data
- [ ] Add `listenToCartUpdates()` method to receive updates from presentation display
- [ ] Handle display connection/disconnection events
- [ ] Add error handling for cases when no display is available

**Key Implementation Details:**
```dart
// Router names must match routes in app_navigator.dart
final routerName = type == WindowType.offlineCustomer
    ? '/offline_customer'
    : '/online_customer';

// Sync cart data to presentation display
await _display.transferDataToPresentation(cartData.toJson());

// Listen for updates from presentation display
_display.listenDataFromPresentationDisplay((data) {
  // Handle incoming data
});
```

### 1.2 Add Routes for Presentation Display

**File:** `lib/src/core/navigation/app_navigator.dart`

**Tasks:**
- [ ] Ensure `/offline_customer` route exists and handles presentation display mode
- [ ] Ensure `/online_customer` route exists and handles presentation display mode
- [ ] Add route arguments handling for presentation display data

**Check if routes exist:**
- Current routes may be defined in `main.dart` for desktop multi-window
- Need to ensure they also work in normal navigation for Android presentation display

---

## 📦 Phase 2: Move Sync Data Logic to WindowManagerAbstract

### 2.1 Extend WindowManagerAbstract Interface

**File:** `lib/src/core/utils/window_manager_abstract.dart`

**Tasks:**
- [ ] Add `syncCartData(Map<String, dynamic> data)` method
- [ ] Add `listenToCartUpdates(Function(Map<String, dynamic>) callback)` method
- [ ] Add `unregisterCartListener()` method
- [ ] Define `CartSyncData` model or reuse from `OfflineCustomerService`

**Interface Extension:**
```dart
abstract class WindowManagerAbstract {
  // ... existing methods ...
  
  /// Sync cart data to customer window (presentation display)
  Future<void> syncCartData(Map<String, dynamic> cartData);
  
  /// Listen to cart updates from customer window
  void listenToCartUpdates(Function(Map<String, dynamic>) onUpdate);
  
  /// Unregister cart update listener
  void unregisterCartListener();
}
```

### 2.2 Implement in WindowManagerDesktop

**File:** `lib/src/core/utils/window_manager_desktop.dart`

**Tasks:**
- [ ] Implement `syncCartData()` using `WindowMethodChannel` (reuse `OfflineCustomerService` logic)
- [ ] Implement `listenToCartUpdates()` using `WindowMethodChannel.setMethodCallHandler()`
- [ ] Store callback reference for unregistering

**Implementation:**
```dart
WindowMethodChannel? _methodChannel;
Function(Map<String, dynamic>)? _cartUpdateCallback;

@override
Future<void> syncCartData(Map<String, dynamic> cartData) async {
  if (_customerWindowController == null) return;
  
  _methodChannel ??= WindowMethodChannel(
    'com.oman.offline_customer_channel',
    mode: ChannelMode.unidirectional,
  );
  
  await _methodChannel!.invokeMethod('update_cart', {
    'data': cartData,
  });
}
```

### 2.3 Implement in WindowManagerAndroid

**File:** `lib/src/core/utils/window_manager_android.dart`

**Tasks:**
- [ ] Implement `syncCartData()` using `_display.transferDataToPresentation()`
- [ ] Implement `listenToCartUpdates()` using `_display.listenDataFromPresentationDisplay()`
- [ ] Store callback reference for cleanup

**Implementation:**
```dart
Function(Map<String, dynamic>)? _cartUpdateCallback;

@override
Future<void> syncCartData(Map<String, dynamic> cartData) async {
  if (_currentDisplayId == null) return;
  
  await _display.transferDataToPresentation(cartData);
}

@override
void listenToCartUpdates(Function(Map<String, dynamic>) onUpdate) {
  _cartUpdateCallback = onUpdate;
  _display.listenDataFromPresentationDisplay((data) {
    if (data is Map<String, dynamic>) {
      onUpdate(data);
    }
  });
}
```

### 2.4 Update OfflineCustomerService (Optional Refactor)

**File:** `lib/src/core/services/offline_customer_service.dart`

**Decision:**
- **Option A**: Deprecate `OfflineCustomerService` and move all logic to window managers
- **Option B**: Keep `OfflineCustomerService` as a utility but use window managers internally

**Recommendation:** Option B - Keep service as utility for data conversion, but use window managers for actual syncing.

**Tasks:**
- [ ] Keep `CartSyncData` and `convertToSyncData()` methods (utilities)
- [ ] Update `broadcastCartUpdate()` to use `WindowManagerUtils.getWindowManager().syncCartData()`
- [ ] Update customer page registration to use window manager's `listenToCartUpdates()`

---

## 📦 Phase 3: Update POS Page to Use WindowManagerAbstract

### 3.1 Replace WindowController with WindowManagerAbstract

**File:** `lib/src/presentation/pages/pos/pos_page.dart`

**Tasks:**
- [ ] Replace `WindowController? _customerWindowController` with `WindowManagerAbstract? _windowManager`
- [ ] Initialize window manager in `initState()` using `WindowManagerUtils.getWindowManager()`
- [ ] Update `_openCustomerWindow()` to use `_windowManager.openCustomerWindow()`
- [ ] Replace window status listener with `_windowManager.windowStatusStream`
- [ ] Update dispose to call `_windowManager.dispose()`

**Key Changes:**
```dart
class _PosPageState extends State<PosPage> {
  WindowManagerAbstract? _windowManager;
  StreamSubscription? _windowStatusSubscription;
  
  @override
  void initState() {
    super.initState();
    // ... existing code ...
    
    // Initialize window manager
    try {
      _windowManager = WindowManagerUtils.getWindowManager();
      
      // Listen to window status changes
      _windowStatusSubscription = _windowManager!.windowStatusStream.listen((status) {
        if (mounted && !status.isOpen) {
          context.read<PosBloc>().add(PosChangeCustomerWindowStatus(false));
        }
      });
    } catch (e) {
      // Platform not supported for multi-window
      Logger.logE('Window manager not available', e);
    }
  }
  
  Future<void> _openCustomerWindow(BuildContext context) async {
    if (_windowManager == null) {
      ToastManager.showError(context, 'Multi-window not supported on this platform');
      return;
    }
    
    try {
      final state = context.read<PosBloc>().state;
      final cartSyncData = OfflineCustomerService.convertToSyncData(
        // ... convert state to cart data ...
      );
      
      await _windowManager!.openCustomerWindow(
        type: WindowType.offlineCustomer,
        params: {},
      );
      
      // Sync cart data after opening window
      await Future.delayed(const Duration(milliseconds: 100));
      await _windowManager!.syncCartData(cartSyncData.toJson());
      
      if (mounted) {
        context.read<PosBloc>().add(PosChangeCustomerWindowStatus(true));
      }
    } catch (e) {
      Logger.logE('Failed to open customer window', e);
      if (mounted) {
        ToastManager.showError(context, 'Failed to open customer window');
      }
    }
  }
}
```

### 3.2 Update Cart Sync When Cart Changes

**File:** `lib/src/presentation/pages/pos/pos_page.dart`

**Tasks:**
- [ ] Listen to `PosBloc` state changes for cart updates
- [ ] Call `_windowManager.syncCartData()` whenever cart items, totals, or customer changes
- [ ] Debounce sync calls to avoid too many updates

**Implementation:**
```dart
// In BlocConsumer listener or separate StreamSubscription
if (_windowManager != null && _windowManager!.isCustomerWindowOpen()) {
  final cartSyncData = OfflineCustomerService.convertToSyncData(
    cartItems: current.cartItems,
    subtotal: current.subtotal,
    discount: current.invoiceDiscount,
    tax: current.taxAmount,
    total: current.total,
    currencySymbol: current.currencySymbol,
    customer: current.selectedCustomer,
    paymentMethod: current.selectedPaymentMethod,
    paymentAccount: current.selectedPaymentAccount,
  );
  
  _windowManager!.syncCartData(cartSyncData.toJson());
}
```

---

## 📦 Phase 4: Integrate CashierSessionCubit into POS Page

### 4.1 Add CashierSessionCubit Provider

**File:** `lib/src/presentation/pages/pos/pos_page.dart`

**Tasks:**
- [ ] Wrap `PosPage` with `BlocProvider<CashierSessionCubit>` in parent widget (or use `MultiBlocProvider`)
- [ ] Initialize `CashierSessionCubit` with repository from DI

**Check current provider structure:**
- Check if `pos_page.dart` is already wrapped in a provider
- If using `app_navigator.dart` route generation, add provider there
- Otherwise, wrap in parent widget (e.g., `HomePage`)

### 4.2 Implement Check-in on POS Page Init

**File:** `lib/src/presentation/pages/pos/pos_page.dart`

**Tasks:**
- [ ] In `initState()`, after `PosInitialize`, check for active cashier session
- [ ] If no active session, show check-in dialog
- [ ] Handle check-in dialog result and initialize session
- [ ] Store session state in `CashierSessionCubit`

**Implementation:**
```dart
@override
void initState() {
  super.initState();
  // ... existing code ...
  
  // Initialize cashier session
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeCashierSession(context);
  });
  
  context.read<PosBloc>().add(const PosInitialize());
}

Future<void> _initializeCashierSession(BuildContext context) async {
  final cashierSessionCubit = context.read<CashierSessionCubit>();
  
  // Check for active session
  await cashierSessionCubit.initialize();
  
  final state = cashierSessionCubit.state;
  
  // If no active session, show check-in dialog
  if (state.activeSession == null) {
    // Trigger check-in dialog
    cashierSessionCubit.showCheckInDialog();
  }
}
```

### 4.3 Handle Check-in Dialog in BlocConsumer

**File:** `lib/src/presentation/pages/pos/pos_page.dart`

**Tasks:**
- [ ] Add `BlocConsumer<CashierSessionCubit, CashierSessionState>` wrapper
- [ ] Listen for `showCheckInDialog` state and show dialog
- [ ] Listen for `showCheckOutDialog` state and show dialog
- [ ] Handle `checkOutSuccess` to navigate to login

**Implementation:**
```dart
// Wrap existing BlocConsumer with MultiBlocConsumer or nested BlocConsumer
BlocConsumer<CashierSessionCubit, CashierSessionState>(
  listenWhen: (previous, current) =>
      previous.showCheckInDialog != current.showCheckInDialog ||
      previous.showCheckOutDialog != current.showCheckOutDialog ||
      previous.checkOutSuccess != current.checkOutSuccess,
  listener: (context, sessionState) {
    // Show check-in dialog
    if (sessionState.showCheckInDialog) {
      DialogProvider.showDialog(
        context: context,
        dialog: CashierCheckInDialog(
          onCheckIn: (amount) async {
            final authCubit = context.read<AuthCubit>();
            final user = authCubit.state.user;
            final posBloc = context.read<PosBloc>();
            final locationId = posBloc.state.selectedLocationId;
            
            if (user != null && locationId != null) {
              await context.read<CashierSessionCubit>().checkIn(
                userId: user.id,
                locationId: locationId,
                openingAmount: amount,
              );
            }
          },
        ),
      );
    }
    
    // Show check-out dialog
    if (sessionState.showCheckOutDialog && sessionState.activeSession != null) {
      DialogProvider.showDialog(
        context: context,
        dialog: CashierCheckOutDialog(
          session: sessionState.activeSession!,
          cashierName: context.read<AuthCubit>().state.user?.name ?? 'Cashier',
          locationName: context.read<PosBloc>().state.selectedLocation?.name ?? 'Location',
          onCheckOut: ({
            required double closingAmount,
            required double closingAmountOnStaff,
            required double totalCardSlips,
            required double totalCheques,
            required String closingNote,
            required Map<String, int> denominations,
          }) async {
            await context.read<CashierSessionCubit>().checkOut(
              closingAmount: closingAmount,
              closingAmountOnStaff: closingAmountOnStaff,
              totalCardSlips: totalCardSlips,
              totalCheques: totalCheques,
              closingNote: closingNote,
              denominations: denominations,
            );
          },
        ),
      );
    }
    
    // Navigate to login after successful check-out
    if (sessionState.checkOutSuccess) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  },
  builder: (context, sessionState) {
    // Return existing POS page widget
    return BlocConsumer<PosBloc, PosState>(
      // ... existing POS BlocConsumer code ...
    );
  },
)
```

### 4.4 Add Check-out Button Handler

**File:** `lib/src/presentation/pages/pos/widgets/pos_bottom_bar_widget.dart` or checkout handler

**Tasks:**
- [ ] Find where checkout button is handled (likely in `PosCartWidget` or `PosBottomBarWidget`)
- [ ] Before showing payment dialog, check if cashier session is active
- [ ] If active, trigger check-out dialog via `CashierSessionCubit.showCheckOutDialog()`
- [ ] Only proceed with payment after successful check-out (or if no session required)

**Implementation:**
```dart
// In checkout button handler
void _onCheckoutPressed(BuildContext context) {
  final cashierSessionCubit = context.read<CashierSessionCubit>();
  final sessionState = cashierSessionCubit.state;
  
  // If there's an active session, show check-out dialog first
  if (sessionState.activeSession != null) {
    cashierSessionCubit.showCheckOutDialog();
    return; // Wait for check-out to complete
  }
  
  // Otherwise, proceed with normal checkout
  _showPaymentMethodDialog(context);
}

// After successful check-out (in listener)
// In CashierSessionCubit listener, after checkOutSuccess:
if (sessionState.checkOutSuccess) {
  // Navigate to login (handled in listener above)
  // OR continue with checkout if business logic allows
}
```

**Alternative Approach:**
- If business logic requires checkout to happen AFTER check-out, handle in listener
- If checkout can happen independently, proceed normally

---

## 📦 Phase 5: Update Customer Pages to Use Window Manager

### 5.1 Update OfflineCustomerPage

**File:** `lib/src/presentation/pages/offline_customer/offline_customer_page.dart`

**Tasks:**
- [ ] Replace `OfflineCustomerService().registerHandle()` with `WindowManagerAbstract.listenToCartUpdates()`
- [ ] Get window manager instance (may need to handle case when not in presentation display mode)
- [ ] Update dispose to call `unregisterCartListener()`

**Challenge:** 
- On Android, customer page may be shown as a normal route, not presentation display
- Need to detect if running in presentation display mode vs normal navigation

**Implementation:**
```dart
class _OfflineCustomerPageState extends State<OfflineCustomerPage> {
  WindowManagerAbstract? _windowManager;
  
  @override
  void initState() {
    super.initState();
    
    // Try to get window manager (only available on supported platforms)
    try {
      _windowManager = WindowManagerUtils.getWindowManager();
      
      // Register cart update listener
      _windowManager?.listenToCartUpdates((cartData) {
        if (mounted) {
          setState(() {
            _cartData = CartSyncData.fromJson(cartData);
          });
        }
      });
    } catch (e) {
      // Not in presentation display mode, handle as normal page
      // Or use alternative data source
    }
  }
  
  @override
  void dispose() {
    _windowManager?.unregisterCartListener();
    super.dispose();
  }
}
```

### 5.2 Update OnlineCustomerPage

**File:** `lib/src/presentation/pages/online_customer/online_customer_page.dart`

**Tasks:**
- [ ] Similar to offline customer page
- [ ] May need to pass URL/href via window manager params instead of constructor
- [ ] Update to receive data from window manager if needed

---

## 📦 Phase 6: Update POS Online Page

### 6.1 Replace WindowController Usage

**File:** `lib/src/presentation/pages/pos_online/pos_online_page.dart`

**Tasks:**
- [ ] Replace `WindowController? _customerWindowController` with `WindowManagerAbstract?`
- [ ] Update `_openCustomerWindow()` method (if exists) to use window manager
- [ ] Similar updates as Phase 3.1

---

## 📦 Phase 7: Update Application Routes for Android

### 7.1 Ensure Routes Work for Presentation Display

**File:** `lib/src/core/navigation/app_navigator.dart` or `lib/main.dart`

**Tasks:**
- [ ] Ensure `/offline_customer` route can be accessed from presentation display
- [ ] Ensure `/online_customer` route can accept `href` parameter from arguments
- [ ] Handle case when routes are accessed normally vs from presentation display

**Check:**
- Current routes may be defined in `main.dart` for desktop multi-window
- Need to add them to `app_navigator.dart` if not already there
- Or ensure `main.dart` routes also work for normal navigation

---

## 📦 Phase 8: Testing & Error Handling

### 8.1 Platform Detection

**Tasks:**
- [ ] Test on desktop (Windows/macOS/Linux) - should use `WindowManagerDesktop`
- [ ] Test on Android with secondary display - should use `WindowManagerAndroid`
- [ ] Test on Android without secondary display - should gracefully handle
- [ ] Test on iOS (if supported) - should gracefully handle unsupported platform

### 8.2 Error Handling

**Tasks:**
- [ ] Handle case when `flutter_presentation_display` package not available
- [ ] Handle case when no secondary display available
- [ ] Handle case when presentation display disconnects
- [ ] Show appropriate error messages to user

### 8.3 Cashier Session Edge Cases

**Tasks:**
- [ ] Handle check-in failure (network error, validation error)
- [ ] Handle check-out failure (network error, validation error)
- [ ] Handle case when user closes POS page without check-out
- [ ] Handle case when app is killed during active session
- [ ] Handle session sync failures

---

## 📋 Implementation Checklist

### Phase 1: Complete WindowManagerAndroid
- [ ] Uncomment and implement `WindowManagerAndroid` methods
- [ ] Test on Android device with secondary display
- [ ] Handle errors gracefully

### Phase 2: Move Sync Data Logic
- [ ] Extend `WindowManagerAbstract` interface
- [ ] Implement in `WindowManagerDesktop`
- [ ] Implement in `WindowManagerAndroid`
- [ ] Update `OfflineCustomerService` to use window managers
- [ ] Test data sync on both platforms

### Phase 3: Update POS Page
- [ ] Replace `WindowController` with `WindowManagerAbstract`
- [ ] Update window opening logic
- [ ] Update cart sync logic
- [ ] Test on desktop and Android

### Phase 4: Integrate Cashier Session
- [ ] Add `CashierSessionCubit` provider
- [ ] Implement check-in on init
- [ ] Implement check-out dialog handler
- [ ] Add check-out button handler
- [ ] Test check-in/check-out flow

### Phase 5: Update Customer Pages
- [ ] Update `OfflineCustomerPage`
- [ ] Update `OnlineCustomerPage`
- [ ] Test on both platforms

### Phase 6: Update POS Online Page
- [ ] Replace window controller usage
- [ ] Test on desktop and Android

### Phase 7: Update Routes
- [ ] Ensure routes work for presentation display
- [ ] Test navigation

### Phase 8: Testing
- [ ] Test on all supported platforms
- [ ] Handle edge cases
- [ ] Error handling
- [ ] User feedback

---

## 🚨 Important Notes

1. **Package Installation**: Ensure `flutter_presentation_display` is installed:
   ```bash
   flutter pub get
   ```

2. **Router Names**: Router names used in `WindowManagerAndroid.openCustomerWindow()` must exactly match route names in navigation:
   - `/offline_customer`
   - `/online_customer`

3. **Platform Checks**: Always check platform support before using window managers:
   ```dart
   try {
     final windowManager = WindowManagerUtils.getWindowManager();
     // Use window manager
   } catch (e) {
     // Platform not supported
   }
   ```

4. **Data Format**: Ensure `CartSyncData` format is consistent between platforms (JSON serialization)

5. **Cashier Session**: Check-in/check-out should be required before allowing checkout, but allow graceful degradation if session fails

6. **Testing**: Test thoroughly on actual Android hardware with secondary display (e.g., SUNMI T2s)

---

## 📚 Related Files

### Core Files
- `lib/src/core/utils/platform_helper.dart`
- `lib/src/core/utils/window_manager_abstract.dart`
- `lib/src/core/utils/window_manager_desktop.dart`
- `lib/src/core/utils/window_manager_android.dart`
- `lib/src/core/utils/window_manager_utils.dart`

### Services
- `lib/src/core/services/offline_customer_service.dart`

### Pages
- `lib/src/presentation/pages/pos/pos_page.dart`
- `lib/src/presentation/pages/pos_online/pos_online_page.dart`
- `lib/src/presentation/pages/offline_customer/offline_customer_page.dart`
- `lib/src/presentation/pages/online_customer/online_customer_page.dart`

### Cashier Session
- `lib/src/presentation/pages/pos/cashier_session/cashier_session_cubit.dart`
- `lib/src/presentation/pages/pos/cashier_session/cashier_session_state.dart`
- `lib/src/presentation/pages/pos/widgets/cashier_checkin_dialog.dart`
- `lib/src/presentation/pages/pos/widgets/cashier_checkout_dialog.dart`

### Navigation
- `lib/src/core/navigation/app_navigator.dart`
- `lib/main.dart`

---

## 🎯 Success Criteria

✅ Window manager works on both desktop and Android
✅ Cart data syncs correctly between main and customer windows/displays
✅ Cashier session check-in happens on POS page init
✅ Cashier session check-out happens before/on checkout
✅ User is navigated to login after successful check-out
✅ Error handling is graceful on all platforms
✅ No crashes when secondary display is not available
✅ Code is maintainable and platform-agnostic where possible
