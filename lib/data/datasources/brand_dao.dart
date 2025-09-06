import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/models/brand.dart';

class BrandDao {
  final DatabaseHelper _dbHelper;
  BrandDao(this._dbHelper);

  Future<List<Brand>> listAll({int limit = 200, int offset = 0}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'brands',
      limit: limit,
      offset: offset,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map((e) => Brand.fromMap(e)).toList();
  }

  Future<int> insert(String name) async {
    final db = await _dbHelper.database;
    return db.insert('brands', {'name': name});
  }
}

