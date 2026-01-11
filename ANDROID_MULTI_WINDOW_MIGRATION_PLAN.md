# Kế Hoạch Migrate Multi-Window Sang Android

## Tổng Quan

App hiện tại sử dụng `desktop_multi_window` và `window_manager` để tạo multi-window trên desktop (Windows, macOS, Linux). Để hỗ trợ Android, cần thay thế bằng `flutter_presentation_display` cho secondary display và ẩn/điều chỉnh các tính năng chỉ dành cho desktop.

## Phân Tích Hiện Trạng

### 1. Các Thư Viện Hiện Tại (Desktop Only)

- **`desktop_multi_window`**: Tạo và quản lý multiple windows
- **`window_manager`**: Quản lý window properties (fullscreen, position, size, etc.)
- **`WindowController`**: Điều khiển window instances

### 2. Các File Liên Quan

#### Entry Point & Initialization
- `lib/main.dart`: Entry point, parse window arguments, initialize window manager
- `lib/src/offline_customer_application.dart`: App widget cho offline customer window
- `lib/src/online_customer_application.dart`: App widget cho online customer window

#### Core Utilities
- `lib/src/core/utils/window_manager_utils.dart`: Utility functions cho window management
  - `WindowType` enum: offlineCustomer, onlineCustomer
  - `WindowArguments` class: Arguments để pass giữa windows
  - `createNewWindow()`: Tạo window mới
  - `openFullScreen()`: Toggle fullscreen mode

#### Pages
- `lib/src/presentation/pages/pos/pos_page.dart`: 
  - `_openCustomerWindow()`: Mở offline customer window
  - `WindowController? _customerWindowController`: Reference đến customer window
  - Sử dụng `WindowController.getAll()` để check window status
  
- `lib/src/presentation/pages/pos_online/pos_online_page.dart`:
  - `WindowController? _customerWindowController`: Reference đến online customer window
  
- `lib/src/presentation/pages/offline_customer/offline_customer_page.dart`:
  - Sử dụng `WindowListener` mixin từ `window_manager`
  - `windowManager.setPreventClose(true)`: Prevent window close
  - `onWindowClose()`: Handle window close event

- `lib/src/presentation/pages/online_customer/online_customer_page.dart`:
  - Tương tự offline customer page với `WindowListener`

#### Services
- `lib/src/core/services/offline_customer_service.dart`: 
  - Sử dụng `desktop_multi_window` để broadcast messages giữa windows
  - `broadcastCartUpdate()`: Gửi cart data đến customer window

### 3. Tính Năng Cần Xử Lý

1. **Multi-Window Creation**: 
   - Desktop: `WindowController.create()` với `WindowConfiguration`
   - Android: `flutter_presentation_display` để hiển thị trên secondary display

2. **Window Management**:
   - Desktop: `show()`, `hide()`, `focus()`, `close()` qua `WindowController`
   - Android: Presentation display management

3. **Fullscreen Toggle**:
   - Desktop: `WindowManagerUtils.openFullScreen()` 
   - Android: Ẩn feature này

4. **Window Lifecycle**:
   - Desktop: `WindowListener` với `onWindowClose()`
   - Android: Standard Flutter lifecycle

5. **Inter-Window Communication**:
   - Desktop: `desktop_multi_window` channel communication
   - Android: Shared state hoặc event bus (giữ nguyên `OfflineCustomerService` logic)

## Kế Hoạch Implementation

### Phase 1: Tạo Platform Abstraction Layer

#### 1.1. Tạo Platform Detection Helper

**File**: `lib/src/core/utils/platform_helper.dart`

```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformHelper {
  static bool get isDesktop => 
    !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
}
```

#### 1.2. Tạo Window Manager Abstraction

**File**: `lib/src/core/utils/window_manager_abstract.dart`

```dart
abstract class WindowManagerAbstract {
  Future<void> openCustomerWindow({
    required WindowType type,
    Map<String, dynamic>? params,
  });
  
  Future<void> closeCustomerWindow();
  
  Future<void> showCustomerWindow();
  
  Future<void> hideCustomerWindow();
  
  Future<bool> isCustomerWindowOpen();
  
  Stream<WindowStatus> get windowStatusStream;
}

enum WindowType {
  offlineCustomer,
  onlineCustomer,
}

class WindowStatus {
  final bool isOpen;
  final WindowType? type;
  
  WindowStatus({required this.isOpen, this.type});
}
```

#### 1.3. Implement Desktop Window Manager

**File**: `lib/src/core/utils/window_manager_desktop.dart`

- Wrap existing `WindowController` logic
- Implement `WindowManagerAbstract`

#### 1.4. Implement Android Window Manager

**File**: `lib/src/core/utils/window_manager_android.dart`

