import 'package:flutter/foundation.dart';

/// Simple logger utility for application-wide logging
class Logger {
  /// Log info message
  static void info(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Log error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('$message ${error ?? ""} ${stackTrace ?? ""}');
    }
  }

  /// Log debug message
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}
