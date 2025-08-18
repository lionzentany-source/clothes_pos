import 'dart:async';
import 'package:sqflite/sqflite.dart';

import '../../core/logging/app_logger.dart';
import '../../core/result/result.dart';

/// Provides aggregate / analytical queries for dashboards and insights.
class AggregatedReportsRepository {
  final Database db;
  AggregatedReportsRepository(this.db);

  Future<Result<List<Map<String, Object?>>>> dailySales({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final rows = await db.rawQuery(
        '''
        SELECT date(s.created_at) AS day, SUM(sp.quantity * sp.price) AS total
        FROM sales s
        JOIN sale_products sp ON sp.sale_id = s.id
        WHERE s.created_at >= ? AND s.created_at < ?
        GROUP BY day
        ORDER BY day ASC
      ''',
        [from.toIso8601String(), to.toIso8601String()],
      );
      return ok(rows);
    } catch (e, st) {
      AppLogger.e('dailySales failed', error: e, stackTrace: st);
      return fail(
        'Failed to load daily sales',
        code: 'agg_daily_sales',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }

  Future<Result<List<Map<String, Object?>>>> topSellingProducts({
    required DateTime from,
    required DateTime to,
    int limit = 10,
  }) async {
    try {
      final rows = await db.rawQuery(
        '''
        SELECT p.id, p.name, SUM(sp.quantity) AS qty, SUM(sp.quantity * sp.price) AS revenue
        FROM sales s
        JOIN sale_products sp ON sp.sale_id = s.id
        JOIN products p ON p.id = sp.product_id
        WHERE s.created_at >= ? AND s.created_at < ?
        GROUP BY p.id, p.name
        ORDER BY qty DESC
        LIMIT ?
      ''',
        [from.toIso8601String(), to.toIso8601String(), limit],
      );
      return ok(rows);
    } catch (e, st) {
      AppLogger.e('topSellingProducts failed', error: e, stackTrace: st);
      return fail(
        'Failed to load top products',
        code: 'agg_top_products',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }

  Future<Result<List<Map<String, Object?>>>> lowTurnoverProducts({
    int minDays = 30,
    int limit = 20,
  }) async {
    try {
      final rows = await db.rawQuery(
        '''
        SELECT p.id, p.name, p.quantity, MAX(s.created_at) AS last_sale
        FROM products p
        LEFT JOIN sale_products sp ON sp.product_id = p.id
        LEFT JOIN sales s ON s.id = sp.sale_id
        GROUP BY p.id, p.name, p.quantity
        HAVING ( (julianday('now') - julianday(MAX(s.created_at))) >= ? OR MAX(s.created_at) IS NULL )
        ORDER BY last_sale ASC
        LIMIT ?
      ''',
        [minDays, limit],
      );
      return ok(rows);
    } catch (e, st) {
      AppLogger.e('lowTurnoverProducts failed', error: e, stackTrace: st);
      return fail(
        'Failed to load low turnover products',
        code: 'agg_low_turnover',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }

  Future<Result<List<Map<String, Object?>>>> reorderSuggestions({
    int minQty = 0,
    int threshold = 5,
    int limit = 50,
  }) async {
    try {
      final rows = await db.rawQuery(
        '''
        SELECT p.id, p.name, p.quantity
        FROM products p
        WHERE p.quantity <= ? AND p.quantity > ?
        ORDER BY p.quantity ASC
        LIMIT ?
      ''',
        [threshold, minQty, limit],
      );
      return ok(rows);
    } catch (e, st) {
      AppLogger.e('reorderSuggestions failed', error: e, stackTrace: st);
      return fail(
        'Failed to load reorder suggestions',
        code: 'agg_reorder',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }
}
