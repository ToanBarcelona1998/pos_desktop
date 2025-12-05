import 'package:flutter/foundation.dart';

/// Logger class for application-wide logging
/// Only logs in debug mode
class Logger {
  /// Log warning message
  static void logW(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      if (error != null) {
        debugPrint('⚠️ [WARNING] $message');
        debugPrint('Error: $error');
        if (stackTrace != null) {
          debugPrint('StackTrace: $stackTrace');
        }
      } else {
        debugPrint('⚠️ [WARNING] $message');
      }
    }
  }

  /// Log info message
  static void logI(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ [INFO] $message');
    }
  }

  /// Log debug message
  static void logD(String message) {
    if (kDebugMode) {
      debugPrint('🔍 [DEBUG] $message');
    }
  }

  /// Log error message
  static void logE(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ [ERROR] $message');
      if (error != null) {
        debugPrint('Error: $error');
        if (stackTrace != null) {
          debugPrint('StackTrace: $stackTrace');
        }
      }
    }
  }
}

