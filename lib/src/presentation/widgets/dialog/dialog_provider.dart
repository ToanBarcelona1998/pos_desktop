import 'package:flutter/material.dart';

import 'base_dialog_widget.dart';

sealed class DialogProvider {
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
  }) async {
    return showDialog<T>(
      context: context,
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
  }) async {
    return showAppDialog<bool>(
      context,
      titleText: title ?? 'Xác nhận hành động',
      messageText: message,
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
}
