import 'package:clothes_pos/data/datasources/brand_dao.dart';
import 'package:clothes_pos/data/models/brand.dart';

class BrandRepository {
  final BrandDao dao;
  BrandRepository(this.dao);

  Future<List<Brand>> listAll({int limit = 200}) => dao.listAll(limit: limit);
  Future<int> create(String name) => dao.insert(name);
}

