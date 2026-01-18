# Root Cause Analysis: Logout và Xóa Database Sau Khi Login

## Vấn đề

Sau khi user login thành công qua webview, database bị xóa và logout được gọi, dẫn đến check-in fail với lỗi "User database not initialized".

## Log Sequence

```
1. User login qua webview → authCompleted được gọi
2. Database được init thành công
3. onChange -- AuthCubit, Change { currentState: Instance of 'Authenticated', nextState: Instance of 'AuthLoading' }
4. [INFO] 🔄 [UserDatabaseHelper] Deleting user database for userId: 7
5. onChange -- AuthCubit, Change { currentState: Instance of 'AuthLoading', nextState: Instance of 'Unauthenticated' }
6. [ERROR] Check-in failed, saving to local
```

## Root Cause

### 1. **Race Condition giữa `onLoadStop` và `authCompleted` handler**

**Flow hiện tại:**
```
1. Webview login thành công → Server redirect về /login page (hoặc /pos/create)
2. onLoadStop được gọi với URL chứa '/login'
3. Code detect URL chứa '/login' → Check authCubit.isAuthenticated
4. Nếu authenticated → Trigger logout → Xóa database
```

**Vấn đề:**
- Sau khi login thành công, server có thể redirect về `/login` page (có thể do logout redirect từ checkout)
- `onLoadStop` được gọi với URL `/login`
- Lúc này `authCubit.isAuthenticated` có thể là `true` (nếu `loginFromWebView` đã hoàn thành)
- Code detect URL `/login` + user authenticated → Trigger logout → Xóa database

### 2. **Timing Issue**

**Sequence of Events:**
```
T0: authCompleted handler được gọi từ webview
T1: Set _isLoggingIn = true
T2: Dispatch PosOnlineAuthCompleted event
T3: PosOnlineBloc._onAuthCompleted → gọi _authCubit.loginFromWebView()
T4: loginFromWebView emit AuthLoading
T5: Webview redirect về /login (server redirect)
T6: onLoadStop được gọi với URL /login
T7: Check authCubit.isAuthenticated (có thể vẫn false hoặc true)
T8: Check _isLoggingIn flag (có thể chưa được set nếu T6 xảy ra trước T1)
T9: Nếu authenticated và !_isLoggingIn → Logout → Xóa database
```

**Race Condition:**
- `onLoadStop` có thể được gọi TRƯỚC khi `authCompleted` handler set flag `_isLoggingIn = true`
- Hoặc `onLoadStop` được gọi SAU khi `loginFromWebView` emit `Authenticated` nhưng flag chưa được reset

### 3. **Logic Flaw trong `onLoadStop`**

**Code cũ:**
```dart
if (urlString.contains('/login')) {
  if (authCubit.isAuthenticated && !_isLoggingIn) {
    // Logout
  }
}
```

**Vấn đề:**
- Chỉ check `isAuthenticated` và `_isLoggingIn` flag
- Không check `AuthCubit` state (`AuthLoading`)
- Nếu `loginFromWebView` đang chạy async, state có thể là `AuthLoading` nhưng flag chưa được set

## Solution

### Fix 1: Check `AuthCubit` State

Thay vì chỉ dựa vào flag `_isLoggingIn`, check trực tiếp `AuthCubit` state:

```dart
if (urlString.contains('/login')) {
  final authCubit = context.read<AuthCubit>();
  final authState = authCubit.state;
  
  // Don't logout if:
  // 1. AuthCubit is in AuthLoading state (loginFromWebView in progress)
  // 2. Flag _isLoggingIn is true (authCompleted handler was called)
  // 3. User is not authenticated (no need to logout)
  final isLoginInProgress = authState is AuthLoading || _isLoggingIn;
  final isAuthenticated = authCubit.isAuthenticated;
  
  // Only logout if user is authenticated AND login is NOT in progress
  if (isAuthenticated && !isLoginInProgress) {
    // Logout
  }
}
```

### Fix 2: Set Flag Sớm Hơn

Set flag `_isLoggingIn = true` ngay khi `authCompleted` handler được gọi, TRƯỚC khi dispatch event:

```dart
controller.addJavaScriptHandler(
  handlerName: 'authCompleted',
  callback: (args) async {
    try {
      // Set flag IMMEDIATELY to prevent race condition
      _isLoggingIn = true;
      
      // ... rest of login logic
      
      // Reset flag after delay
      Future.delayed(const Duration(seconds: 2), () {
        _isLoggingIn = false;
      });
    } catch (e) {
      _isLoggingIn = false;
    }
  },
);
```

### Fix 3: Better URL Detection

Thay vì chỉ check `urlString.contains('/login')`, có thể check thêm:
- URL có phải là redirect từ server sau login không?
- Có query params đặc biệt không?
- Có referrer header không?

Nhưng fix này phức tạp hơn và có thể không cần thiết nếu Fix 1 và 2 đã đủ.

## Implementation

Đã implement Fix 1 và Fix 2 trong `pos_online_page.dart`:

1. ✅ Check `AuthCubit` state (`AuthLoading`) thay vì chỉ dựa vào flag
2. ✅ Set flag `_isLoggingIn = true` ngay khi `authCompleted` handler được gọi
3. ✅ Reset flag sau delay để đảm bảo login flow hoàn tất
4. ✅ Thêm logging để debug

## Testing

Để test fix này:

1. Login qua webview
2. Verify database không bị xóa
3. Verify check-in hoạt động bình thường
4. Verify logout vẫn hoạt động khi user thực sự navigate đến `/login` page

## Prevention

Để tránh vấn đề tương tự trong tương lai:

1. **Always check state, not just flags**: Check `AuthCubit` state thay vì chỉ dựa vào local flags
2. **Set flags early**: Set flags ngay khi event handler được gọi, không chờ async operations
3. **Add logging**: Log state changes để debug race conditions
4. **Consider using BlocListener**: Listen to `AuthCubit` state changes thay vì check trong `onLoadStop`
