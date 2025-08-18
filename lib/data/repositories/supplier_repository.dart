import 'package:clothes_pos/data/datasources/supplier_dao.dart';
import 'package:clothes_pos/data/models/supplier.dart';

class SupplierRepository {
  final SupplierDao dao;
  SupplierRepository(this.dao);

  Future<List<Supplier>> search(String q, {int limit = 50, int offset = 0}) =>
      dao.searchByName(q, limit: limit, offset: offset);
  Future<List<Supplier>> listAll({int limit = 50, int offset = 0}) =>
      dao.listAll(limit: limit, offset: offset);
  Future<int> create(String name, {String? contactInfo}) =>
      dao.insert(name, contactInfo: contactInfo);
}
