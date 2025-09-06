// ignore_for_file: avoid_print
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  sqfliteFfiInit();
  String? dbArg;
  for (final a in args) {
    if (a.startsWith('--db=')) dbArg = a.split('=')[1];
  }
  final dbPath = dbArg != null && dbArg.isNotEmpty
      ? dbArg
      : p.join(
          p.current,
          '.dart_tool',
          'sqflite_common_ffi',
          'databases',
          'clothes_pos.db',
        );

  if (!File(dbPath).existsSync()) {
    stderr.writeln('Database not found at $dbPath');
    exit(2);
  }

  final db = await databaseFactoryFfi.openDatabase(dbPath);
  try {
    print('DB: $dbPath');
    final tables = await db.rawQuery(
      "SELECT name, type FROM sqlite_master WHERE type IN ('table','view') ORDER BY name",
    );
    print('\nTables (name,type):');
    for (final t in tables) {
      print(' - ${t['name']} (${t['type']})');
    }

    Future<void> showTable(String table) async {
      print('\nPRAGMA table_info($table):');
      try {
        final cols = await db.rawQuery('PRAGMA table_info($table)');
        if (cols.isEmpty) {
          print('  <no such table or no columns>');
          return;
        }
        for (final c in cols) {
          print(
            '  - ${c['name']} (${c['type']}) pk=${c['pk']} notnull=${c['notnull']} dflt=${c['dflt_value']}',
          );
        }
      } catch (e) {
        print('  ERROR reading PRAGMA for $table: $e');
      }
    }

    // Show product_variants specifically, plus attributes-related tables if present
    await showTable('product_variants');
    await showTable('attributes');
    await showTable('attribute_values');
    await showTable('variant_attributes');
  } finally {
    await db.close();
  }
}
