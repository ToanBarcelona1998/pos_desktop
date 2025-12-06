import 'dart:ui';

import 'package:window_manager/window_manager.dart';

sealed class WindowManagerUtils{
  static Size ? previousSize;
  static Offset ? previousPosition;

  static void openFullScreen() async{
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
}