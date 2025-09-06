import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/models/category.dart';

class CategoryDao {
  final DatabaseHelper _dbHelper;
  CategoryDao(this._dbHelper);

  Future<List<Category>> listAll({int limit = 200, int offset = 0}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'categories',
      limit: limit,
      offset: offset,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map((e) => Category.fromMap(e)).toList();
  }

  Future<int> insert(String name) async {
    final db = await _dbHelper.database;
    return db.insert('categories', {'name': name});
  }
}
