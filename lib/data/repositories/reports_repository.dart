import 'package:clothes_pos/data/datasources/reports_dao.dart';

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
}
