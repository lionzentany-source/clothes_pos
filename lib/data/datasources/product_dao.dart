import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/models/parent_product.dart';
import 'package:clothes_pos/data/models/product_variant.dart';

class ProductDao {
  final DatabaseHelper _dbHelper;
  ProductDao(this._dbHelper);

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
    return rows.map((e) => ProductVariant.fromMap(e)).toList();
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
    List<ProductVariant> vs,
  ) async {
    final db = await _dbHelper.database;
    return db.transaction<int>((txn) async {
      final parentId = await txn.insert('parent_products', p.toMap());
      for (final v in vs) {
        final m = v.toMap();
        m['parent_product_id'] = parentId;
        await txn.insert('product_variants', m);
      }
      return parentId;
    });
  }

  Future<void> updateProductAndVariants(
    ParentProduct p,
    List<ProductVariant> vs,
  ) async {
    final db = await _dbHelper.database;
    await db.transaction<void>((txn) async {
      await txn.update(
        'parent_products',
        p.toMap(),
        where: 'id = ?',
        whereArgs: [p.id],
      );
      await txn.delete(
        'product_variants',
        where: 'parent_product_id = ?',
        whereArgs: [p.id],
      );
      for (final v in vs) {
        final m = v.toMap();
        m['parent_product_id'] = p.id;
        await txn.insert('product_variants', m);
      }
    });
  }

  Future<List<String>> distinctSizes({int limit = 100}) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT size FROM product_variants WHERE size IS NOT NULL AND TRIM(size) <> '' ORDER BY size COLLATE NOCASE ASC LIMIT ?",
      [limit],
    );
    return rows.map((e) => (e['size'] as String).trim()).toList();
  }

  Future<List<String>> distinctColors({int limit = 100}) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT color FROM product_variants WHERE color IS NOT NULL AND TRIM(color) <> '' ORDER BY color COLLATE NOCASE ASC LIMIT ?",
      [limit],
    );
    return rows.map((e) => (e['color'] as String).trim()).toList();
  }

  Future<List<String>> distinctBrands({int limit = 100}) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT b.name AS brand FROM parent_products pp LEFT JOIN brands b ON pp.brand_id = b.id WHERE b.name IS NOT NULL AND TRIM(b.name) <> '' ORDER BY b.name COLLATE NOCASE ASC LIMIT ?",
      [limit],
    );
    return rows.map((e) => (e['brand'] as String).trim()).toList();
  }
}
