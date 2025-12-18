import 'dart:convert';
import 'dart:ui';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

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
}

enum WindowType {
  none('none'),
  onlineCustomer('onlineCustomer'),
  offlineCustomer('offlineCustomer');

  final String type;

  const WindowType(this.type);

  static WindowType fromName(String type) {
    return WindowType.values.firstWhere(
      (e) => type.toLowerCase() == e.type.toLowerCase(),
      orElse: () => WindowType.none,
    );
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

  static void openFullScreen() async {
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
