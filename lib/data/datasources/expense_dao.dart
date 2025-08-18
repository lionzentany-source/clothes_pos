import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/models/expense.dart';
import 'package:clothes_pos/data/models/expense_category.dart';

class ExpenseDao {
  final DatabaseHelper _dbHelper;
  ExpenseDao(this._dbHelper);

  Future<List<ExpenseCategory>> listCategories({bool onlyActive = true}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'expense_categories',
      where: onlyActive ? 'is_active = 1' : null,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map((e) => ExpenseCategory.fromMap(e)).toList();
  }

  Future<int> createCategory(String name) async {
    final db = await _dbHelper.database;
    return db.insert('expense_categories', {'name': name.trim()});
  }

  Future<void> renameCategory(int id, String newName) async {
    final db = await _dbHelper.database;
    await db.update(
      'expense_categories',
      {'name': newName.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setCategoryActive(int id, bool active) async {
    final db = await _dbHelper.database;
    await db.update(
      'expense_categories',
      {'is_active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> createExpense(Expense e) async {
    final db = await _dbHelper.database;
    return db.insert('expenses', e.toMap());
  }

  Future<void> updateExpense(Expense e) async {
    if (e.id == null) return;
    final db = await _dbHelper.database;
    await db.update('expenses', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteExpense(int id) async {
    final db = await _dbHelper.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> listExpenses({
    DateTime? start,
    DateTime? end,
    int? categoryId,
    String? paidVia,
    int limit = 500,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <Object?>[];
    if (start != null) {
      where.add('date(date) >= date(?)');
      args.add(start.toIso8601String());
    }
    if (end != null) {
      where.add('date(date) <= date(?)');
      args.add(end.toIso8601String());
    }
    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    if (paidVia != null && paidVia.isNotEmpty) {
      where.add('paid_via = ?');
      args.add(paidVia);
    }
    final whereClause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery(
      '''
      SELECT e.*, c.name AS category_name
      FROM expenses e
      LEFT JOIN expense_categories c ON c.id = e.category_id
      $whereClause
      ORDER BY date DESC, id DESC
      LIMIT ? OFFSET ?
    ''',
      [...args, limit, offset],
    );
    return rows.map((e) => Expense.fromMap(e)).toList();
  }

  Future<double> sumExpenses({
    DateTime? start,
    DateTime? end,
    int? categoryId,
  }) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <Object?>[];
    if (start != null) {
      where.add('date(date) >= date(?)');
      args.add(start.toIso8601String());
    }
    if (end != null) {
      where.add('date(date) <= date(?)');
      args.add(end.toIso8601String());
    }
    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    final whereClause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery(
      'SELECT SUM(amount) AS total FROM expenses $whereClause',
      args,
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> sumByCategory({
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <Object?>[];
    if (start != null) {
      where.add('date(e.date) >= date(?)');
      args.add(start.toIso8601String());
    }
    if (end != null) {
      where.add('date(e.date) <= date(?)');
      args.add(end.toIso8601String());
    }
    final whereClause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery('''
      SELECT c.name, SUM(e.amount) total
      FROM expenses e
      LEFT JOIN expense_categories c ON c.id = e.category_id
      $whereClause
      GROUP BY c.name
      ORDER BY total DESC
    ''', args);
    final map = <String, double>{};
    for (final r in rows) {
      map[(r['name'] as String? ?? 'غير مصنف')] =
          (r['total'] as num?)?.toDouble() ?? 0;
    }
    return map;
  }
}
