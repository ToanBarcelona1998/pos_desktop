import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform detection helper
class PlatformHelper {
  /// Check if running on desktop (Windows, macOS, Linux)
  static bool get isDesktop => 
    !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  
  /// Check if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  
  /// Check if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  
  /// Check if running on mobile (Android or iOS)
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  
  /// Check if running on Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  
  /// Check if running on macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  
  /// Check if running on Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;
}
