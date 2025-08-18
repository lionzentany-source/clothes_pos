import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Simple centralized logger. Currently routes to console; can be swapped later.
class AppLogger {
  static void d(String message, {Object? error, StackTrace? stackTrace}) {
    _log('DEBUG', message, error, stackTrace);
  }

  static void i(String message, {Object? error, StackTrace? stackTrace}) {
    _log('INFO', message, error, stackTrace);
  }

  static void w(String message, {Object? error, StackTrace? stackTrace}) {
    _log('WARN', message, error, stackTrace);
  }

  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, error, stackTrace);
  }

  static void _log(String level, String message, Object? error, StackTrace? stackTrace) {
    final full = StringBuffer('[$level] $message');
    if (error != null) full.write(' | error: $error');
    if (stackTrace != null) full.write('\n$stackTrace');

    // In debug, use debugPrint to avoid truncation; also use developer.log
    debugPrint(full.toString());
    developer.log(message, level: _toDeveloperLevel(level), error: error, stackTrace: stackTrace, name: 'ClothesPOS');
  }

  static int _toDeveloperLevel(String level) {
    switch (level) {
      case 'ERROR':
        return 1000;
      case 'WARN':
        return 900;
      case 'INFO':
        return 800;
      case 'DEBUG':
      default:
        return 500;
    }
  }
}

