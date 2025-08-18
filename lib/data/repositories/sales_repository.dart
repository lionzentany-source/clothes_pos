import 'package:clothes_pos/data/datasources/sales_dao.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/data/models/payment.dart';
import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';

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

  Future<List<SaleItem>> itemsForSale(int saleId) => dao.itemsForSale(saleId);
  Future<Sale> getSale(int saleId) => dao.getSale(saleId);
  Future<List<Payment>> paymentsForSale(int saleId) =>
      dao.paymentsForSale(saleId);
}
