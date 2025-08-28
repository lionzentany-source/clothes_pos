import 'package:clothes_pos/core/db/database_helper.dart';

class ReturnLineInput {
  final int saleItemId;
  final int variantId;
  final int quantity; // qty to return
  final double refundAmount;
  ReturnLineInput({required this.saleItemId, required this.variantId, required this.quantity, required this.refundAmount});
}

class ReturnsDao {
  final DatabaseHelper _dbHelper;
  ReturnsDao(this._dbHelper);

  Future<List<Map<String, Object?>>> getReturnableItems(int saleId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT 
        si.id AS sale_item_id,
        si.variant_id,
        si.quantity AS sold_qty,
        si.price_per_unit,
        COALESCE(r.ret_qty, 0) AS returned_qty,
        (si.quantity - COALESCE(r.ret_qty, 0)) AS remaining_qty
      FROM sale_items si
      INNER JOIN sales s ON s.id = si.sale_id
      LEFT JOIN (
        SELECT sri.sale_item_id, SUM(sri.quantity) AS ret_qty
        FROM sales_return_items sri
        INNER JOIN sales_returns sr ON sr.id = sri.sales_return_id
        WHERE sr.sale_id = ?
        GROUP BY sri.sale_item_id
      ) r ON r.sale_item_id = si.id
      WHERE si.sale_id = ?
      ORDER BY si.id ASC
    ''', [saleId, saleId]);
    return rows;
  }

  Future<int> createReturn({
    required int saleId,
    required int userId,
    String? reason,
    required List<ReturnLineInput> items,
  }) async {
    final db = await _dbHelper.database;
    return db.transaction<int>((txn) async {
      // Validate quantities (use the same transaction for reads)
      final remainingRows = await txn.rawQuery('''
        SELECT
          si.id AS sale_item_id,
          (si.quantity - COALESCE(r.ret_qty, 0)) AS remaining_qty
        FROM sale_items si
        LEFT JOIN (
          SELECT sri.sale_item_id, SUM(sri.quantity) AS ret_qty
          FROM sales_return_items sri
          INNER JOIN sales_returns sr ON sr.id = sri.sales_return_id
          WHERE sr.sale_id = ?
          GROUP BY sri.sale_item_id
        ) r ON r.sale_item_id = si.id
        WHERE si.sale_id = ?
      ''', [saleId, saleId]);
      final remainingMap = <int, int>{}; // sale_item_id -> remaining
      for (final r in remainingRows) {
        remainingMap[r['sale_item_id'] as int] = (r['remaining_qty'] as num).toInt();
      }
      for (final it in items) {
        final rem = remainingMap[it.saleItemId] ?? 0;
        if (it.quantity < 1 || it.quantity > rem) {
          throw Exception('كمية مرتجع غير صالحة للبند ${it.saleItemId}');
        }
      }

      final returnId = await txn.insert('sales_returns', {
        'sale_id': saleId,
        'user_id': userId,
        'reason': reason,
      });

      double totalRefund = 0;
      for (final it in items) {
        totalRefund += it.refundAmount;
        await txn.insert('sales_return_items', {
          'sales_return_id': returnId,
          'sale_item_id': it.saleItemId,
          'variant_id': it.variantId,
          'quantity': it.quantity,
          'refund_amount': it.refundAmount,
        });
        await txn.insert('inventory_movements', {
          'variant_id': it.variantId,
          'qty_change': it.quantity,
          'movement_type': 'RETURN',
          'reference_type': 'RETURN',
          'reference_id': returnId,
          'reason': reason,
        });
        await txn.rawUpdate(
          'UPDATE product_variants SET quantity = quantity + ? WHERE id = ?',
          [it.quantity, it.variantId],
        );
      }

      if (totalRefund > 0) {
        await txn.insert('payments', {
          'sale_id': saleId,
          'amount': totalRefund,
          'method': 'REFUND',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return returnId;
    });
  }
}

