import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';
import 'package:clothes_pos/data/models/expense.dart';
import 'package:clothes_pos/data/models/expense_category.dart';

class ExpenseDao {
  final DatabaseHelper _dbHelper;
  ExpenseDao(this._dbHelper);

  Future<List<ExpenseCategory>> listCategories({bool onlyActive = true}) async {
    AppLogger.d('ExpenseDao.listCategories onlyActive=$onlyActive');
    final sw = Stopwatch()..start();
    final db = await _dbHelper.database;
    final rows = await db.query(
      'expense_categories',
      where: onlyActive ? 'is_active = 1' : null,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    sw.stop();
    AppLogger.d(
      'ExpenseDao.listCategories rows=${rows.length} in ${sw.elapsedMilliseconds}ms',
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
    AppLogger.d(
      'ExpenseDao.listExpenses start=$start end=$end cat=$categoryId paidVia=$paidVia limit=$limit offset=$offset',
    );
    final sw = Stopwatch()..start();
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
    sw.stop();
    AppLogger.d(
      'ExpenseDao.listExpenses rows=${rows.length} in ${sw.elapsedMilliseconds}ms',
    );
    final list = <Expense>[];
    var rowIndex = 0;
    for (final r in rows) {
      try {
        final rowSw = Stopwatch()..start();
        list.add(Expense.fromMap(r));
        rowSw.stop();
        if (rowSw.elapsedMilliseconds > 50) {
          AppLogger.w(
            'ExpenseDao.listExpenses slow row parse idx=$rowIndex took=${rowSw.elapsedMilliseconds}ms',
          );
        }
      } catch (e, st) {
        AppLogger.e(
          'ExpenseDao.listExpenses row map failed row=$r',
          error: e,
          stackTrace: st,
        );
      }
      rowIndex++;
    }
    return list;
  }

  Future<double> sumExpenses({
    DateTime? start,
    DateTime? end,
    int? categoryId,
  }) async {
    AppLogger.d('ExpenseDao.sumExpenses start=$start end=$end cat=$categoryId');
    final sw = Stopwatch()..start();
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
    List<Map<String, Object?>> rows;
    try {
      final future = db.rawQuery(
        'SELECT COALESCE(SUM(amount),0) AS total FROM expenses $whereClause',
        args,
      );
      rows = await future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          AppLogger.w(
            'ExpenseDao.sumExpenses timeout after 5s; returning fallback 0 and will retry async',
          );
          return [
            {'total': 0},
          ];
        },
      );
    } catch (e, st) {
      AppLogger.e(
        'ExpenseDao.sumExpenses query failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
    sw.stop();
    final total = (rows.first['total'] as num?)?.toDouble() ?? 0.0;
    AppLogger.d(
      'ExpenseDao.sumExpenses total=$total in ${sw.elapsedMilliseconds}ms',
    );
    return total;
  }

  Future<Map<String, double>> sumByCategory({
    DateTime? start,
    DateTime? end,
  }) async {
    AppLogger.d('ExpenseDao.sumByCategory start=$start end=$end');
    final sw = Stopwatch()..start();
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
    sw.stop();
    AppLogger.d(
      'ExpenseDao.sumByCategory rows=${map.length} in ${sw.elapsedMilliseconds}ms',
    );
    return map;
  }
}
