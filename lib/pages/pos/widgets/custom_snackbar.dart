import 'package:flutter/material.dart';

enum SnackbarAnimationType { fade, slide }

class CustomSnackbarManager {
  static final List<_SnackbarData> _snackbars = [];
  static OverlayEntry? _overlayEntry;

  static void show(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
        SnackbarAnimationType animation = SnackbarAnimationType.slide,
        bool isError = false,
      }) {
    final overlay = Overlay.of(context);

    final data = _SnackbarData(
      id: UniqueKey(),
      message: message,
      animationType: animation,
      duration: duration,
      isError: isError,
    );

    _snackbars.add(data);
    _showOverlay(context, overlay);
  }


  static void _showOverlay(BuildContext context, OverlayState overlay) {
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: (_) {
        return Positioned(
          top: 40,
          right: 20,
          child: _SnackbarColumn(
            onRemove: _removeSnackbar,
          ),
        );
      });
      overlay.insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  static void _removeSnackbar(Key id) {
    _snackbars.removeWhere((s) => s.id == id);
    if (_snackbars.isEmpty) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    } else {
      _overlayEntry?.markNeedsBuild();
    }
  }

  static List<_SnackbarData> get snackbars => List.unmodifiable(_snackbars);
}

class _SnackbarData {
  final Key id;
  final String message;
  final SnackbarAnimationType animationType;
  final Duration duration;
  final bool isError;

  _SnackbarData({
    required this.id,
    required this.message,
    required this.animationType,
    required this.duration,
    this.isError = false,
  });
}

class _SnackbarColumn extends StatefulWidget {
  final void Function(Key id) onRemove;
  const _SnackbarColumn({required this.onRemove,});

  @override
  State<_SnackbarColumn> createState() => _SnackbarColumnState();
}

class _SnackbarColumnState extends State<_SnackbarColumn> {
  @override
  Widget build(BuildContext context) {
    final snackbars = CustomSnackbarManager.snackbars;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: snackbars.map((data) {
        return  _AnimatedSnackbar(
          key: data.id,
          message: data.message,
          animationType: data.animationType,
          duration: data.duration,
          isError: data.isError,
          onDismissed: () => widget.onRemove(data.id),
        );

      }).toList(),
    );
  }
}
class _AnimatedSnackbar extends StatefulWidget {
  final String message;
  final VoidCallback onDismissed;
  final SnackbarAnimationType animationType;
  final Duration duration;
  final bool isError;

  const _AnimatedSnackbar({
    super.key,
    required this.message,
    required this.onDismissed,
    required this.animationType,
    required this.duration,
    this.isError = false,
  });

  @override
  State<_AnimatedSnackbar> createState() => _AnimatedSnackbarState();
}

class _AnimatedSnackbarState extends State<_AnimatedSnackbar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _slide = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () async {
      if (mounted) {
        await _controller.reverse();
        if (mounted) widget.onDismissed();
      }

    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child = _SnackbarBody(
      message: widget.message,
      isError: widget.isError,
      onClose: () async {
        if (mounted) {
          await _controller.reverse();
          if (mounted) widget.onDismissed();
        }

      },
    );

    if (widget.animationType == SnackbarAnimationType.fade) {
      child = FadeTransition(opacity: _fade, child: child);
    } else {
      child = SlideTransition(position: _slide, child: child);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(color: Colors.transparent, child: child),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
class _SnackbarBody extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onClose;

  const _SnackbarBody({
    required this.message,
    required this.isError,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? Colors.red[600] : Colors.green[600],
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

