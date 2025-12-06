import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Custom toast manager for showing success and error messages
/// Uses fluttertoast package for mobile/web, ScaffoldMessenger for desktop
class ToastManager {
  /// Check if we're on a desktop platform
  static bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  /// Show a toast message
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool isError = false,
  }) {
    if (_isDesktop) {
      // Use ScaffoldMessenger for desktop platforms
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red[600] : Colors.green[600],
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      // Use fluttertoast for mobile and web
      try {
        Fluttertoast.showToast(
          msg: message,
          toastLength: duration.inSeconds > 3 ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: duration.inSeconds,
          backgroundColor: isError ? Colors.red[600] : Colors.green[600],
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } catch (e) {
        // Fallback to ScaffoldMessenger if fluttertoast fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.red[600] : Colors.green[600],
            duration: duration,
          ),
        );
      }
    }
  }

  /// Show success toast
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message, duration: duration, isError: false);
  }

  /// Show error toast
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message, duration: duration, isError: true);
  }
}

