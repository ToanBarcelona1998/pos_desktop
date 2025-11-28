import 'package:flutter/material.dart';

class StyleColors{
  mainColor(double opacity){
    return const Color(0xFF6C63FF).withAlpha((opacity * 256).toInt());

  }

  secondColor(double opacity){
    return Colors.red.withAlpha((opacity * 256).toInt());
  }

  accentColor(double opacity){
    return Colors.white.withAlpha((opacity * 256).toInt());
  }
}