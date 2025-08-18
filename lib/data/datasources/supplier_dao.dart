import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/models/supplier.dart';

class SupplierDao {
  final DatabaseHelper _dbHelper;
  SupplierDao(this._dbHelper);

  Future<List<Supplier>> searchByName(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'suppliers',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      limit: limit,
      offset: offset,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map((e) => Supplier.fromMap(e)).toList();
  }

  Future<List<Supplier>> listAll({int limit = 50, int offset = 0}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'suppliers',
      limit: limit,
      offset: offset,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map((e) => Supplier.fromMap(e)).toList();
  }

  Future<int> insert(String name, {String? contactInfo}) async {
    final db = await _dbHelper.database;
    return db.insert('suppliers', {
      'name': name,
      if (contactInfo != null && contactInfo.isNotEmpty)
        'contact_info': contactInfo,
    });
  }
}
