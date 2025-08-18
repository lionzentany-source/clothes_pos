import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/models/payment.dart';
import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';

class SalesDao {
  final DatabaseHelper _dbHelper;
  SalesDao(this._dbHelper);

  Future<int> createSale({
    required Sale sale,
    required List<SaleItem> items,
    required List<Payment> payments,
  }) async {
    final db = await _dbHelper.database;
    return db.transaction<int>((txn) async {
      // prevent negative stock: check all first
      for (final it in items) {
        final rows = await txn.rawQuery(
          'SELECT quantity FROM product_variants WHERE id = ?',
          [it.variantId],
        );
        if (rows.isEmpty) throw Exception('Variant not found: ${it.variantId}');
        final qty = rows.first['quantity'] as int;
        if (qty < it.quantity) {
          throw Exception('Insufficient stock for variant ${it.variantId}');
        }
      }

      final saleId = await txn.insert('sales', sale.toMap());
      double total = 0;
      for (final it in items) {
        total += it.pricePerUnit * it.quantity;
        final m = it.toMap();
        m['sale_id'] = saleId;
        await txn.insert('sale_items', m);
        // OUT movement & decrement stock
        await txn.insert('inventory_movements', {
          'variant_id': it.variantId,
          'qty_change': -it.quantity,
          'movement_type': 'OUT',
          'reference_type': 'SALE',
          'reference_id': saleId,
        });
        await txn.rawUpdate(
          'UPDATE product_variants SET quantity = quantity - ? WHERE id = ?',
          [it.quantity, it.variantId],
        );
      }
      await txn.update(
        'sales',
        {'total_amount': total},
        where: 'id = ?',
        whereArgs: [saleId],
      );

      for (final p in payments) {
        final m = p.toMap();
        m['sale_id'] = saleId;
        await txn.insert('payments', m);
        // If cash payment and has session, add cash IN movement
        if (p.method == PaymentMethod.cash && p.cashSessionId != null) {
          await txn.insert('cash_movements', {
            'cash_session_id': p.cashSessionId,
            'amount': p.amount,
            'movement_type': 'IN',
            'reason': 'SALE #$saleId',
          });
        }
      }
      return saleId;
    });
  }

  Future<List<SaleItem>> itemsForSale(int saleId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return rows.map((e) => SaleItem.fromMap(e)).toList();
  }

  Future<Sale> getSale(int saleId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [saleId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw Exception('Sale not found: $saleId');
    }
    return Sale.fromMap(rows.first);
  }

  Future<List<Payment>> paymentsForSale(int saleId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'payments',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return rows.map((e) => Payment.fromMap(e)).toList();
  }

  Future<List<Map<String, Object?>>> itemRowsForSale(int saleId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT si.*, pv.sku, pv.size, pv.color, pp.name AS parent_name, b.name AS brand_name
      FROM sale_items si
      JOIN product_variants pv ON si.variant_id = pv.id
      LEFT JOIN parent_products pp ON pv.parent_product_id = pp.id
      LEFT JOIN brands b ON pp.brand_id = b.id
      WHERE si.sale_id = ?
      ORDER BY si.id ASC
    ''',
      [saleId],
    );
    return rows;
  }
}
