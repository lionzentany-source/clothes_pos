import 'package:clothes_pos/data/datasources/held_sales_dao.dart';

class HeldSalesRepository {
  final HeldSalesDao _dao;
  HeldSalesRepository(this._dao);

  Future<int> saveHeldSale(
    String name,
    List<Map<String, Object?>> items,
  ) async {
    final ts = DateTime.now().toIso8601String();
    return _dao.insertHeldSale(name, ts, items);
  }

  Future<List<Map<String, Object?>>> listHeldSales() async {
    return _dao.listHeldSalesSummary();
  }

  Future<List<Map<String, Object?>>> getItemsForHeldSale(int id) async {
    return _dao.itemsForHeldSale(id);
  }

  Future<void> deleteHeldSale(int id) async {
    return _dao.deleteHeldSale(id);
  }
}
