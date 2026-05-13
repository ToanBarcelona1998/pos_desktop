import 'dart:convert';
import 'dart:ui';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'platform_helper.dart';
import 'window_manager_abstract.dart';
import 'window_manager_desktop.dart';
import 'window_manager_android.dart';

extension WindowControllerExtension on WindowController {
  Future<void> customMethods() async {
    return await setWindowMethodHandler((call) async {
      switch (call.method) {
        case 'window_center':
          return await windowManager.center();
        case 'window_close':
          return await windowManager.close();
        case 'focus':
          return await windowManager.focus();
        case 'show':
          return await windowManager.show();
        default:
          return;
      }
    });
  }

  Future<void> center() {
    return invokeMethod('window_center');
  }

  Future<void> focus() {
    return invokeMethod('focus');
  }

  Future<void> close() {
    return invokeMethod('window_close');
  }

  Future<void> show() {
    return invokeMethod('show');
  }
}


final class WindowArguments {
  final WindowType type;
  final Map<String, dynamic> params;

  const WindowArguments({
    required this.type,
    required this.params,
  });

  factory WindowArguments.main() {
    return WindowArguments(
      type: WindowType.none,
      params: {},
    );
  }

  factory WindowArguments.fromJson(Map<String, dynamic> json) {
    return WindowArguments(
      type: WindowType.fromName(json['type']),
      params: json['params'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.type,
      'params': params,
    };
  }
}

sealed class WindowManagerUtils {
  static Size? previousSize;
  static Offset? previousPosition;

  /// Get platform-specific window manager
  static WindowManagerAbstract getWindowManager() {
    if (PlatformHelper.isDesktop) {
      return WindowManagerDesktop();
    } else if (PlatformHelper.isAndroid) {
      return WindowManagerAndroid();
    } else {
      throw UnsupportedError('Platform not supported for multi-window');
    }
  }

  static void openFullScreen() async {
    // Only support fullscreen on desktop
    if (!PlatformHelper.isDesktop) {
      return;
    }
    
    bool isFullScreen = await windowManager.isFullScreen();
    if (isFullScreen) {
      await windowManager.setFullScreen(false);
      if (previousSize != null) {
        await windowManager.setSize(previousSize!);
      }
      if (previousPosition != null) {
        await windowManager.setPosition(previousPosition!);
      }
    } else {
      previousSize = await windowManager.getSize();
      previousPosition = await windowManager.getPosition();
      await windowManager.setFullScreen(true);
    }
  }

  static WindowArguments parseWindowArguments(String argument) {
    try {
      final Map<String, dynamic> json = jsonDecode(argument);

      return WindowArguments.fromJson(json);
    } catch (e) {
      return WindowArguments.main();
    }
  }

  static Future<WindowController> createNewWindow(WindowArguments arguments) async{
    final controller = await WindowController.create(
      WindowConfiguration(
        arguments: jsonEncode(
          arguments.toJson(),
        ),
        hiddenAtLaunch: false,
      ),
    );

    return controller;
  }
}
