import 'package:flutter/material.dart';

import 'base_dialog_widget.dart';

sealed class DialogProvider {
  static Future<T?> showCustomDialog<T>(
    BuildContext context, {
    required Widget child,
  }) {
    return showDialog<T>(
      context: context,
      builder: (BuildContext context) {
        return child;
      },
    );
  }

  static Future<T?> showAppDialog<T>(
    BuildContext context, {
    Widget? titleWidget,
    String? titleText,
    Widget? subtitleWidget,
    String? subtitleText,
    Widget? messageWidget,
    String? messageText,
    required List<BaseDialogAction> actions,
    double width = 400.0,
    bool barrierDismissible = true,
  }) async {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return BaseDialogWidget(
          titleWidget: titleWidget,
          titleText: titleText,
          subtitleWidget: subtitleWidget,
          subtitleText: subtitleText,
          messageWidget: messageWidget,
          messageText: messageText,
          actions: actions,
          width: width,
        );
      },
    );
  }

  static Future<void> showInfoDialog(
    BuildContext context, {
    String? title,
    required String message,
  }) {
    return showAppDialog(
      context,
      titleText: title ?? 'Thông báo',
      messageText: message,
      actions: [
        BaseDialogAction(
          text: 'Đóng',
          isPrimary: true,
          color: Colors.blueAccent,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    String? title,
    required String message,
    String confirmText = 'Xác nhận',
    String cancelText = 'Hủy bỏ',
    Color? confirmColor,
    VoidCallback? onCancel,
    required VoidCallback onConfirm,
    bool barrierDismissible = true,
  }) async {
    return showAppDialog<bool>(
      context,
      titleText: title ?? 'Xác nhận hành động',
      messageText: message,
      barrierDismissible: barrierDismissible,
      actions: [
        BaseDialogAction(
          text: cancelText,
          isPrimary: false,
          color: Colors.grey,
          onPressed: () {
            Navigator.pop(context);
            onCancel?.call();
          },
        ),
        BaseDialogAction(
          text: confirmText,
          isPrimary: true,
          color: confirmColor ?? Colors.red,
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
        ),
      ],
    );
  }

  /// Show a loading dialog with a message
  static Future<void> showLoadingDialog(
    BuildContext context, {
    required String message,
    bool barrierDismissible = false,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
