import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TestDb {
  static Future<Database> open() async {
    // Initialize FFI for tests
    if (!kIsWeb) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 14,
      onCreate: (db, version) async {
        // Minimal schema required for tests; in real tests you can load full SQL from assets
        await db.execute(
          'CREATE TABLE sales (id INTEGER PRIMARY KEY AUTOINCREMENT, total_amount REAL NOT NULL, sale_date TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE sale_items (id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER NOT NULL, variant_id INTEGER NOT NULL, quantity INTEGER NOT NULL, price_per_unit REAL NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE inventory_movements (id INTEGER PRIMARY KEY AUTOINCREMENT, variant_id INTEGER NOT NULL, qty_change INTEGER NOT NULL, movement_type TEXT NOT NULL)',
        );
      },
    );
    return db;
  }
}
