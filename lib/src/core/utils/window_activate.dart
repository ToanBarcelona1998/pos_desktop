import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:win32/win32.dart';

class WindowsWebViewFocusManager with WidgetsBindingObserver {

  void init() {
    WidgetsBinding.instance.addObserver(this);
    _activateOnStartup();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  // ===== 1️⃣ Activate khi app start =====
  void _activateOnStartup() {
    Future.delayed(const Duration(milliseconds: 150), () {
      _ensureForeground();
    });
  }

  // ===== 2️⃣ Chỉ đảm bảo foreground =====
  void _ensureForeground() {
    final hwnd = GetActiveWindow();
    if (hwnd != 0) {
      SetForegroundWindow(hwnd);
    }
  }

  // ===== 3️⃣ Lifecycle guard =====
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _reactivateIfInternal();
    }
  }

  void _reactivateIfInternal() {
    final foreground = GetForegroundWindow();
    if (foreground == 0) return;

    final pidPtr = calloc<Uint32>();
    GetWindowThreadProcessId(foreground, pidPtr);

    final currentPid = GetCurrentProcessId();
    final sameProcess = pidPtr.value == currentPid;

    calloc.free(pidPtr);

    if (sameProcess) {
      Future.microtask(_ensureForeground);
    }
  }

  // ===== 4️⃣ Dùng cho Pointer interception =====
  void onPointerDown() {
    _ensureForeground();
  }
}