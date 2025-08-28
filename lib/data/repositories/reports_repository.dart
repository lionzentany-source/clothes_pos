import 'package:clothes_pos/data/datasources/reports_dao.dart';
import 'package:clothes_pos/core/result/result.dart';
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

  Future<List<Map<String, Object?>>> employeePerformance({
    int limit = 10,
    String? startIso,
    String? endIso,
    int? userId,
  }) => dao.employeePerformance(
    limit: limit,
    startIso: startIso,
    endIso: endIso,
    userId: userId,
  );

  Future<List<Map<String, Object?>>> stockStatus({
    int limit = 50,
    int? categoryId,
    int? supplierId,
  }) => dao.stockStatus(
    limit: limit,
    categoryId: categoryId,
    supplierId: supplierId,
  );

  Future<double> purchasesTotalByDate({
    String? startIso,
    String? endIso,
    int? supplierId,
  }) => dao.purchasesTotalByDate(
    startIso: startIso,
    endIso: endIso,
    supplierId: supplierId,
  );

  Future<double> expensesTotalByDate({
    String? startIso,
    String? endIso,
    int? categoryId,
  }) => dao.expensesTotalByDate(
    startIso: startIso,
    endIso: endIso,
    categoryId: categoryId,
  );

  // Incremental Result wrappers (example subset)
  Future<Result<List<Map<String, Object?>>>> salesByDayResult({
    String? startIso,
    String? endIso,
    int? userId,
    int? categoryId,
    int? supplierId,
  }) async {
    try {
      final data = await salesByDay(
        startIso: startIso,
        endIso: endIso,
        userId: userId,
        categoryId: categoryId,
        supplierId: supplierId,
      );
      return ok(data);
    } catch (e, st) {
      AppLogger.e('salesByDay failed', error: e, stackTrace: st);
      return fail(
        'تعذر تحميل تقرير المبيعات اليومية',
        code: 'report_sales_day',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }

  Future<Result<List<Map<String, Object?>>>> topProductsResult({
    int limit = 10,
    String? startIso,
    String? endIso,
    int? userId,
    int? categoryId,
    int? supplierId,
  }) async {
    try {
      final data = await topProducts(
        limit: limit,
        startIso: startIso,
        endIso: endIso,
        userId: userId,
        categoryId: categoryId,
        supplierId: supplierId,
      );
      return ok(data);
    } catch (e, st) {
      AppLogger.e('topProducts failed', error: e, stackTrace: st);
      return fail(
        'تعذر تحميل أفضل المنتجات',
        code: 'report_top_products',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }
}
