import 'dart:convert';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/core/di/locator.dart'; // Assuming sl is available here
import 'package:flutter/foundation.dart'; // Import for debugPrint

class UsageLogger {
  final DatabaseHelper _dbHelper = sl<DatabaseHelper>();

  Future<void> logEvent(String eventType, Map<String, dynamic> details) async {
    final db = await _dbHelper.database;
    try {
      await db.insert(
        'usage_logs',
        {
          'timestamp': DateTime.now().toIso8601String(),
          'event_type': eventType,
          'event_details': jsonEncode(details),
          // 'user_id': (await _authService.getCurrentUser())?.id, // Requires Auth Service
          // 'session_id': _sessionId, // Requires session management
        },
      );
    } catch (e) {
      // Log the error, but don't block the main thread or crash the app
      debugPrint('Error logging usage event: $e');
    }
  }

  // Optional: Method to retrieve logs for debugging/analysis
  Future<List<Map<String, dynamic>>> getUsageLogs() async {
    final db = await _dbHelper.database;
    return await db.query('usage_logs', orderBy: 'timestamp DESC');
  }

  // Optional: Method to clear old logs (e.g., after backup)
  Future<void> clearOldUsageLogs() async {
    final db = await _dbHelper.database;
    // Example: Delete logs older than 30 days
    await db.delete(
      'usage_logs',
      where: 'timestamp < ?',
      whereArgs: [DateTime.now().subtract(const Duration(days: 30)).toIso8601String()],
    );
  }
}