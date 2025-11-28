import 'package:flutter/material.dart';
import 'package:pos_final/helpers/app_theme.dart';

class GreetingWidget extends StatelessWidget {
  const GreetingWidget({super.key, required this.themeData, required this.userName});

  final ThemeData themeData;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome, $userName!', style: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.w700, color: themeData.colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text('Have a great day!', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: themeData.colorScheme.onSurface.withAlpha((0.6 * 256).toInt()))),
      ],
    );
  }
}