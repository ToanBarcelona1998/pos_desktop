import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Custom toast manager for showing success and error messages
/// Uses fluttertoast package for displaying toasts
class ToastManager {
  /// Show a toast message
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool isError = false,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: duration.inSeconds > 3 ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: duration.inSeconds,
      backgroundColor: isError ? Colors.red[600] : Colors.green[600],
      textColor: Colors.white,
      fontSize: 16.0,
    );
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

