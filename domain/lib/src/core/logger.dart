import 'package:flutter/foundation.dart';
import 'dart:developer' as dev;

sealed class Logger{
  static const String reset = '\x1B[0m';
  static const String red = '\x1B[31m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';

  static void log(String message) {
    if (kDebugMode) {
      dev.log('$red[LOG]: $message$reset');
    }
  }

  static void logE(String message, [Object ? e ,String ? tag]) {
    if (kDebugMode) {
      dev.log('$red[ERROR]-${tag ?? 'NO TAG'}: $message$reset', error: e);

    }
  }

  static void logI(String message, {String ? tag}) {
    if (kDebugMode) {
      dev.log('$yellow[INFO]-${tag ?? 'NO TAG'}: $message$reset');
    }
  }

}

