import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';
import 'package:sqflite/sqflite.dart';

class LegacyAttributesMigrator {
  final DatabaseHelper _dbHelper;
  final bool dryRun;
  final int? sampleLimit;

  /// If [dryRun] is true the migrator will only log the actions it would take
  /// and will not perform insert/update operations.
  LegacyAttributesMigrator(
    this._dbHelper, {
    this.dryRun = true,
    this.sampleLimit,
  });

  Future<void> migrate() async {
    AppLogger.i(
      'Starting legacy attributes migration... dryRun=$dryRun sampleLimit=$sampleLimit',
    );
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // Step 1: Add "size" and "color" to attributes table
      final sizeAttributeId = await _insertAttribute(txn, 'Size');
      final colorAttributeId = await _insertAttribute(txn, 'Color');

      // Step 2: Read unique size and color values and add to attribute_values
      await _migrateUniqueValues(txn, 'size', sizeAttributeId);
      await _migrateUniqueValues(txn, 'color', colorAttributeId);

      // Step 3: Link product_variants to variant_attributes
      await _linkVariantAttributes(txn, sizeAttributeId, colorAttributeId);
    });

    AppLogger.i('Legacy attributes migration completed. dryRun=$dryRun');
  }

  Future<int> _insertAttribute(Transaction txn, String name) async {
    final existing = await txn.query(
      'attributes',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }
    AppLogger.d('[Migrator] Will insert attribute: $name');
    if (dryRun) return -1; // return a sentinel for dry-run
    return await txn.insert('attributes', {'name': name});
  }

  Future<void> _migrateUniqueValues(
    Transaction txn,
    String columnName,
    int attributeId,
  ) async {
    final sql =
        "SELECT DISTINCT $columnName FROM product_variants WHERE $columnName IS NOT NULL AND $columnName != ''";
    final List<Map<String, dynamic>> uniqueValues = await txn.rawQuery(sql);

    for (final row in uniqueValues) {
      final value = row[columnName];
      if (value != null) {
        final existing = await txn.query(
          'attribute_values',
          where: 'attribute_id = ? AND value = ?',
          whereArgs: [attributeId, value],
        );
        if (existing.isEmpty) {
          AppLogger.d(
            '[Migrator] Will insert attribute_value: attribute_id=$attributeId value=$value',
          );
          if (!dryRun) {
            await txn.insert('attribute_values', {
              'attribute_id': attributeId,
              'value': value,
            });
          }
        }
      }
    }
  }

  Future<void> _linkVariantAttributes(
    Transaction txn,
    int sizeAttributeId,
    int colorAttributeId,
  ) async {
    final List<Map<String, dynamic>> variants = await txn.query(
      'product_variants',
      columns: ['id', 'size', 'color'],
      limit: sampleLimit,
    );

    for (final variant in variants) {
      final variantId = variant['id'] as int;
      final size = variant['size'];
      final color = variant['color'];

      if (size is String && size.trim().isNotEmpty) {
        final sizeValueId = await _getAttributeValueId(
          txn,
          sizeAttributeId,
          size,
        );
        if (sizeValueId != null) {
          await _insertVariantAttribute(txn, variantId, sizeValueId);
        }
      }

      if (color is String && color.trim().isNotEmpty) {
        final colorValueId = await _getAttributeValueId(
          txn,
          colorAttributeId,
          color,
        );
        if (colorValueId != null) {
          await _insertVariantAttribute(txn, variantId, colorValueId);
        }
      }
    }
  }

  Future<int?> _getAttributeValueId(
    Transaction txn,
    int attributeId,
    String value,
  ) async {
    final result = await txn.query(
      'attribute_values',
      columns: ['id'],
      where: 'attribute_id = ? AND value = ?',
      whereArgs: [attributeId, value],
    );
    return result.isNotEmpty ? result.first['id'] as int : null;
  }

  Future<void> _insertVariantAttribute(
    Transaction txn,
    int variantId,
    int attributeValueId,
  ) async {
    // Check if already exists to prevent duplicates on re-run
    final existing = await txn.query(
      'variant_attributes',
      where: 'variant_id = ? AND attribute_value_id = ?',
      whereArgs: [variantId, attributeValueId],
    );
    if (existing.isEmpty) {
      AppLogger.d(
        '[Migrator] Will insert variant_attribute variant_id=$variantId attribute_value_id=$attributeValueId',
      );
      if (!dryRun) {
        await txn.insert('variant_attributes', {
          'variant_id': variantId,
          'attribute_value_id': attributeValueId,
        });
      }
    }
  }
}
