import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AttributeDao {
  /// Ensure attribute exists; return id (existing or newly created).
  Future<int> ensureAttribute(Database db, String name) async {
    final rows = await db.query(
      'attributes',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (rows.isNotEmpty) return rows.first['id'] as int;
    return await db.insert('attributes', {'name': name});
  }

  Future<int?> getAttributeId(Database db, String name) async {
    final rows = await db.query(
      'attributes',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (rows.isEmpty) return null;
    return rows.first['id'] as int;
  }

  Future<int> ensureAttributeValue(
    Database db,
    int attributeId,
    String value,
  ) async {
    final rows = await db.query(
      'attribute_values',
      where: 'attribute_id = ? AND value = ?',
      whereArgs: [attributeId, value],
    );
    if (rows.isNotEmpty) return rows.first['id'] as int;
    try {
      return await db.insert('attribute_values', {
        'attribute_id': attributeId,
        'value': value,
      });
    } catch (e) {
      // In case of a UNIQUE constraint race, select the existing id
      final existing = await db.query(
        'attribute_values',
        where: 'attribute_id = ? AND value = ?',
        whereArgs: [attributeId, value],
        limit: 1,
      );
      if (existing.isNotEmpty) return existing.first['id'] as int;
      rethrow;
    }
  }

  Future<void> linkVariantAttribute(
    Database db,
    int variantId,
    int attributeValueId,
  ) async {
    final exists = await db.query(
      'variant_attributes',
      where: 'variant_id = ? AND attribute_value_id = ?',
      whereArgs: [variantId, attributeValueId],
    );
    if (exists.isNotEmpty) return;
    await db.insert('variant_attributes', {
      'variant_id': variantId,
      'attribute_value_id': attributeValueId,
    });
  }
}
