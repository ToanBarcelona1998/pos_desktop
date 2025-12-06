import 'package:flutter/material.dart';
import '../app_button.dart';

class BaseDialogAction {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isPrimary;

  const BaseDialogAction({
    required this.text,
    this.onPressed,
    this.color,
    this.isPrimary = true,
  });
}

class BaseDialogWidget extends StatelessWidget {
  final Widget? titleWidget;
  final String? titleText;
  final Widget? subtitleWidget;
  final String? subtitleText;

  final Widget? messageWidget;
  final String? messageText;

  final List<BaseDialogAction>? actions;

  final double width;
  final BorderRadius borderRadius;

  const BaseDialogWidget({
    super.key,
    this.titleWidget,
    this.titleText,
    this.subtitleWidget,
    this.subtitleText,
    this.messageWidget,
    this.messageText,
    this.actions,
    this.width = 400.0,
    BorderRadius? borderRadius,
  })  : assert(titleWidget != null ||
            titleText != null ||
            (titleWidget == null && titleText == null)),
        assert(subtitleWidget != null ||
            subtitleText != null ||
            (subtitleWidget == null && subtitleText == null)),
        assert(messageWidget != null ||
            messageText != null ||
            (messageWidget == null && messageText == null)),
        this.borderRadius =
            borderRadius ?? const BorderRadius.all(Radius.circular(16));

  // Hàm xây dựng Widget cho Text/Title
  Widget _buildText(String? text, TextStyle style,
      {TextAlign align = TextAlign.center}) {
    if (text == null) return const SizedBox.shrink();
    return Text(
      text,
      textAlign: align,
      style: style,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ------------------ 1. TITLE ------------------
            if (titleWidget != null || titleText != null) ...[
              titleWidget ??
                  _buildText(
                    titleText,
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
              const SizedBox(height: 8),
            ],

            // ------------------ 2. SUBTITLE ------------------
            if (subtitleWidget != null || subtitleText != null) ...[
              subtitleWidget ??
                  _buildText(
                    subtitleText,
                    TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
              const SizedBox(height: 16),
            ],

            // ------------------ 3. MESSAGE (Content) ------------------
            if (messageWidget != null || messageText != null) ...[
              messageWidget ??
                  _buildText(
                    messageText,
                    const TextStyle(fontSize: 18),
                    align: TextAlign.left, // Nội dung thường căn trái
                  ),
              const SizedBox(height: 24),
            ],

            // ------------------ 4. ACTIONS (Buttons) ------------------
            if (actions != null && actions!.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!.map((action) {
                  final button = action.isPrimary
                      ? AppButton(
                          text: action.text,
                          onPressed: action.onPressed,
                          backgroundColor: action.color,
                          foregroundColor: Colors.white,
                        )
                      : AppTextButton(
                          text: action.text,
                          onPressed: action.onPressed,
                          color: action.color ?? Colors.blueAccent,
                        );

                  return Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: button,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
