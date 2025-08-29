import 'package:clothes_pos/core/config/feature_flags.dart';
import 'package:clothes_pos/data/datasources/attribute_dao.dart';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/models/parent_product.dart';
import 'package:clothes_pos/data/models/attribute.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';

class ProductDao {
  final DatabaseHelper _dbHelper;
  final AttributeDao _attributeDao;
  ProductDao(this._dbHelper, this._attributeDao);

  // Parent products CRUD
  Future<int> insertParentProduct(ParentProduct p) async {
    final db = await _dbHelper.database;
    return db.insert('parent_products', p.toMap());
  }

  Future<int> updateParentProduct(ParentProduct p) async {
    final db = await _dbHelper.database;
    return db.update(
      'parent_products',
      p.toMap(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  Future<int> deleteParentProduct(int id) async {
    final db = await _dbHelper.database;
    return db.delete('parent_products', where: 'id = ?', whereArgs: [id]);
  }

  Future<ParentProduct?> getParentById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'parent_products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ParentProduct.fromMap(rows.first);
  }

  /// Load parent product and its assigned parent-level attributes (if dynamic attributes enabled)
  Future<Map<String, Object?>> getParentWithAttributes(int id) async {
    final db = await _dbHelper.database;
    final parentRow = await db.query(
      'parent_products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (parentRow.isEmpty) return {};
    final attrs = <Map<String, Object?>>[];
    if (FeatureFlags.useDynamicAttributes) {
      final rows = await db.rawQuery(
        'SELECT a.* FROM attributes a JOIN parent_attributes pa ON pa.attribute_id = a.id WHERE pa.parent_id = ? ORDER BY a.id ASC',
        [id],
      );
      attrs.addAll(rows);
    }
    return {'parent': parentRow.first, 'attributes': attrs};
  }

  Future<List<ParentProduct>> searchParentsByName(
    String q, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'parent_products',
      where: 'name LIKE ?',
      whereArgs: ['%$q%'],
      limit: limit,
      offset: offset,
      orderBy: 'id DESC',
    );
    return rows.map((e) => ParentProduct.fromMap(e)).toList();
  }

  // Variants CRUD
  Future<int> insertVariant(ProductVariant v) async {
    final db = await _dbHelper.database;
    return db.insert('product_variants', v.toMap());
  }

  Future<int> updateVariant(ProductVariant v) async {
    final db = await _dbHelper.database;
    return db.update(
      'product_variants',
      v.toMap(),
      where: 'id = ?',
      whereArgs: [v.id],
    );
  }

  Future<void> updateSalePrice({
    required int variantId,
    required double salePrice,
  }) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE product_variants SET sale_price = ? WHERE id = ?',
      [salePrice, variantId],
    );
  }

