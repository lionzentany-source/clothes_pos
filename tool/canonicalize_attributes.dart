// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

/// Canonicalize attributes stored in TEXT columns into an array-of-objects
/// shape: [{ "id": null, "name": "Size", "value": "M" }, ...]
///
/// Usage:
/// dart run tool/canonicalize_attributes.dart --dry-run
/// dart run tool/canonicalize_attributes.dart --commit --db=/path/to/db
/// Optional: --sample=100 to only process first N rows in each table

Future<void> main(List<String> args) async {
  var dryRun = true;
  int? sampleLimit;
  if (args.contains('--commit')) dryRun = false;
  for (final a in args) {
    if (a == '--dry-run') dryRun = true;
    if (a.startsWith('--sample=')) {
      final parts = a.split('=');
      if (parts.length == 2) sampleLimit = int.tryParse(parts[1]);
    }
  }

  print('[canonicalize] dryRun=$dryRun sampleLimit=$sampleLimit');

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
    exit(1);
  }

  final db = await databaseFactoryFfi.openDatabase(dbPath);
  try {
    await _processTable(db, 'sale_items', sampleLimit, dryRun);
    await _processTable(db, 'held_sale_items', sampleLimit, dryRun);
    print('Canonicalization complete.');
  } finally {
    await db.close();
  }
}

Future<void> _processTable(
  Database db,
  String table,
  int? sampleLimit,
  bool dryRun,
) async {
  // Ensure the table actually has an `attributes` column before querying it.
  try {
    final pragma = await db.rawQuery("PRAGMA table_info('$table')");
    final columnNames = pragma
        .map((r) => (r['name'] ?? '').toString())
        .toList();
    if (!columnNames.contains('attributes')) {
      print('[canonicalize] Skipping $table: no attributes column');
      return;
    }
  } catch (e) {
    stderr.writeln('[canonicalize] Could not inspect table $table: $e');
    return;
  }

  // Select rows that have a non-null attributes column
  final limitClause = sampleLimit != null ? 'LIMIT $sampleLimit' : '';
  final rows = await db.rawQuery(
    'SELECT id, attributes FROM $table WHERE attributes IS NOT NULL $limitClause',
  );
  print(
    '[canonicalize] Found ${rows.length} rows in $table with attributes (sampleLimit=$sampleLimit)',
  );

  for (final r in rows) {
    final id = r['id'];
    final raw = r['attributes'];
    if (raw == null) continue;
    String? current;
    if (raw is String) {
      current = raw;
    } else {
      current = jsonEncode(raw);
    }

    // Try to decode and decide if conversion is needed
    bool needsConversion = false;
    List<dynamic>? targetArray;
    try {
      final dec = json.decode(current);
      if (dec is Map) {
        // convert map -> array
        targetArray = dec.entries
            .map((e) => {'id': null, 'name': e.key, 'value': e.value})
            .toList();
        needsConversion = true;
      } else if (dec is List) {
        // already an array; ensure elements are objects with name/value when possible
        final normalized = <dynamic>[];
        var changed = false;
        for (final e in dec) {
          if (e is String) {
            normalized.add({'id': null, 'name': e, 'value': e});
            changed = true;
          } else if (e is Map) {
            // If map has 'name' and 'value' assume ok
            if (e.containsKey('name') && e.containsKey('value')) {
              normalized.add(e);
            } else if (e.containsKey('value') && e.length == 1) {
              normalized.add({
                'id': null,
                'name': e['value'],
                'value': e['value'],
              });
              changed = true;
            } else {
              normalized.add(e);
            }
          } else {
            normalized.add(e);
          }
        }
        if (changed) {
          targetArray = normalized;
          needsConversion = true;
        }
      } else {
        // unknown shape: attempt to store as single value
        targetArray = [
          {'id': null, 'name': dec.toString(), 'value': dec.toString()},
        ];
        needsConversion = true;
      }
    } catch (_) {
      // not json - store as single-string attribute
      targetArray = [
        {'id': null, 'name': current, 'value': current},
      ];
      needsConversion = true;
    }

    if (needsConversion && targetArray != null) {
      final encoded = jsonEncode(targetArray);
      print('[canonicalize] $table id=$id: will update attributes -> $encoded');
      if (!dryRun) {
        await db.update(
          table,
          {'attributes': encoded},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
  }
}
