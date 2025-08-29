import 'dart:async';
import 'package:sqflite/sqflite.dart';

import '../../core/logging/app_logger.dart';
import 'package:clothes_pos/data/datasources/product_dao.dart';
import 'package:clothes_pos/core/config/feature_flags.dart';
import 'package:clothes_pos/core/di/locator.dart';
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
        SELECT date(s.sale_date) AS day, SUM(si.quantity * si.price_per_unit) AS total
        FROM sales s
        JOIN sale_items si ON si.sale_id = s.id
        WHERE s.sale_date >= ? AND s.sale_date < ?
        GROUP BY day
        ORDER BY day ASC
      ''',
        [from.toIso8601String(), to.toIso8601String()],
      );
      // Attach attributes to variant rows when dynamic attributes feature is enabled.
      if (FeatureFlags.useDynamicAttributes && rows.isNotEmpty) {
        try {
          final productDao = sl<ProductDao>();
          // collect variant ids
          final vids = <int>[];
          for (final r in rows) {
            final vid = (r['id'] as int?);
            if (vid != null) vids.add(vid);
          }
          if (vids.isNotEmpty) {
            final variants = await productDao.getVariantsByIds(
              vids.toSet().toList(),
            );
            final mapById = {for (var v in variants) v.id!: v};
            for (final r in rows) {
              final vid = (r['id'] as int?);
              if (vid != null && mapById.containsKey(vid)) {
                r['attributes'] = mapById[vid]!.attributes ?? [];
              } else {
                r['attributes'] = [];
              }
            }
          } else {
            for (final r in rows) r['attributes'] = [];
          }
        } catch (e, st) {
          AppLogger.w(
            'Failed to enrich lowTurnoverProducts with attributes',
            error: e,
            stackTrace: st,
          );
        }
      }

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
        SELECT pp.id, pp.name, SUM(si.quantity) AS qty, SUM(si.quantity * si.price_per_unit) AS revenue
        FROM sales s
        JOIN sale_items si ON si.sale_id = s.id
        JOIN product_variants pv ON pv.id = si.variant_id
        JOIN parent_products pp ON pp.id = pv.parent_product_id
        WHERE s.sale_date >= ? AND s.sale_date < ?
        GROUP BY pp.id, pp.name
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
        SELECT pv.id, pp.name, pv.quantity, MAX(s.sale_date) AS last_sale
        FROM product_variants pv
        JOIN parent_products pp ON pp.id = pv.parent_product_id
        LEFT JOIN sale_items si ON si.variant_id = pv.id
        LEFT JOIN sales s ON s.id = si.sale_id
        GROUP BY pv.id, pp.name, pv.quantity
        HAVING ( (julianday('now') - julianday(MAX(s.sale_date))) >= ? OR MAX(s.sale_date) IS NULL )
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
        SELECT pv.id, pp.name, pv.quantity
        FROM product_variants pv
        JOIN parent_products pp ON pp.id = pv.parent_product_id
        WHERE pv.quantity <= ? AND pv.quantity > ?
        ORDER BY pv.quantity ASC
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
