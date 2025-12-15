import 'package:flutter/foundation.dart';

enum LogType { error, info, success, log }

sealed class Logger{
  static const _colors = {
    LogType.error: "\x1B[31m",
    LogType.info: "\x1B[33m",
    LogType.success: "\x1B[32m",
    LogType.log: "\x1B[34m",
  };

  static const String _reset = "\x1B[0m";

  static void _print(LogType type, String message, {String? tag}) {
    if (kDebugMode) {
      final time = DateTime.now().toIso8601String();
      final color = _colors[type] ?? "";
      final label = type.name.toUpperCase();
      final tagStr = tag != null ? "[$tag] " : "";
      print("$color[$label][$time] $tagStr$message$_reset");
    }
  }

  static void log(String message) => _print(LogType.log, message);

  static void logE(String message, [Object ? e ,String ? tag]) => _print(LogType.error, message, tag: tag);

  static void logI(String message, {String ? tag}) => _print(LogType.info, message, tag: tag);

}

