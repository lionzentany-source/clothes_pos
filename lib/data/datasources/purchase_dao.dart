import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/models/purchase_invoice.dart';
import 'package:clothes_pos/data/models/purchase_invoice_item.dart';

class PurchaseDao {
  final DatabaseHelper _dbHelper;
  PurchaseDao(this._dbHelper);

  Future<int> insertInvoice(
    PurchaseInvoice invoice,
    List<PurchaseInvoiceItem> items,
  ) async {
    final db = await _dbHelper.database;
    return db.transaction<int>((txn) async {
      final invoiceId = await txn.insert('purchase_invoices', invoice.toMap());
      double total = 0;
      for (final it in items) {
        final m = it.toMap();
        m['purchase_invoice_id'] = invoiceId;
        total += it.costPrice * it.quantity;
        await txn.insert('purchase_invoice_items', m);
        // IN movement + update variant qty & cost
        await txn.insert('inventory_movements', {
          'variant_id': it.variantId,
          'qty_change': it.quantity,
          'movement_type': 'IN',
          'reference_type': 'PURCHASE',
          'reference_id': invoiceId,
        });
        await txn.rawUpdate(
          'UPDATE product_variants SET quantity = quantity + ?, cost_price = ? WHERE id = ?',
          [it.quantity, it.costPrice, it.variantId],
        );
      }
      await txn.update(
        'purchase_invoices',
        {'total_cost': total},
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
      return invoiceId;
    });
  }

  // Insert invoice and also attach RFID EPCs per item inside the same transaction
  Future<int> insertInvoiceWithRfids(
    PurchaseInvoice invoice,
    List<PurchaseInvoiceItem> items,
    List<List<String>> rfidsByItem,
  ) async {
    final db = await _dbHelper.database;
    return db.transaction<int>((txn) async {
      final invoiceId = await txn.insert('purchase_invoices', invoice.toMap());
      double total = 0;
      for (var i = 0; i < items.length; i++) {
        final it = items[i];
        final m = it.toMap();
        m['purchase_invoice_id'] = invoiceId;
        total += it.costPrice * it.quantity;
        await txn.insert('purchase_invoice_items', m);
        // IN movement + update variant qty & cost
        await txn.insert('inventory_movements', {
          'variant_id': it.variantId,
          'qty_change': it.quantity,
          'movement_type': 'IN',
          'reference_type': 'PURCHASE',
          'reference_id': invoiceId,
        });
        await txn.rawUpdate(
          'UPDATE product_variants SET quantity = quantity + ?, cost_price = ? WHERE id = ?',
          [it.quantity, it.costPrice, it.variantId],
        );
        // Attach EPCs (ignore duplicates)
        if (i < rfidsByItem.length) {
          for (final epc in rfidsByItem[i]) {
            if (epc.trim().isEmpty) continue;
            await txn.rawInsert(
              'INSERT OR IGNORE INTO product_variant_rfids(variant_id, epc) VALUES(?, ?)',
              [it.variantId, epc.trim()],
            );
          }
        }
      }
      await txn.update(
        'purchase_invoices',
        {'total_cost': total},
        where: 'id = ?',
        whereArgs: [invoiceId],
      );
      return invoiceId;
    });
  }

  Future<List<PurchaseInvoice>> listInvoices({
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'purchase_invoices',
      limit: limit,
      offset: offset,
      orderBy: 'id DESC',
    );
    return rows.map((e) => PurchaseInvoice.fromMap(e)).toList();
  }

  Future<List<PurchaseInvoiceItem>> itemsForInvoice(int invoiceId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'purchase_invoice_items',
      where: 'purchase_invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return rows.map((e) => PurchaseInvoiceItem.fromMap(e)).toList();
  }
}
