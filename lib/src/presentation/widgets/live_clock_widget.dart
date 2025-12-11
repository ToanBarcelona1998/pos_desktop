import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:pos_final/src/core/constants/app_responsive.dart';

class LiveClockWidget extends StatefulWidget {
  const LiveClockWidget({super.key});

  @override
  State<LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<LiveClockWidget> {
  String _timeString = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(now);
    setState(() {
      _timeString = formattedTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rTypography = context.rTypography;
    
    return Text(
      _timeString,
      style: rTypography.labelMedium.copyWith(
        color: Colors.white
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}