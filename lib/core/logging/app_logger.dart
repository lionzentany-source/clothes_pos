import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Rolling file + console logger (singleton style static API).
/// Features:
/// - Levels: DEBUG/INFO/WARN/ERROR
/// - Daily log file (logs/YYYY-MM-DD.log) with 7-day retention
/// - Buffered async writes (debounced 500ms)
/// - Safe no-op on web or if file system unavailable
class AppLogger {
  static Directory? _logDir;
  static DateTime? _currentFileDate;
  static IOSink? _sink;
  static final List<String> _buffer = [];
  static Timer? _flushTimer;
  static bool _initStarted = false;
  static const _retentionDays = 7;

  static Future<void> _init() async {
    if (_initStarted) return; // idempotent
    _initStarted = true;
    try {
      if (kIsWeb) return; // skip file logging on web
      final dir = await getApplicationSupportDirectory();
      _logDir = Directory('${dir.path}${Platform.pathSeparator}logs');
      if (!await _logDir!.exists()) await _logDir!.create(recursive: true);
      await _rotateIfNeeded();
      await _cleanup();
    } catch (_) {
      // swallow init errors
    }
  }

  static Future<void> _rotateIfNeeded() async {
    if (kIsWeb || _logDir == null) return;
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    if (_currentFileDate == dateOnly && _sink != null) return;
    await _sink?.flush();
    await _sink?.close();
    _currentFileDate = dateOnly;
    final file = File(
      '${_logDir!.path}${Platform.pathSeparator}'
      '${dateOnly.toIso8601String().substring(0, 10)}.log',
    );
    _sink = file.openWrite(mode: FileMode.append);
  }

  static Future<void> _cleanup() async {
    if (kIsWeb || _logDir == null) return;
    try {
      final cutoff = DateTime.now().subtract(
        const Duration(days: _retentionDays),
      );
      for (final e in _logDir!.listSync()) {
        if (e is File && e.path.endsWith('.log')) {
          final name = e.uri.pathSegments.last; // YYYY-MM-DD.log
          if (name.length >= 15) {
            final dateStr = name.substring(0, 10);
            try {
              final dt = DateTime.parse(dateStr);
              if (dt.isBefore(cutoff)) {
                await e.delete();
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  static void _enqueue(String line) {
    if (kIsWeb) return; // skip
    _buffer.add(line);
    _flushTimer ??= Timer(const Duration(milliseconds: 500), () async {
      final lines = List<String>.from(_buffer);
      _buffer.clear();
      _flushTimer = null;
      try {
        await _init();
        await _rotateIfNeeded();
        _sink?.writeAll(lines, '\n');
      } catch (_) {
        /* ignore */
      }
    });
  }

  static void d(String message, {Object? error, StackTrace? stackTrace}) =>
      _log('DEBUG', message, error, stackTrace);
  static void i(String message, {Object? error, StackTrace? stackTrace}) =>
      _log('INFO', message, error, stackTrace);
  static void w(String message, {Object? error, StackTrace? stackTrace}) =>
      _log('WARN', message, error, stackTrace);
  static void e(String message, {Object? error, StackTrace? stackTrace}) =>
      _log('ERROR', message, error, stackTrace);

  static void _log(
    String level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final ts = DateTime.now().toIso8601String();
    final sb = StringBuffer('[$ts][$level] $message');
    if (error != null) sb.write(' | error: $error');
    if (stackTrace != null) sb.write('\n$stackTrace');
    final line = sb.toString();
    debugPrint(line); // console
    developer.log(
      message,
      level: _toDeveloperLevel(level),
      error: error,
      stackTrace: stackTrace,
      name: 'ClothesPOS',
    );
    _enqueue(line);
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
