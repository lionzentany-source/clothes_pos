import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/models/attribute.dart';

class AttributeDao {
  final DatabaseHelper _dbHelper;

  AttributeDao(this._dbHelper);

  Future<List<Attribute>> getAllAttributes() async {
    final db = await _dbHelper.database;
    final maps = await db.query('attributes');
    return maps.map((map) => Attribute.fromMap(map)).toList();
  }

  Future<Attribute> getAttributeById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('attributes', where: 'id = ?', whereArgs: [id]);
    return Attribute.fromMap(maps.first);
  }

  Future<int> createAttribute(Attribute attribute) async {
    final db = await _dbHelper.database;
    // Prevent UNIQUE constraint failures by returning existing id if name exists
    final existing = await db.query(
      'attributes',
      where: 'name = ?',
      whereArgs: [attribute.name],
      limit: 1,
    );
    if (existing.isNotEmpty) return existing.first['id'] as int;

    return await db.insert('attributes', attribute.toMap());
  }

  Future<int> updateAttribute(Attribute attribute) async {
    final db = await _dbHelper.database;
    return await db.update(
      'attributes',
      attribute.toMap(),
      where: 'id = ?',
      whereArgs: [attribute.id],
    );
  }

  Future<int> deleteAttribute(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('attributes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<AttributeValue>> getAttributeValues(int attributeId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'attribute_values',
      where: 'attribute_id = ?',
      whereArgs: [attributeId],
    );
    return maps.map((map) => AttributeValue.fromMap(map)).toList();
  }

  Future<int> createAttributeValue(AttributeValue value) async {
    final db = await _dbHelper.database;
    return await db.insert('attribute_values', value.toMap());
  }

  Future<int> updateAttributeValue(AttributeValue value) async {
    final db = await _dbHelper.database;
    return await db.update(
      'attribute_values',
      value.toMap(),
      where: 'id = ?',
      whereArgs: [value.id],
    );
  }

  Future<int> deleteAttributeValue(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'attribute_values',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<AttributeValue>> getAttributeValuesForVariant(
    int variantId,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery(
      '''
      SELECT av.*
      FROM attribute_values av
      INNER JOIN variant_attributes va ON av.id = va.attribute_value_id
      WHERE va.variant_id = ?
    ''',
      [variantId],
    );
    return maps.map((map) => AttributeValue.fromMap(map)).toList();
  }

  /// Bulk fetch attribute values for multiple variant ids and group them by variant id.
  Future<Map<int, List<AttributeValue>>> getAttributeValuesForVariantIds(
    List<int> variantIds,
  ) async {
    final result = <int, List<AttributeValue>>{};
    if (variantIds.isEmpty) return result;
    final db = await _dbHelper.database;
    final placeholders = List.filled(variantIds.length, '?').join(',');
    final maps = await db.rawQuery('''
      SELECT av.*, va.variant_id as variant_id
      FROM attribute_values av
      INNER JOIN variant_attributes va ON av.id = va.attribute_value_id
      WHERE va.variant_id IN ($placeholders)
      ORDER BY va.variant_id ASC, av.id ASC
    ''', variantIds);
    for (final row in maps) {
      final variantId = row['variant_id'] as int;
      final avMap = Map<String, Object?>.from(row)..remove('variant_id');
      final av = AttributeValue.fromMap(avMap);
      result.putIfAbsent(variantId, () => <AttributeValue>[]).add(av);
    }
    return result;
  }
}
