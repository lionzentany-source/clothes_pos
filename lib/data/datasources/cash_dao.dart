import 'package:clothes_pos/core/db/database_helper.dart';

class CashDao {
  final DatabaseHelper _dbHelper;
  CashDao(this._dbHelper);

  Future<Map<String, Object?>?> getOpenSession() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT * FROM cash_sessions WHERE closed_at IS NULL ORDER BY id DESC LIMIT 1',
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<int> openSession({
    required int openedBy,
    required double openingFloat,
  }) async {
    final db = await _dbHelper.database;
    return db.insert('cash_sessions', {
      'opened_by': openedBy,
      'opening_float': openingFloat,
    });
  }

  Future<double> closeSession({
    required int sessionId,
    required int closedBy,
    required double closingAmount,
  }) async {
    final db = await _dbHelper.database;
    // compute variance = closingAmount - (opening_float + sum IN - sum OUT)
    final sums = await db.rawQuery(
      '''
      SELECT
        (SELECT opening_float FROM cash_sessions WHERE id = ?) AS opening,
        (SELECT IFNULL(SUM(amount),0) FROM cash_movements WHERE cash_session_id = ? AND movement_type='IN') AS sin,
        (SELECT IFNULL(SUM(amount),0) FROM cash_movements WHERE cash_session_id = ? AND movement_type='OUT') AS sout,
        (SELECT IFNULL(SUM(amount),0) FROM expenses WHERE cash_session_id = ? AND paid_via = 'cash') AS sexp
    ''',
      [sessionId, sessionId, sessionId, sessionId],
    );
    final opening = (sums.first['opening'] as num).toDouble();
    final sin = (sums.first['sin'] as num).toDouble();
    final sout = (sums.first['sout'] as num).toDouble();
    final sexp = (sums.first['sexp'] as num).toDouble();
    // expected = opening + IN - OUT - cash expenses
    final variance = closingAmount - (opening + sin - sout - sexp);

    await db.update(
      'cash_sessions',
      {
        'closed_by': closedBy,
        'closed_at': DateTime.now().toIso8601String(),
        'closing_amount': closingAmount,
        'variance': variance,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    return variance;
  }

  Future<void> addMovement({
    required int sessionId,
    required double amount,
    required String type,
    String? reason,
  }) async {
    final db = await _dbHelper.database;
    await db.insert('cash_movements', {
      'cash_session_id': sessionId,
      'amount': amount,
      'movement_type': type,
      'reason': reason,
    });
  }

  Future<Map<String, Object?>> getSessionSummary(int sessionId) async {
    final db = await _dbHelper.database;
    final session = await db.query(
      'cash_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (session.isEmpty) return {};
    final payments = await db.rawQuery(
      'SELECT method, SUM(amount) total FROM payments WHERE cash_session_id = ? GROUP BY method',
      [sessionId],
    );
    final movements = await db.rawQuery(
      'SELECT movement_type type, SUM(amount) total FROM cash_movements WHERE cash_session_id = ? GROUP BY movement_type',
      [sessionId],
    );
    final expenses = await db.rawQuery(
      'SELECT IFNULL(SUM(amount),0) total FROM expenses WHERE cash_session_id = ? AND paid_via = "cash"',
      [sessionId],
    );
    final opening = (session.first['opening_float'] as num?)?.toDouble() ?? 0;
    double salesCash = 0;
    for (final p in payments) {
      if (p['method'] == 'cash') {
        salesCash = (p['total'] as num?)?.toDouble() ?? 0;
      }
    }
    double cashIn = 0, cashOut = 0;
    for (final m in movements) {
      final t = m['type'];
      final total = (m['total'] as num?)?.toDouble() ?? 0;
      if (t == 'IN') {
        cashIn = total;
      } else if (t == 'OUT') {
        cashOut = total;
      }
    }
    final cashExpenses = (expenses.first['total'] as num?)?.toDouble() ?? 0;
    final current = opening + salesCash + cashIn - cashOut - cashExpenses;
    return {
      'session': session.first,
      'opening_float': opening,
      'sales_cash': salesCash,
      'cash_in': cashIn,
      'cash_out': cashOut,
      'cash_expenses': cashExpenses,
      'expected_cash': current,
    };
  }
}
