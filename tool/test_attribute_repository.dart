import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// path not required here
import 'package:clothes_pos/data/attributes/attribute_repository.dart';
import 'package:clothes_pos/data/attributes/attribute_dao.dart';

Future<void> main(List<String> args) async {
  sqfliteFfiInit();
  final useReal = args.contains('--db');
  String dbPath;
  Database db;
  if (useReal) {
    dbPath = args
        .firstWhere((a) => a.startsWith('--db='), orElse: () => '')
        .split('=')[1];
    if (!File(dbPath).existsSync()) {
      stderr.writeln('DB not found: $dbPath');
      exit(1);
    }
    db = await databaseFactoryFfi.openDatabase(dbPath);
  } else {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    // create minimal schema
    await db.execute('''
      CREATE TABLE attributes (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE NOT NULL);
    ''');
    await db.execute('''
      CREATE TABLE attribute_values (id INTEGER PRIMARY KEY AUTOINCREMENT, attribute_id INTEGER NOT NULL, value TEXT NOT NULL);
    ''');
    await db.execute('''
      CREATE TABLE variant_attributes (variant_id INTEGER NOT NULL, attribute_value_id INTEGER NOT NULL);
    ''');
  }

  final repo = AttributeRepository(AttributeDao());
  print('Ensuring attribute Size...');
  final attrId = await repo.ensureAttributeByName(db, 'Size');
  print('Size id = $attrId');

  print('Adding value M for Size...');
  final valId = await repo.addValueForAttribute(db, 'Size', 'M');
  print('attribute_value id = $valId');

  print('Linking variant 101 -> value');
  await repo.link(db, 101, 'Size', 'M');
  final rows = await db.query('variant_attributes');
  print('variant_attributes rows: ${rows.length}');

  await db.close();
  print('Test complete.');
}