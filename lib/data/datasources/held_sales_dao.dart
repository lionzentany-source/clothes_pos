import 'dart:convert';

import 'package:clothes_pos/core/db/database_helper.dart';

class HeldSalesDao {
  final DatabaseHelper _dbHelper;
  HeldSalesDao(this._dbHelper);

  Future<int> insertHeldSale(
    String name,
    String ts,
    List<Map<String, Object?>> items,
  ) async {
    final db = await _dbHelper.database;
    return db.transaction<int>((txn) async {
      final id = await txn.insert('held_sales', {'name': name, 'ts': ts});
      for (final it in items) {
        final attributesRaw = it['attributes'];
        String? encodedAttributes;
        if (attributesRaw == null) {
          encodedAttributes = null;
        } else if (attributesRaw is String) {
          // assume already serialized; try to decode then re-encode to canonical shape
          try {
            final decoded = json.decode(attributesRaw);
            if (decoded is Map) {
              // convert legacy map to array-of-objects
              final arr = decoded.entries
                  .map((e) => {'id': null, 'name': e.key, 'value': e.value})
                  .toList();
              encodedAttributes = jsonEncode(arr);
            } else if (decoded is List) {
              encodedAttributes = jsonEncode(decoded);
            } else {
              encodedAttributes = null;
            }
          } catch (_) {
            encodedAttributes = null;
          }
        } else if (attributesRaw is Map) {
          final arr = attributesRaw.entries
              .map((e) => {'id': null, 'name': e.key, 'value': e.value})
              .toList();
          encodedAttributes = jsonEncode(arr);
        } else if (attributesRaw is List) {
          encodedAttributes = jsonEncode(attributesRaw);
        } else {
          encodedAttributes = null;
        }

        await txn.insert('held_sale_items', {
          'held_sale_id': id,
          'variant_id': it['variant_id'],
          'quantity': it['quantity'],
          'price': it['price'],
          'attributes': encodedAttributes,
          'price_override': it['price_override'],
        });
      }
      return id;
    });
  }

  Future<List<Map<String, Object?>>> listHeldSalesSummary() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT h.id, h.name, h.ts, COUNT(i.id) AS items_count
      FROM held_sales h
      LEFT JOIN held_sale_items i ON i.held_sale_id = h.id
      GROUP BY h.id
      ORDER BY h.id DESC
    ''');
    return rows;
  }

  Future<List<Map<String, Object?>>> itemsForHeldSale(int heldId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'held_sale_items',
      where: 'held_sale_id = ?',
      whereArgs: [heldId],
      orderBy: 'id ASC',
    );
    return rows;
  }

  Future<void> deleteHeldSale(int id) async {
    final db = await _dbHelper.database;
    await db.delete('held_sales', where: 'id = ?', whereArgs: [id]);
    // items are deleted by cascade if supported; ensure cleanup
    await db.delete(
      'held_sale_items',
      where: 'held_sale_id = ?',
      whereArgs: [id],
    );
  }
}