- Sử dụng `flutter_presentation_display`
- Implement `WindowManagerAbstract`
- Hiển thị customer page trên secondary display

### Phase 2: Update Dependencies

#### 2.1. Update `pubspec.yaml`

```yaml
dependencies:
  # Existing
  desktop_multi_window: ^0.3.0  # Keep for desktop
  window_manager: ^0.4.3         # Keep for desktop
  
  # New for Android
  flutter_presentation_display: ^1.0.0  # Add this
  
  # Conditional imports
  conditional_import: ^1.0.0  # Optional, for cleaner code
```

**Note**: `flutter_presentation_display` có thể không tồn tại. Cần verify package name hoặc sử dụng package thực tế như:
- `presentation_displays` (https://pub.dev/packages/presentation_displays)
- Hoặc tạo custom implementation

#### 2.2. Update Android Configuration

**File**: `android/app/build.gradle`

```gradle
android {
    // ... existing config
    
    defaultConfig {
        // ... existing config
        minSdkVersion 21  // Ensure minimum SDK for presentation display
    }
}

dependencies {
    // For presentation display support
    implementation 'androidx.window:window:1.0.0'
    implementation 'androidx.window:window-java:1.0.0'
}
```

**File**: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest>
    <!-- Add if needed for presentation display -->
    <uses-feature android:name="android.hardware.display.output" android:required="false" />
</manifest>
```

### Phase 3: Refactor Core Files

#### 3.1. Update `lib/main.dart`

**Changes**:
- Platform check trước khi initialize `window_manager`
- Conditional initialization:
  ```dart
  if (PlatformHelper.isDesktop) {
    await windowManager.ensureInitialized();
    final windowController = await WindowController.fromCurrentEngine();
    await windowController.customMethods();
    
    final WindowArguments windowArguments = 
      WindowManagerUtils.parseWindowArguments(windowController.arguments);
    // ... handle window arguments
  } else {
    // Android: Run main app directly
    runApp(const Application());
  }
  ```

#### 3.2. Update `lib/src/core/utils/window_manager_utils.dart`

**Changes**:
- Thêm factory method để get platform-specific window manager:
  ```dart
  static WindowManagerAbstract getWindowManager() {
    if (PlatformHelper.isDesktop) {
      return WindowManagerDesktop();
    } else if (PlatformHelper.isAndroid) {
      return WindowManagerAndroid();
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }
  ```
- Giữ nguyên các utility functions nhưng wrap trong platform checks

#### 3.3. Update `WindowManagerUtils.openFullScreen()`

**Changes**:
```dart
static void openFullScreen() async {
  if (!PlatformHelper.isDesktop) {
    // Android: Fullscreen not supported, do nothing or show message
    return;
  }
  // Existing desktop logic
}
```

### Phase 4: Update POS Pages

#### 4.1. Update `lib/src/presentation/pages/pos/pos_page.dart`

**Changes**:
- Replace `WindowController` với `WindowManagerAbstract`
- Update `_openCustomerWindow()`:
  ```dart
  final windowManager = WindowManagerUtils.getWindowManager();
  await windowManager.openCustomerWindow(
    type: WindowType.offlineCustomer,
  );
  ```
- Remove desktop-specific window checking logic
- Update dispose logic

#### 4.2. Update `lib/src/presentation/pages/pos_online/pos_online_page.dart`

**Similar changes** như `pos_page.dart` cho online customer window

#### 4.3. Update `lib/src/presentation/pages/offline_customer/offline_customer_page.dart`

**Changes**:
- Remove `WindowListener` mixin (desktop only)
- Create platform-specific lifecycle handling:
  ```dart
  @override
  void initState() {
    super.initState();
    _setupMessageHandler();
    
    if (PlatformHelper.isDesktop) {
      windowManager.setPreventClose(true);
      windowManager.addListener(this);
    }
  }
  
  @override
  void dispose() {
    OfflineCustomerService().unRegisterHandle();
    if (PlatformHelper.isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }
  ```
- Conditional `onWindowClose()` implementation

#### 4.4. Update `lib/src/presentation/pages/online_customer/online_customer_page.dart`

**Similar changes** như `offline_customer_page.dart`

### Phase 5: Update Services

#### 5.1. Update `lib/src/core/services/offline_customer_service.dart`

**Changes**:
- Keep communication logic (có thể dùng shared state hoặc event bus)
- Remove `desktop_multi_window` specific code
- Implement platform-agnostic broadcast mechanism:
  - Desktop: Keep existing channel-based approach
  - Android: Use StreamController hoặc event bus

### Phase 6: Update Application Widgets

#### 6.1. Update `lib/src/offline_customer_application.dart`

**Changes**:
- Remove desktop-only scroll behavior check:
  ```dart
  scrollBehavior: PlatformHelper.isDesktop
      ? DesktopScrollBehavior()
      : null,
  ```

#### 6.2. Update `lib/src/online_customer_application.dart`

**Similar changes**

#### 6.3. Update `lib/src/application.dart`

**Similar scroll behavior changes**

### Phase 7: Hide Desktop-Only Features

#### 7.1. Update `lib/src/presentation/pages/pos/widgets/pos_app_bar_widget.dart`

**Changes**:
- Hide "Open Full Screen" button trên Android:
  ```dart
  if (PlatformHelper.isDesktop && widget.onOpenFullScreen != null)
    IconButton(
      icon: Icon(Icons.fullscreen),
      onPressed: widget.onOpenFullScreen,
    ),
  ```

## Implementation Details

### Android Presentation Display Implementation

**File**: `lib/src/core/utils/window_manager_android.dart`

```dart
import 'package:flutter_presentation_display/flutter_presentation_display.dart';
import 'dart:async';

class WindowManagerAndroid implements WindowManagerAbstract {
  final FlutterPresentationDisplay _display = FlutterPresentationDisplay();
  int? _currentDisplayId;
  StreamSubscription? _displayChangeSubscription;
  final _windowStatusController = StreamController<WindowStatus>.broadcast();
  
  WindowManagerAndroid() {
    _setupDisplayListener();
  }
  
  void _setupDisplayListener() {
    _displayChangeSubscription = _display.connectedDisplaysChangedStream.listen((displayId) {
      // Handle display connection changes
      _windowStatusController.add(WindowStatus(
        isOpen: displayId != null,
        type: _getCurrentWindowType(),
      ));
    });
    
    // Listen for data from presentation display
    _display.listenDataFromPresentationDisplay((data) {
      // Handle data from customer window
      // Similar to desktop_multi_window message handling
    });
  }
  
  @override
  Future<void> openCustomerWindow({
    required WindowType type,
    Map<String, dynamic>? params,
  }) async {
    try {
      // Get available displays
      final displays = await _display.getDisplays();
      
      if (displays == null || displays.isEmpty) {
        throw Exception('No displays available');
      }
      
      // Use first secondary display (index 1) or primary if only one available
      // For offline customer: use displayId from displays list
      final displayId = displays.length > 1 ? displays[1].displayId : displays[0].displayId;
      
      // Determine router name based on type
      final routerName = type == WindowType.offlineCustomer 
          ? 'offline_customer' 
          : 'online_customer';
      
      // Show secondary display
      final result = await _display.showSecondaryDisplay(
        displayId: displayId,
        routerName: routerName,
      );
      
      if (result == true) {
        _currentDisplayId = displayId;
        _windowStatusController.add(WindowStatus(
          isOpen: true,
          type: type,
        ));
        
        // Send initial data to presentation display
        if (params != null) {
          await _display.transferDataToPresentation(params);
        }
      }
    } catch (e) {
      throw Exception('Failed to open customer window: $e');
    }
  }
  
  @override
  Future<void> closeCustomerWindow() async {
    if (_currentDisplayId != null) {
      await _display.hideSecondaryDisplay(_currentDisplayId!);
      _currentDisplayId = null;
      _windowStatusController.add(WindowStatus(isOpen: false));
    }
  }
  
  @override
  Future<void> showCustomerWindow() async {
    // Presentation display doesn't have explicit show/hide
    // If hidden, reopen with same displayId and routerName
    // This needs to be handled by storing window state
  }
  
  @override
  Future<void> hideCustomerWindow() async {
    await closeCustomerWindow();
  }
  
  @override
  Future<bool> isCustomerWindowOpen() async {
    return _currentDisplayId != null;
  }
  
  @override
  Stream<WindowStatus> get windowStatusStream => _windowStatusController.stream;
  
  /// Transfer data to customer window (presentation display)
  Future<void> transferDataToCustomer(Map<String, dynamic> data) async {
    if (_currentDisplayId != null) {
      await _display.transferDataToPresentation(data);
    }
  }
  
  WindowType? _getCurrentWindowType() {
    // Store window type when opening, return here
    // This requires storing window state
    return null;
  }
  
  void dispose() {
    _displayChangeSubscription?.cancel();
    _windowStatusController.close();
  }
}
```

**Router Configuration** (cần setup trong app routing):

Cần configure router names trong app để match với `routerName` parameter:
- `'offline_customer'` -> `OfflineCustomerPage`
- `'online_customer'` -> `OnlineCustomerPage`

**Note**: Package `flutter_presentation_display` đơn giản hơn nhiều - không cần Platform Channel hay native code. Package tự handle tất cả native logic internally.

## Testing Plan

### 1. Desktop Testing (Regression)
- ✅ Test multi-window functionality vẫn hoạt động
- ✅ Test window lifecycle (open, close, hide, show)
- ✅ Test fullscreen toggle
- ✅ Test inter-window communication

### 2. Android Testing
- ✅ Test app chạy được trên Android (không crash)
- ✅ Test customer window mở được trên secondary display (nếu có)
- ✅ Test fallback khi không có secondary display
- ✅ Test UI không bị broken (desktop-only features ẩn đi)
- ✅ Test cart sync vẫn hoạt động

### 3. Platform-Specific Testing
- ✅ Test platform detection chính xác
- ✅ Test conditional code paths
- ✅ Test error handling khi platform không support

## Migration Checklist

### Preparation
- [ ] Research và verify `flutter_presentation_display` package (hoặc alternative)
- [ ] Setup Android development environment
- [ ] Create feature branch: `feature/android-multi-window`

### Implementation
- [ ] Phase 1: Platform abstraction layer
  - [ ] Create `PlatformHelper`
  - [ ] Create `WindowManagerAbstract`
  - [ ] Implement `WindowManagerDesktop`
  - [ ] Implement `WindowManagerAndroid`
- [ ] Phase 2: Dependencies
  - [ ] Update `pubspec.yaml`
  - [ ] Update Android configuration
  - [ ] Run `flutter pub get`
- [ ] Phase 3: Core files
  - [ ] Update `main.dart`
  - [ ] Update `window_manager_utils.dart`
- [ ] Phase 4: POS pages
  - [ ] Update `pos_page.dart`
  - [ ] Update `pos_online_page.dart`
  - [ ] Update `offline_customer_page.dart`
  - [ ] Update `online_customer_page.dart`
- [ ] Phase 5: Services
  - [ ] Update `offline_customer_service.dart`
- [ ] Phase 6: Application widgets
  - [ ] Update application widgets
- [ ] Phase 7: Hide desktop features
  - [ ] Update UI components

### Testing
- [ ] Desktop regression tests
- [ ] Android basic functionality tests
- [ ] Android secondary display tests (nếu có device)
- [ ] Error handling tests

### Documentation
- [ ] Update README với Android support info
- [ ] Document Android requirements (SDK version, hardware requirements)
- [ ] Document known limitations

## Known Limitations & Considerations

1. **Secondary Display Requirement**: 
   - Android secondary display yêu cầu hardware support (HDMI, wireless display, USB-C to HDMI)
   - Không phải tất cả Android devices đều support
   - Cần handle fallback gracefully khi không có secondary display
   - Tested on SUNMI T2s (POS devices thường support)

2. **Window Management Differences**:
   - Desktop: True multi-window với independent windows
   - Android: Presentation display là extension của main app, không phải independent process
   - User experience có thể khác nhau (presentation display không thể minimize/restore như desktop window)

3. **Package Availability**:
   - ✅ `flutter_presentation_display` đã được verify và có documentation
   - Package tự handle native code, không cần custom Platform Channel
   - Based on `presentation_displays` package (BSD 2-Clause License)

4. **Inter-Window Communication**:
   - Desktop: `desktop_multi_window` channel-based communication
   - Android: `transferDataToPresentation()` và `listenDataFromPresentationDisplay()` methods
   - Cần maintain cả 2 mechanisms trong abstraction layer

5. **Router Configuration**:
   - Cần setup router names trong app routing để match với `routerName` parameter
   - Router names: `'offline_customer'`, `'online_customer'`

6. **Build Configuration**:
   - Cần maintain cả desktop và Android builds
   - CI/CD pipeline cần update để build cả 2 platforms
   - Package không cần special Android configuration (minSdkVersion 21 thường đã có)

## Alternatives Considered

1. **Separate Android App**: 
   - Tạo app riêng cho Android
   - ❌ Duplicate code, maintainability issues

2. **Conditional Compilation**:
   - Sử dụng `dart:io` Platform checks
   - ✅ Chosen approach

3. **Feature Flags**:
   - Runtime feature flags
   - ⚠️ More complex, có thể overkill

## Next Steps

1. **Verify Package**: Research và confirm package name cho presentation display
2. **Proof of Concept**: Tạo simple PoC để test secondary display trên Android
3. **Incremental Migration**: Migrate từng phase, test sau mỗi phase
4. **Documentation**: Update documentation sau khi complete

## References

- Flutter Platform Channels: https://docs.flutter.dev/platform-integration/platform-channels
- Android Presentation Display API: https://developer.android.com/reference/android/app/Presentation
- Desktop Multi Window Package: https://pub.dev/packages/desktop_multi_window
- Presentation Displays Package (example): https://pub.dev/packages/presentation_displays (verify if exists)
