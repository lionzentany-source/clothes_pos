import 'package:clothes_pos/data/datasources/reports_dao.dart';
import 'package:clothes_pos/data/datasources/product_dao.dart';
import 'package:clothes_pos/core/config/feature_flags.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';

class ReportsRepository {
  final ReportsDao dao;
  ReportsRepository(this.dao);

  Future<List<Map<String, Object?>>> salesByDay({
    String? startIso,
    String? endIso,
    int? userId,
    int? categoryId,
    int? supplierId,
  }) => dao.salesByDay(
    startIso: startIso,
    endIso: endIso,
    userId: userId,
    categoryId: categoryId,
    supplierId: supplierId,
  );

  Future<List<Map<String, Object?>>> salesByMonth({
    String? startIso,
    String? endIso,
    int? userId,
    int? categoryId,
    int? supplierId,
  }) => dao.salesByMonth(
    startIso: startIso,
    endIso: endIso,
    userId: userId,
    categoryId: categoryId,
    supplierId: supplierId,
  );

  Future<List<Map<String, Object?>>> topProducts({
    int limit = 10,
    String? startIso,
    String? endIso,
    int? userId,
    int? categoryId,
    int? supplierId,
  }) => dao.topProducts(
    limit: limit,
    startIso: startIso,
    endIso: endIso,
    userId: userId,
    categoryId: categoryId,
    supplierId: supplierId,
  );

  Future<List<Map<String, Object?>>> salesByCategory({
    String? startIso,
    String? endIso,
    int? userId,
  }) => dao.salesByCategory(startIso: startIso, endIso: endIso, userId: userId);

  /// Get total expenses for a date range
  Future<double> expensesTotalByDate({
    required String startIso,
    required String endIso,
  }) async {
    try {
      return await dao.expensesTotalByDate(startIso: startIso, endIso: endIso);
    } catch (e, st) {
      AppLogger.e('expensesTotalByDate failed', error: e, stackTrace: st);
      return 0.0;
    }
  }

  /// Get total purchases for a date range
  Future<double> purchasesTotalByDate({
    required String startIso,
    required String endIso,
  }) async {
    try {
      return await dao.purchasesTotalByDate(startIso: startIso, endIso: endIso);
    } catch (e, st) {
      AppLogger.e('purchasesTotalByDate failed', error: e, stackTrace: st);
      return 0.0;
    }
  }

  /// Get stock status report
  Future<List<Map<String, Object?>>> stockStatus({
    int? categoryId,
    bool? lowStockOnly,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final rows = await dao.stockStatus(
        categoryId: categoryId,
        lowStockOnly: lowStockOnly,
        limit: limit,
        offset: offset,
      );

      // If dynamic attributes are enabled, enrich variant rows with their
      // attributes by loading the variant via ProductDao. We resolve a
      // ProductDao from the service locator to avoid changing the constructor.
      if (FeatureFlags.useDynamicAttributes && rows.isNotEmpty) {
        try {
          final productDao = sl<ProductDao>();
          // collect variant ids
          final vids = <int>[];
          for (final r in rows) {
            final vid = (r['id'] ?? r['pv_id'] ?? r['pv.id']) as int?;
            if (vid != null) vids.add(vid);
          }
          if (vids.isNotEmpty) {
            final variants = await productDao.getVariantsByIds(
              vids.toSet().toList(),
            );
            final mapById = {for (var v in variants) v.id!: v};
            for (final r in rows) {
              final vid = (r['id'] ?? r['pv_id'] ?? r['pv.id']) as int?;
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
            'Failed to enrich stockStatus with attributes',
            error: e,
            stackTrace: st,
          );
        }
      }

      return rows;
    } catch (e, st) {
      AppLogger.e('stockStatus failed', error: e, stackTrace: st);
      return [];
    }
  }

  /// Get sales total for a date range
  Future<double> salesTotalByDate({
    required String startIso,
    required String endIso,
    int? userId,
    int? categoryId,
  }) async {
    try {
      return await dao.salesTotalByDate(
        startIso: startIso,
        endIso: endIso,
        userId: userId,
        categoryId: categoryId,
      );
    } catch (e, st) {
      AppLogger.e('salesTotalByDate failed', error: e, stackTrace: st);
      return 0.0;
    }
  }

  /// Get returns total for a date range
  Future<double> returnsTotalByDate({
    required String startIso,
    required String endIso,
    int? userId,
  }) async {
    try {
      return await dao.returnsTotalByDate(
        startIso: startIso,
        endIso: endIso,
        userId: userId,
      );
    } catch (e, st) {
      AppLogger.e('returnsTotalByDate failed', error: e, stackTrace: st);
      return 0.0;
    }
  }

  /// Get profit calculation for a date range
  Future<double> profitByDate({
    required String startIso,
    required String endIso,
    int? userId,
  }) async {
    try {
      final sales = await salesTotalByDate(
        startIso: startIso,
        endIso: endIso,
        userId: userId,
      );
      final purchases = await purchasesTotalByDate(
        startIso: startIso,
        endIso: endIso,
      );
      final expenses = await expensesTotalByDate(
        startIso: startIso,
        endIso: endIso,
      );
      final returns = await returnsTotalByDate(
        startIso: startIso,
        endIso: endIso,
        userId: userId,
      );

      return sales - purchases - expenses - returns;
    } catch (e, st) {
      AppLogger.e('profitByDate failed', error: e, stackTrace: st);
      return 0.0;
    }
  }

  /// Get customer count
  Future<int> customerCount() async {
    try {
      return await dao.customerCount();
    } catch (e, st) {
      AppLogger.e('customerCount failed', error: e, stackTrace: st);
      return 0;
    }
  }

  /// Get inventory count
  Future<int> inventoryCount() async {
    try {
      return await dao.inventoryCount();
    } catch (e, st) {
      AppLogger.e('inventoryCount failed', error: e, stackTrace: st);
      return 0;
    }
  }
}
