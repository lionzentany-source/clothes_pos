import 'dart:async';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';

/// Periodically scans for data integrity anomalies (e.g., negative stock) and logs warnings.
class IntegrityMonitor {
  final DatabaseHelper dbHelper;
  final Duration interval;
  Timer? _timer;
  bool _running = false;

  IntegrityMonitor({
    required this.dbHelper,
    this.interval = const Duration(minutes: 5),
  });

  void start() {
    if (_running) return;
    _running = true;
    _timer = Timer.periodic(interval, (_) => _scan());
    // immediate first scan (delayed slightly to allow app startup)
    Future.delayed(const Duration(seconds: 10), _scan);
  }

  Future<void> _scan() async {
    try {
      final db = await dbHelper.database;
      final negatives = await db.rawQuery(
        'SELECT id, quantity FROM product_variants WHERE quantity < 0 LIMIT 20',
      );
      if (negatives.isNotEmpty) {
        AppLogger.w(
          'Negative stock detected for ${negatives.length} variants (showing first=${negatives.first})',
        );
      }
    } catch (e, st) {
      AppLogger.e('Integrity scan failed', error: e, stackTrace: st);
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }
}
