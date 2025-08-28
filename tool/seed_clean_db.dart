import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  sqfliteFfiInit();
  final dbFactory = databaseFactoryFfi;
  final dbPath = File('backups/clothes_pos_clean.db').absolute.path;
  // Ensure DB exists (create minimal schema if missing)
  final db = await dbFactory.openDatabase(dbPath, options: OpenDatabaseOptions(version: 1, onCreate: (db, version) async {
    // Reuse minimal schema from create_clean_db
    await db.execute('''
      CREATE TABLE parent_products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand_id INTEGER,
        category_id INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE product_variants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parent_product_id INTEGER NOT NULL,
        sku TEXT,
        barcode TEXT,
        quantity INTEGER DEFAULT 0,
        sale_price REAL DEFAULT 0,
        reorder_point INTEGER DEFAULT 0,
        rfid_tag TEXT,
        FOREIGN KEY(parent_product_id) REFERENCES parent_products(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE brands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE attributes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      );
    ''');

    await db.execute('''
      CREATE TABLE attribute_values (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attribute_id INTEGER NOT NULL,
        value TEXT NOT NULL,
        FOREIGN KEY(attribute_id) REFERENCES attributes(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE variant_attributes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        variant_id INTEGER NOT NULL,
        attribute_value_id INTEGER NOT NULL,
        FOREIGN KEY(variant_id) REFERENCES product_variants(id),
        FOREIGN KEY(attribute_value_id) REFERENCES attribute_values(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE product_variant_rfids (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        variant_id INTEGER NOT NULL,
        epc TEXT NOT NULL,
        FOREIGN KEY(variant_id) REFERENCES product_variants(id)
      );
    ''');
  }));

  // Insert a brand
  final brandId = await db.insert('brands', {'name': 'Acme Apparel'});

  // Insert a parent product
  final parentId = await db.insert('parent_products', {
    'name': 'Classic Tee',
    'brand_id': brandId,
    'category_id': null,
  });

  // Insert two variants
  final variant1Id = await db.insert('product_variants', {
    'parent_product_id': parentId,
    'sku': 'CT-001-M-RED',
    'barcode': '1234567890123',
    'quantity': 10,
    'sale_price': 19.99,
    'reorder_point': 5,
    'rfid_tag': null,
  });

  final variant2Id = await db.insert('product_variants', {
    'parent_product_id': parentId,
    'sku': 'CT-002-L-BLUE',
    'barcode': '1234567890124',
    'quantity': 7,
    'sale_price': 21.99,
    'reorder_point': 3,
    'rfid_tag': null,
  });

  // Insert attributes (Size, Color)
  final sizeAttrId = await db.insert('attributes', {'name': 'Size'});
  final colorAttrId = await db.insert('attributes', {'name': 'Color'});

  // Insert attribute values
  final sizeMId = await db.insert('attribute_values', {'attribute_id': sizeAttrId, 'value': 'M'});
  final sizeLId = await db.insert('attribute_values', {'attribute_id': sizeAttrId, 'value': 'L'});
  final colorRedId = await db.insert('attribute_values', {'attribute_id': colorAttrId, 'value': 'Red'});
  final colorBlueId = await db.insert('attribute_values', {'attribute_id': colorAttrId, 'value': 'Blue'});

  // Link variant attributes
  await db.insert('variant_attributes', {'variant_id': variant1Id, 'attribute_value_id': sizeMId});
  await db.insert('variant_attributes', {'variant_id': variant1Id, 'attribute_value_id': colorRedId});

  await db.insert('variant_attributes', {'variant_id': variant2Id, 'attribute_value_id': sizeLId});
  await db.insert('variant_attributes', {'variant_id': variant2Id, 'attribute_value_id': colorBlueId});

  print('Seeded clean DB at: $dbPath');
  print('brandId: $brandId parentId: $parentId variants: $variant1Id, $variant2Id');

  await db.close();
}
