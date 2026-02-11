import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

const WM_POINTERACTIVATE = 0x024B;
const WM_MOUSEACTIVATE = 0x0021;
const WM_NCACTIVATE = 0x0086;

const PA_ACTIVATE = 1;
const MA_ACTIVATE = 1;

class WindowsTouchWebViewFix {
  static int _oldProcAddress = 0;

  static int _customWndProc(
      int hwnd,
      int msg,
      int wParam,
      int lParam,
      ) {

    switch (msg) {
      case WM_POINTERACTIVATE:
        return PA_ACTIVATE;

      case WM_MOUSEACTIVATE:
        return MA_ACTIVATE;

      case WM_NCACTIVATE:
        return 1;
    }

    if (_oldProcAddress != 0) {
      return CallWindowProc(
        Pointer.fromAddress(_oldProcAddress),
        hwnd,
        msg,
        wParam,
        lParam,
      );
    }

    // fallback an toàn
    return DefWindowProc(hwnd, msg, wParam, lParam);
  }

  static void install() {
    final hwnd = GetActiveWindow();
    if (hwnd == 0) return;

    final newProc = Pointer.fromFunction<WNDPROC>(
      _customWndProc,
      0,
    );

    // LƯU OLD PROC TRƯỚC
    final old = GetWindowLongPtr(hwnd, GWLP_WNDPROC);

    _oldProcAddress = old;

    // Sau đó mới set
    SetWindowLongPtr(
      hwnd,
      GWLP_WNDPROC,
      newProc.address,
    );
  }
}