import 'package:clothes_pos/data/datasources/sales_dao.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/data/models/payment.dart';
import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';
import 'package:clothes_pos/core/result/result.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';

typedef PermissionChecker = bool Function(String code);
typedef CashSessionProvider = Future<Map<String, Object?>?> Function();

class SalesRepository {
  final SalesDao dao;
  // Optional injected guards
  PermissionChecker? hasPermission;
  CashSessionProvider? getOpenSession;
  SalesRepository(this.dao, {this.hasPermission, this.getOpenSession});

  void setGuards({
    PermissionChecker? permission,
    CashSessionProvider? openSession,
  }) {
    hasPermission = permission ?? hasPermission;
    getOpenSession = openSession ?? getOpenSession;
  }

  Future<int> createSale({
    required Sale sale,
    required List<SaleItem> items,
    required List<Payment> payments,
  }) async {
    // Guard: permission
    if (hasPermission != null &&
        !hasPermission!.call(AppPermissions.performSales)) {
      throw Exception('Permission denied: ${AppPermissions.performSales}');
    }
    // Guard: require an open cash session for ALL sales (not only cash payments)
    if (getOpenSession != null) {
      final session = await getOpenSession!.call();
      if (session == null) {
        throw Exception('No open cash session');
      }
    }
    return dao.createSale(sale: sale, items: items, payments: payments);
  }

  // Incremental adoption: new Result-based wrapper preserving original API.
  Future<Result<int>> createSaleResult({
    required Sale sale,
    required List<SaleItem> items,
    required List<Payment> payments,
  }) async {
    try {
      final id = await createSale(sale: sale, items: items, payments: payments);
      return ok(id);
    } on Exception catch (e, st) {
      final msg = e.toString();
      final code = msg.contains('Permission denied')
          ? 'permission_denied'
          : (msg.contains('No open cash session')
                ? 'no_cash_session'
                : 'sale_error');
      AppLogger.w('createSaleResult failed: $msg');
      return fail(
        'تعذر إنشاء عملية البيع',
        code: code,
        exception: e,
        stackTrace: st,
        retryable: code == 'sale_error',
      );
    } catch (e, st) {
      AppLogger.e('createSaleResult unexpected', error: e, stackTrace: st);
      return fail(
        'خطأ غير متوقع',
        code: 'unexpected',
        exception: e,
        stackTrace: st,
        retryable: false,
      );
    }
  }

  Future<List<SaleItem>> itemsForSale(int saleId) => dao.itemsForSale(saleId);
  Future<Sale> getSale(int saleId) => dao.getSale(saleId);
  Future<List<Payment>> paymentsForSale(int saleId) =>
      dao.paymentsForSale(saleId);
}
