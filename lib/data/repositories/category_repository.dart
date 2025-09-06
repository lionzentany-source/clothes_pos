import 'package:clothes_pos/data/datasources/category_dao.dart';
import 'package:clothes_pos/data/models/category.dart';

class CategoryRepository {
  final CategoryDao dao;
  CategoryRepository(this.dao);

  Future<List<Category>> listAll({int limit = 200, int offset = 0}) =>
      dao.listAll(limit: limit, offset: offset);
  Future<int> create(String name) => dao.insert(name);
}