  Future<int> deleteVariant(int id) async {
    final db = await _dbHelper.database;
    return db.delete('product_variants', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ProductVariant>> getVariantsByParent(int parentId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'product_variants',
      where: 'parent_product_id = ?',
      whereArgs: [parentId],
    );

    if (!FeatureFlags.useDynamicAttributes) {
      return rows.map((e) => ProductVariant.fromMap(e)).toList();
    }

    final variants = <ProductVariant>[];
    for (final row in rows) {
      final variant = ProductVariant.fromMap(row);
      final attributeValues = await _attributeDao.getAttributeValuesForVariant(
        variant.id!,
      );
      variants.add(variant.copyWith(attributes: attributeValues));
    }
    return variants;
  }

  Future<List<ProductVariant>> searchVariants({
    String? name,
    String? sku,
    String? barcode,
    String? rfidTag,
    int? brandId,
    int? categoryId,
    int limit = 20,
    int offset = 0,
  }) async {
    final rows = await searchVariantRows(
      name: name,
      sku: sku,
      barcode: barcode,
      rfidTag: rfidTag,
      brandId: brandId,
      categoryId: categoryId,
      limit: limit,
      offset: offset,
    );
    return rows.map((e) => ProductVariant.fromMap(e)).toList();
  }

  Future<List<Map<String, Object?>>> searchVariantRows({
    String? name,
    String? sku,
    String? barcode,
    String? rfidTag,
    int? brandId,
    int? categoryId,
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <Object?>[];

    if (name != null && name.isNotEmpty) {
      if (FeatureFlags.useDynamicAttributes) {
        where.add(
          '('
          'pp.name LIKE ? OR '
          'pv.sku LIKE ? OR '
          'b.name LIKE ? OR '
          'EXISTS ('
          '  SELECT 1 FROM variant_attributes va '
          '  JOIN attribute_values av ON va.attribute_value_id = av.id '
          '  WHERE va.variant_id = pv.id AND av.value LIKE ?'
          ')'
          ')',
        );
        args.addAll(['%$name%', '%$name%', '%$name%', '%$name%']);
      } else {
        where.add(
          '('
          'pp.name LIKE ? OR '
          'pv.sku LIKE ? OR '
          'b.name LIKE ? OR '
          'pv.size LIKE ? OR '
          'pv.color LIKE ?'
          ')',
        );
        args.addAll(['%$name%', '%$name%', '%$name%', '%$name%', '%$name%']);
      }
    }
    if (sku != null && sku.isNotEmpty) {
      where.add('pv.sku LIKE ?');
      args.add('%$sku%');
    }
    if (barcode != null && barcode.isNotEmpty) {
      where.add('pv.barcode LIKE ?');
      args.add('%$barcode%');
    }
    if (rfidTag != null && rfidTag.isNotEmpty) {
      // Check both legacy single-tag column and new multi-tag table
      where.add(
        '('
        'pv.rfid_tag = ? OR EXISTS (SELECT 1 FROM product_variant_rfids r WHERE r.variant_id = pv.id AND r.epc = ?)'
        ')',
      );
      args.addAll([rfidTag, rfidTag]);
    }
    if (brandId != null) {
      where.add('pp.brand_id = ?');
      args.add(brandId);
    }
    if (categoryId != null) {
      where.add('pp.category_id = ?');
      args.add(categoryId);
    }

    final whereClause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';

    final rows = await db.rawQuery(
      '''
  SELECT pv.*, pp.name AS parent_name, pp.category_id AS category_id, b.name AS brand_name
      FROM product_variants pv
      LEFT JOIN parent_products pp ON pv.parent_product_id = pp.id
      LEFT JOIN brands b ON pp.brand_id = b.id
      $whereClause
      ORDER BY pv.id DESC
      LIMIT ? OFFSET ?
      ''',
      [...args, limit, offset],
    );
    return rows;
  }

  Future<Map<String, Object?>?> getVariantRowById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '''
  SELECT pv.*, pp.name AS parent_name, pp.category_id AS category_id, b.name AS brand_name
      FROM product_variants pv
      LEFT JOIN parent_products pp ON pv.parent_product_id = pp.id
      LEFT JOIN brands b ON pp.brand_id = b.id
      WHERE pv.id = ?
      LIMIT 1
      ''',
      [id],
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Bulk fetch variant rows by ids
  Future<List<Map<String, Object?>>> getVariantRowsByIds(List<int> ids) async {
    if (ids.isEmpty) return <Map<String, Object?>>[];
    final db = await _dbHelper.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.rawQuery('''
  SELECT pv.*, pp.name AS parent_name, pp.category_id AS category_id, b.name AS brand_name
      FROM product_variants pv
      LEFT JOIN parent_products pp ON pv.parent_product_id = pp.id
      LEFT JOIN brands b ON pp.brand_id = b.id
      WHERE pv.id IN ($placeholders)
      ''', ids);
    return rows;
  }

  /// Bulk fetch variants with attribute values populated (when dynamic attributes enabled)
  Future<List<ProductVariant>> getVariantsByIds(List<int> ids) async {
    final rows = await getVariantRowsByIds(ids);
    final variants = rows.map((r) => ProductVariant.fromMap(r)).toList();
    if (!FeatureFlags.useDynamicAttributes || variants.isEmpty) return variants;

    // Bulk load attribute values for all variants
    final vidList = variants.map((v) => v.id!).toList();
    final avMap = await _attributeDao.getAttributeValuesForVariantIds(vidList);
    final populated = <ProductVariant>[];
    for (final v in variants) {
      final attrs = avMap[v.id!] ?? <AttributeValue>[];
      populated.add(v.copyWith(attributes: attrs));
    }
    return populated;
  }

  Future<ProductVariant?> getVariantWithAttributesById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'product_variants',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final variant = ProductVariant.fromMap(rows.first);

    if (!FeatureFlags.useDynamicAttributes) {
      return variant;
    }

    final attributeValues = await _attributeDao.getAttributeValuesForVariant(
      variant.id!,
    );
    return variant.copyWith(attributes: attributeValues);
  }

  Future<List<ProductVariant>> getLowStockVariants({
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT * FROM product_variants
      WHERE reorder_point > 0 AND quantity <= reorder_point
      ORDER BY (reorder_point - quantity) DESC
      LIMIT ? OFFSET ?
      ''',
      [limit, offset],
    );
    return rows.map((e) => ProductVariant.fromMap(e)).toList();
  }

  // RFID multi-tag helpers
  Future<void> addRfidTag({required int variantId, required String epc}) async {
    final db = await _dbHelper.database;
    await db.rawInsert(
      'INSERT OR IGNORE INTO product_variant_rfids(variant_id, epc) VALUES(?, ?)',
      [variantId, epc],
    );
  }

  Future<void> removeRfidTag({required String epc}) async {
    final db = await _dbHelper.database;
    await db.rawDelete('DELETE FROM product_variant_rfids WHERE epc = ?', [
      epc,
    ]);
  }

  Future<List<String>> listRfidTags(int variantId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT epc FROM product_variant_rfids WHERE variant_id = ? ORDER BY id ASC',
      [variantId],
    );
    return rows.map((e) => e['epc'] as String).toList();
  }

  // Bulk create/update
  Future<int> createProductWithVariants(
    ParentProduct p,
    List<ProductVariant> vs, [
    List<Attribute>? parentAttributes,
  ]) async {
    try {
      AppLogger.d(
        '[ProductDao.createProductWithVariants] Start creating product: ${p.name}',
      );
      AppLogger.d(
        '[ProductDao.createProductWithVariants] Parent product data: ${p.toMap()}',
      );
      AppLogger.d(
        '[ProductDao.createProductWithVariants] Number of variants: ${vs.length}',
      );

      final db = await _dbHelper.database;

      // Check parent_products table structure
      final parentColumns = await db.rawQuery(
        'PRAGMA table_info(parent_products)',
      );
      AppLogger.d(
        '[ProductDao.createProductWithVariants] parent_products columns: $parentColumns',
      );

      // Check product_variants table structure
      final variantColumns = await db.rawQuery(
        'PRAGMA table_info(product_variants)',
      );
      AppLogger.d(
        '[ProductDao.createProductWithVariants] product_variants columns: $variantColumns',
      );

      return await db.transaction<int>((txn) async {
        AppLogger.d(
          '[ProductDao.createProductWithVariants] Inserting parent product...',
        );
        final parentId = await txn.insert('parent_products', p.toMap());
        AppLogger.d(
          '[ProductDao.createProductWithVariants] Parent product created with ID: $parentId',
        );

        // persist parent-level attributes mapping if provided
        if (parentAttributes != null && parentAttributes.isNotEmpty) {
          await txn.delete(
            'parent_attributes',
            where: 'parent_id = ?',
            whereArgs: [parentId],
          );
          for (final a in parentAttributes) {
            if (a.id != null) {
              await txn.insert('parent_attributes', {
                'parent_id': parentId,
                'attribute_id': a.id,
              });
            }
          }
        }

        for (int i = 0; i < vs.length; i++) {
          final v = vs[i];
          final m = v.toMap();
          m['parent_product_id'] = parentId;
          AppLogger.d(
            '[ProductDao.createProductWithVariants] image_path for variant $i: ${m['image_path']}',
          );
          AppLogger.d(
            '[ProductDao.createProductWithVariants] Inserting variant $i: $m',
          );
          final variantId = await txn.insert('product_variants', m);
          AppLogger.d(
            '[ProductDao.createProductWithVariants] Variant $i inserted successfully with ID: $variantId',
          );

          if (FeatureFlags.useDynamicAttributes) {
            if (v.attributes != null) {
              for (final attributeValue in v.attributes!) {
                await txn.insert('variant_attributes', {
                  'variant_id': variantId,
                  'attribute_value_id': attributeValue.id,
                });
              }
            }
          }
        }

        AppLogger.d(
          '[ProductDao.createProductWithVariants] Transaction completed successfully, returning parentId: $parentId',
        );
        return parentId;
      });
    } catch (e, st) {
      AppLogger.e(
        '[ProductDao.createProductWithVariants] ERROR: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> updateProductAndVariants(
    ParentProduct p,
    List<ProductVariant> vs, [
    List<Attribute>? parentAttributes,
  ]) async {
    final db = await _dbHelper.database;
    await db.transaction<void>((txn) async {
      // تحديث بيانات المنتج الرئيسي
      await txn.update(
        'parent_products',
        p.toMap(),
        where: 'id = ?',
        whereArgs: [p.id],
      );

      // Update parent-level attributes mapping if provided
      if (parentAttributes != null) {
        await txn.delete(
          'parent_attributes',
          where: 'parent_id = ?',
          whereArgs: [p.id],
        );
        for (final a in parentAttributes) {
          if (a.id != null) {
            await txn.insert('parent_attributes', {
              'parent_id': p.id,
              'attribute_id': a.id,
            });
          }
        }
      }

      // جلب جميع المتغيرات القديمة لهذا المنتج
      final oldVariants = await txn.query(
        'product_variants',
        where: 'parent_product_id = ?',
        whereArgs: [p.id],
      );
      final oldIds = oldVariants.map((e) => e['id'] as int).toSet();
      final newIds = vs.where((v) => v.id != null).map((v) => v.id!).toSet();

      // حذف المتغيرات التي تم حذفها من واجهة المستخدم (غير موجودة في vs)
      for (final oldId in oldIds.difference(newIds)) {
        // حاول الحذف، إذا كان هناك ارتباطات سيظهر خطأ ولن يتم الحذف
        await txn.delete(
          'product_variants',
          where: 'id = ?',
          whereArgs: [oldId],
        );
      }

      // تحديث أو إدراج المتغيرات الجديدة
      for (final v in vs) {
        final m = v.toMap();
        m['parent_product_id'] = p.id;
        int variantId;
        if (v.id != null && oldIds.contains(v.id)) {
          // تحديث المتغير الموجود
          await txn.update(
            'product_variants',
            m,
            where: 'id = ?',
            whereArgs: [v.id],
          );
          variantId = v.id!;
        } else {
          // إدراج متغير جديد
          variantId = await txn.insert('product_variants', m);
        }

        if (FeatureFlags.useDynamicAttributes) {
          // Clear existing attributes for the variant
          await txn.delete(
            'variant_attributes',
            where: 'variant_id = ?',
            whereArgs: [variantId],
          );
          // Insert new attributes
          if (v.attributes != null) {
            for (final attributeValue in v.attributes!) {
              await txn.insert('variant_attributes', {
                'variant_id': variantId,
                'attribute_value_id': attributeValue.id,
              });
            }
          }
        }
      }
    });
  }

  Future<List<String>> distinctSizes({int limit = 100}) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT size FROM product_variants WHERE size IS NOT NULL AND TRIM(size) <> \'\' ORDER BY size COLLATE NOCASE ASC LIMIT ?',
      [limit],
    );
    return rows.map((e) => (e['size'] as String).trim()).toList();
  }

  Future<List<String>> distinctColors({int limit = 100}) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT color FROM product_variants WHERE color IS NOT NULL AND TRIM(color) <> \'\' ORDER BY color COLLATE NOCASE ASC LIMIT ?',
      [limit],
    );
    return rows.map((e) => (e['color'] as String).trim()).toList();
  }

  Future<List<String>> distinctBrands({int limit = 100}) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT b.name AS brand FROM parent_products pp LEFT JOIN brands b ON pp.brand_id = b.id WHERE b.name IS NOT NULL AND TRIM(b.name) <> \'\' ORDER BY b.name COLLATE NOCASE ASC LIMIT ?',
      [limit],
    );
    return rows.map((e) => (e['brand'] as String).trim()).toList();
  }
}
