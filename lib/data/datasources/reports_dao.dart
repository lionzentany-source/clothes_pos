import 'package:clothes_pos/core/db/database_helper.dart';

class ReportsDao {
  final DatabaseHelper _dbHelper;
  ReportsDao(this._dbHelper);

  Future<List<Map<String, Object?>>> salesByDay({
    String? startIso,
    String? endIso,
    int? userId,
    int? categoryId,
    int? supplierId,
  }) async {
    final db = await _dbHelper.database;
    final args = <Object?>[];
    final where = StringBuffer('WHERE 1=1');
    if (startIso != null) {
      where.write(' AND date(s.sale_date) >= date(?)');
      args.add(startIso);
    }
    if (endIso != null) {
      where.write(' AND date(s.sale_date) <= date(?)');
      args.add(endIso);
    }
    if (userId != null) {
      where.write(' AND s.user_id = ?');
      args.add(userId);
    }
    if (categoryId != null) {
      where.write(' AND pp.category_id = ?');
      args.add(categoryId);
    }
    if (supplierId != null) {
      where.write(' AND pp.supplier_id = ?');
      args.add(supplierId);
    }
    final sql =
        '''
      SELECT date(s.sale_date) AS d,
             COUNT(DISTINCT s.id) AS cnt,
             SUM(si.quantity * si.price_per_unit) AS total
      FROM sales s
      JOIN sale_items si ON si.sale_id = s.id
      JOIN product_variants pv ON pv.id = si.variant_id
      LEFT JOIN parent_products pp ON pp.id = pv.parent_product_id
      ${where.toString()}
      GROUP BY date(s.sale_date)
      ORDER BY d DESC
      LIMIT 90
    ''';
    return db.rawQuery(sql, args);
  }

  Future<List<Map<String, Object?>>> salesByMonth({
    String? startIso,
    String? endIso,
    int? userId,
    int? categoryId,
    int? supplierId,
  }) async {
    final db = await _dbHelper.database;
    final args = <Object?>[];
    final where = StringBuffer('WHERE 1=1');
    if (startIso != null) {
      where.write(' AND date(s.sale_date) >= date(?)');
      args.add(startIso);
    }
    if (endIso != null) {
      where.write(' AND date(s.sale_date) <= date(?)');
      args.add(endIso);
    }
    if (userId != null) {
      where.write(' AND s.user_id = ?');
      args.add(userId);
    }
    if (categoryId != null) {
      where.write(' AND pp.category_id = ?');
      args.add(categoryId);
    }
    if (supplierId != null) {
      where.write(' AND pp.supplier_id = ?');
      args.add(supplierId);
    }
    final sql =
        '''
      SELECT strftime('%Y-%m', s.sale_date) AS m,
             COUNT(DISTINCT s.id) AS cnt,
             SUM(si.quantity * si.price_per_unit) AS total
      FROM sales s
      JOIN sale_items si ON si.sale_id = s.id
      JOIN product_variants pv ON pv.id = si.variant_id
      LEFT JOIN parent_products pp ON pp.id = pv.parent_product_id
      ${where.toString()}
      GROUP BY strftime('%Y-%m', s.sale_date)
      ORDER BY m DESC
      LIMIT 24
    ''';
    return db.rawQuery(sql, args);
  }

  Future<List<Map<String, Object?>>> topProducts({
    int limit = 10,
    String? startIso,
    String? endIso,
    int? userId,
    int? categoryId,
    int? supplierId,
  }) async {
    final db = await _dbHelper.database;
    final args = <Object?>[limit];
    final where = StringBuffer('WHERE 1=1');
    if (startIso != null) {
      where.write(' AND date(s.sale_date) >= date(?)');
      args.add(startIso);
    }
    if (endIso != null) {
      where.write(' AND date(s.sale_date) <= date(?)');
      args.add(endIso);
    }
    if (userId != null) {
      where.write(' AND s.user_id = ?');
      args.add(userId);
    }
    if (categoryId != null) {
      where.write(' AND pp.category_id = ?');
      args.add(categoryId);
    }
    if (supplierId != null) {
      where.write(' AND pp.supplier_id = ?');
      args.add(supplierId);
    }
    final sql =
        '''
      SELECT pv.id AS variant_id, pv.sku,
             SUM(si.quantity) AS qty,
             SUM(si.quantity * si.price_per_unit) AS rev
      FROM sales s
      JOIN sale_items si ON si.sale_id = s.id
      JOIN product_variants pv ON pv.id = si.variant_id
      LEFT JOIN parent_products pp ON pp.id = pv.parent_product_id
      ${where.toString()}
      GROUP BY pv.id, pv.sku
      ORDER BY qty DESC
      LIMIT ?
    ''';
    return db.rawQuery(sql, args);
  }

