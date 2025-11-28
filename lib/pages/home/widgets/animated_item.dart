import 'package:flutter/material.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/home/widgets/item_widget.dart';

class AnimatedItem extends StatefulWidget {
  const AnimatedItem({super.key, required this.item, required this.index});

  final ({String name, IconData icon, VoidCallback? onTap}) item;
  final int index;

  @override
  State<AnimatedItem> createState() => _AnimatedItemState();
}

class _AnimatedItemState extends State<AnimatedItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    final direction = widget.index.isEven ? 1.0 : -1.0;
    _offsetAnimation = Tween<Offset>(begin: Offset(direction, 0.0), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: ItemWidget(
        name: AppLocalizations.of(context).translate(widget.item.name),
        icon: widget.item.icon,
        onTap: widget.item.onTap,
      ),
    );
  }
}