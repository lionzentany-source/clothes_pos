// ignore_for_file: avoid_print
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main(List<String> args) async {
  // Usage: dart run tool/query_variant_attributes.dart [variantId] [dbPath]
  final variantId = args.isNotEmpty ? int.tryParse(args[0]) ?? 1 : 1;
  final dbPath = args.length > 1 ? args[1] : 'backups/clothes_pos_clean.db';
  sqfliteFfiInit();
  final dbFactory = databaseFactoryFfi;

  final resolvedPath = File(dbPath).absolute.path;
  if (!File(resolvedPath).existsSync()) {
    print('DB not found at $resolvedPath');
    exit(1);
  }

  final db = await dbFactory.openDatabase(resolvedPath);

  try {
    final rows = await db.rawQuery(
      '''
      SELECT va.variant_id AS variant_id, a.name AS attribute, av.value AS value
      FROM variant_attributes va
      JOIN attribute_values av ON va.attribute_value_id = av.id
      JOIN attributes a ON av.attribute_id = a.id
      WHERE va.variant_id = ?
      ORDER BY a.name ASC
    ''',
      [variantId],
    );

    if (rows.isEmpty) {
      print('No attributes linked to variant $variantId');
    } else {
      print('Attributes for variant $variantId:');
      for (final r in rows) {
        print('- ${r['attribute']}: ${r['value']}');
      }
    }
  } catch (e) {
    print('Query failed: $e');
    print('Listing tables in DB for diagnostics:');
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
    );
    for (final t in tables) {
      print('- ${t['name']}');
    }
  }

  await db.close();
}
