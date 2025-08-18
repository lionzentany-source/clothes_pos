import 'package:clothes_pos/data/datasources/returns_dao.dart';

class ReturnsRepository {
  final ReturnsDao dao;
  ReturnsRepository(this.dao);

  Future<List<Map<String, Object?>>> getReturnableItems(int saleId) => dao.getReturnableItems(saleId);
  Future<int> createReturn({required int saleId, required int userId, String? reason, required List<ReturnLineInput> items}) =>
      dao.createReturn(saleId: saleId, userId: userId, reason: reason, items: items);
}

