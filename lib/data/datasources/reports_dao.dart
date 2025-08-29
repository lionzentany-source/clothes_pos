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

    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (startIso != null) {
      whereConditions.add('s.sale_date >= ?');
      whereArgs.add(startIso);
    }

    if (endIso != null) {
      whereConditions.add('s.sale_date <= ?');
      whereArgs.add(endIso);
    }

    if (userId != null) {
      whereConditions.add('s.user_id = ?');
      whereArgs.add(userId);
    }

    if (categoryId != null) {
      whereConditions.add('p.category_id = ?');
      whereArgs.add(categoryId);
    }

    if (supplierId != null) {
      whereConditions.add('p.supplier_id = ?');
      whereArgs.add(supplierId);
    }

    final whereClause = whereConditions.isEmpty
        ? ''
        : 'WHERE ${whereConditions.join(' AND ')}';

    final result = await db.rawQuery('''
      SELECT 
        DATE(s.sale_date) AS sale_date,
        COUNT(DISTINCT s.id) AS invoice_count,
        SUM(si.quantity * si.price_per_unit) AS total_amount
      FROM sales s
      JOIN sale_items si ON s.id = si.sale_id
      JOIN product_variants pv ON si.variant_id = pv.id
      JOIN parent_products pp ON pv.parent_product_id = pp.id
      $whereClause
      GROUP BY DATE(s.sale_date)
      ORDER BY sale_date
    ''', whereArgs);

    return result;
  }

  Future<List<Map<String, Object?>>> salesByMonth({
    String? startIso,
    String? endIso,
    int? userId,
    int? categoryId,
    int? supplierId,
  }) async {
    final db = await _dbHelper.database;

    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (startIso != null) {
      whereConditions.add('s.sale_date >= ?');
      whereArgs.add(startIso);
    }

    if (endIso != null) {
      whereConditions.add('s.sale_date <= ?');
      whereArgs.add(endIso);
    }

    if (userId != null) {
      whereConditions.add('s.user_id = ?');
      whereArgs.add(userId);
    }

    if (categoryId != null) {
      whereConditions.add('pp.category_id = ?');
      whereArgs.add(categoryId);
    }

    if (supplierId != null) {
      whereConditions.add('pp.supplier_id = ?');
      whereArgs.add(supplierId);
    }

    final whereClause = whereConditions.isEmpty
        ? ''
        : 'WHERE ${whereConditions.join(' AND ')}';

    final result = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', s.sale_date) AS sale_month,
        COUNT(DISTINCT s.id) AS invoice_count,
        SUM(si.quantity * si.price_per_unit) AS total_amount
      FROM sales s
      JOIN sale_items si ON s.id = si.sale_id
      JOIN product_variants pv ON si.variant_id = pv.id
      JOIN parent_products pp ON pv.parent_product_id = pp.id
      $whereClause
      GROUP BY strftime('%Y-%m', s.sale_date)
      ORDER BY sale_month
    ''', whereArgs);

    return result;
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

    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (startIso != null) {
      whereConditions.add('s.sale_date >= ?');
      whereArgs.add(startIso);
    }

    if (endIso != null) {
      whereConditions.add('s.sale_date <= ?');
      whereArgs.add(endIso);
    }

    if (userId != null) {
      whereConditions.add('s.user_id = ?');
      whereArgs.add(userId);
    }

    if (categoryId != null) {
      whereConditions.add('pp.category_id = ?');
      whereArgs.add(categoryId);
    }

    if (supplierId != null) {
      whereConditions.add('pp.supplier_id = ?');
      whereArgs.add(supplierId);
    }

    final whereClause = whereConditions.isEmpty
        ? ''
        : 'WHERE ${whereConditions.join(' AND ')}';

    final result = await db.rawQuery(
      '''
      SELECT 
        pp.name,
        SUM(si.quantity) AS product_count,
        SUM(si.quantity * si.price_per_unit) AS total_amount
      FROM sales s
      JOIN sale_items si ON s.id = si.sale_id
      JOIN product_variants pv ON si.variant_id = pv.id
      JOIN parent_products pp ON pv.parent_product_id = pp.id
      $whereClause
      GROUP BY pp.id, pp.name
      ORDER BY product_count DESC
      LIMIT ?
    ''',
      [...whereArgs, limit],
    );

    return result;
  }

  Future<List<Map<String, Object?>>> salesByCategory({
    String? startIso,
    String? endIso,
    int? userId,
  }) async {
    final db = await _dbHelper.database;

    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (startIso != null) {
      whereConditions.add('s.sale_date >= ?');
      whereArgs.add(startIso);
    }

    if (endIso != null) {
      whereConditions.add('s.sale_date <= ?');
      whereArgs.add(endIso);
    }

    if (userId != null) {
      whereConditions.add('s.user_id = ?');
      whereArgs.add(userId);
    }

    final whereClause = whereConditions.isEmpty
        ? ''
        : 'WHERE ${whereConditions.join(' AND ')}';

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(c.name, 'غير مصنف') AS name,
        COUNT(DISTINCT s.id) AS invoice_count,
        SUM(si.quantity * si.price_per_unit) AS total_amount
      FROM sales s
      JOIN sale_items si ON s.id = si.sale_id
      JOIN product_variants pv ON si.variant_id = pv.id
      JOIN parent_products pp ON pv.parent_product_id = pp.id
      LEFT JOIN categories c ON pp.category_id = c.id
      $whereClause
      GROUP BY c.id, c.name
      ORDER BY total_amount DESC
    ''', whereArgs);

    return result;
  }

  /// Get total expenses for a date range
  Future<double> expensesTotalByDate({
    required String startIso,
    required String endIso,
  }) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0.0) AS total
      FROM expenses
      WHERE created_at >= ? AND created_at <= ?
    ''',
      [startIso, endIso],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get total purchases for a date range
  Future<double> purchasesTotalByDate({
    required String startIso,
    required String endIso,
  }) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(pii.quantity * pii.cost_price), 0.0) AS total
      FROM purchase_invoices pi
      JOIN purchase_invoice_items pii ON pi.id = pii.purchase_invoice_id
      WHERE pi.created_at >= ? AND pi.created_at <= ?
    ''',
      [startIso, endIso],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get sales total for a date range
  Future<double> salesTotalByDate({
    required String startIso,
    required String endIso,
    int? userId,
    int? categoryId,
  }) async {
    final db = await _dbHelper.database;

    final whereConditions = <String>['s.sale_date >= ?', 's.sale_date <= ?'];
    final whereArgs = <dynamic>[startIso, endIso];

    if (userId != null) {
      whereConditions.add('s.user_id = ?');
      whereArgs.add(userId);
    }

    if (categoryId != null) {
      whereConditions.add(
        'pv.parent_product_id IN (SELECT id FROM parent_products WHERE category_id = ?)',
      );
      whereArgs.add(categoryId);
    }

    final whereClause = 'WHERE ${whereConditions.join(' AND ')}';

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(si.quantity * si.price_per_unit), 0.0) AS total
      FROM sales s
      JOIN sale_items si ON s.id = si.sale_id
      LEFT JOIN product_variants pv ON si.variant_id = pv.id
      $whereClause
    ''', whereArgs);

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get returns total for a date range
  Future<double> returnsTotalByDate({
    required String startIso,
    required String endIso,
    int? userId,
  }) async {
    final db = await _dbHelper.database;

    final whereConditions = <String>['r.created_at >= ?', 'r.created_at <= ?'];
    final whereArgs = <dynamic>[startIso, endIso];

    if (userId != null) {
      whereConditions.add('r.user_id = ?');
      whereArgs.add(userId);
    }

    final whereClause = 'WHERE ${whereConditions.join(' AND ')}';

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(ri.quantity * ri.price_per_unit), 0.0) AS total
      FROM returns r
      JOIN return_items ri ON r.id = ri.return_id
      $whereClause
    ''', whereArgs);

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Get stock status report
  Future<List<Map<String, Object?>>> stockStatus({
    int? categoryId,
    bool? lowStockOnly,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;

    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (categoryId != null) {
      whereConditions.add('pp.category_id = ?');
      whereArgs.add(categoryId);
    }

    if (lowStockOnly == true) {
      whereConditions.add(
        'pv.quantity <= pv.reorder_point AND pv.reorder_point > 0',
      );
    }

    final whereClause = whereConditions.isEmpty
        ? ''
        : 'WHERE ${whereConditions.join(' AND ')}';

    final result = await db.rawQuery(
      '''
      SELECT
        pv.id,
        pv.sku,
        pp.name AS product_name,
        pv.quantity,
        pv.reorder_point,
        pv.cost_price,
        pv.sale_price,
        c.name AS category_name,
        b.name AS brand_name
      FROM product_variants pv
      JOIN parent_products pp ON pv.parent_product_id = pp.id
      LEFT JOIN categories c ON pp.category_id = c.id
      LEFT JOIN brands b ON pp.brand_id = b.id
      $whereClause
      ORDER BY pv.quantity ASC, pp.name ASC
      LIMIT ? OFFSET ?
    ''',
      [...whereArgs, limit, offset],
    );

    return result;
  }

  /// Get customer count
  Future<int> customerCount() async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM customers');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Get inventory count
  Future<int> inventoryCount() async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM product_variants',
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