  Future<List<Map<String, Object?>>> employeePerformance({
    int limit = 10,
    String? startIso,
    String? endIso,
    int? userId,
  }) async {
    final db = await _dbHelper.database;
    final args = <Object?>[limit];
    final where = StringBuffer('WHERE 1=1');
    if (startIso != null) {
      where.write(' AND date(s.sale_date) >= date(?)');
      args.add(startIso);
    }
    if (endIso != null) {
      where.write(' AND date(s.sale_date) <= date(?)');
      args.add(endIso);
    }
    if (userId != null) {
      where.write(' AND s.user_id = ?');
      args.add(userId);
    }
    final sql =
        '''
      SELECT u.id AS user_id, u.username,
             COUNT(s.id) AS cnt,
             SUM(s.total_amount) AS total
      FROM sales s
      LEFT JOIN users u ON u.id = s.user_id
      ${where.toString()}
      GROUP BY u.id, u.username
      ORDER BY total DESC
      LIMIT ?
    ''';
    return db.rawQuery(sql, args);
  }

  Future<double> purchasesTotalByDate({
    String? startIso,
    String? endIso,
    int? supplierId,
  }) async {
    final db = await _dbHelper.database;
    final args = <Object?>[];
    final where = StringBuffer('WHERE 1=1');
    if (startIso != null) {
      where.write(' AND date(received_date) >= date(?)');
      args.add(startIso);
    }
    if (endIso != null) {
      where.write(' AND date(received_date) <= date(?)');
      args.add(endIso);
    }
    if (supplierId != null) {
      where.write(' AND supplier_id = ?');
      args.add(supplierId);
    }
    final sql =
        'SELECT SUM(total_cost) AS total FROM purchase_invoices ${where.toString()}';
    final rows = await db.rawQuery(sql, args);
    final total = (rows.first['total'] as num?)?.toDouble() ?? 0;
    return total;
  }

  Future<double> expensesTotalByDate({
    String? startIso,
    String? endIso,
    int? categoryId,
  }) async {
    final db = await _dbHelper.database;
    final args = <Object?>[];
    final where = StringBuffer('WHERE 1=1');
    if (startIso != null) {
      where.write(' AND date(date) >= date(?)');
      args.add(startIso);
    }
    if (endIso != null) {
      where.write(' AND date(date) <= date(?)');
      args.add(endIso);
    }
    if (categoryId != null) {
      where.write(' AND category_id = ?');
      args.add(categoryId);
    }
    final rows = await db.rawQuery(
      'SELECT SUM(amount) AS total FROM expenses ${where.toString()}',
      args,
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, Object?>>> stockStatus({
    int limit = 50,
    int? categoryId,
    int? supplierId,
  }) async {
    final db = await _dbHelper.database;
    final args = <Object?>[limit];
    final where = StringBuffer('WHERE 1=1');
    if (categoryId != null) {
      where.write(' AND pp.category_id = ?');
      args.add(categoryId);
    }
    if (supplierId != null) {
      where.write(' AND pp.supplier_id = ?');
      args.add(supplierId);
    }
    final sql =
        '''
      SELECT pv.id AS variant_id, pv.sku, pv.quantity, pv.reorder_point
      FROM product_variants pv
      LEFT JOIN parent_products pp ON pp.id = pv.parent_product_id
      ${where.toString()}
      ORDER BY pv.quantity ASC
      LIMIT ?
    ''';
    return db.rawQuery(sql, args);
  }
}
