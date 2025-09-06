// ignore_for_file: avoid_print
// Small tool to create a clean dev DB without legacy size/color columns.
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main(List<String> args) async {
  sqfliteFfiInit();
  final dbFactory = databaseFactoryFfi;

  // Use a canonical backups path to avoid nested .dart_tool resolution issues
  final dbDir = Directory('backups');
  if (!dbDir.existsSync()) dbDir.createSync(recursive: true);
  final dbPath = File('${dbDir.path}/clothes_pos_clean.db').absolute.path;

  // Remove existing clean DB if present to start fresh
  final f = File(dbPath);
  if (f.existsSync()) {
    print('Removing existing DB at $dbPath');
    f.deleteSync();
  }

  final db = await dbFactory.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        // Minimal schema without 'size' and 'color' columns
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
      },
    ),
  );

  print('Created clean DB at: $dbPath');
  await db.close();
}
