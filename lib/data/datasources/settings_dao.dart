import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class SettingsDao {
  final DatabaseHelper _dbHelper;
  SettingsDao(this._dbHelper);

  Future<String?> get(String key) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> set(String key, String? value) async {
    final db = await _dbHelper.database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
