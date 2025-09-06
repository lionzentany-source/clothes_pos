// ignore_for_file: avoid_print
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  sqfliteFfiInit();
  String? dbArg;
  for (final a in args) {
    if (a.startsWith('--db=')) {
      dbArg = a.split('=')[1];
    }
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
    print('DB: $dbPath');

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );
    print('\nFound ${tables.length} tables:');
    for (final t in tables) {
      print(" - ${t['name']}");
    }

    final suspects = <String>[];

    for (final t in tables) {
      final table = t['name'] as String;
      final cols = await db.rawQuery('PRAGMA table_info("$table")');
      for (final c in cols) {
        final colName = (c['name'] as String).toLowerCase();
        if (colName.contains('size') || colName.contains('color')) {
          suspects.add('$table.$colName');
        }
      }
    }

    print('\nSuspected columns (contain "size" or "color"):');
    for (final s in suspects) {
      print(' - $s');
    }

    if (suspects.isEmpty) {
      print('\nNo obvious columns found.');
    }

    // For each suspect, count non-null/non-empty
    for (final s in suspects) {
      final parts = s.split('.');
      final table = parts[0];
      final col = parts[1];
      final countRes = await db.rawQuery(
        'SELECT COUNT(*) AS cnt FROM $table WHERE $col IS NOT NULL AND TRIM($col) != ""',
      );
      final cnt = (countRes.first['cnt'] as int?) ?? 0;
      print('\n$cnt rows non-empty in $table.$col');

      // sample values
      final samples = await db.rawQuery(
        'SELECT DISTINCT $col AS v FROM $table WHERE $col IS NOT NULL AND TRIM($col) != "" LIMIT 20',
      );
      print('Sample distinct values (up to 20):');
      for (final r in samples) {
        print('  - ${r['v']}');
      }
    }
    // Always scan TEXT-like columns for JSON-like occurrences (to catch hidden storage)
    print(
      '\nScanning TEXT-like columns for JSON-like occurrences of size/color (sample rows)...',
    );
    for (final t in tables) {
      final table = t['name'] as String;
      final cols = await db.rawQuery('PRAGMA table_info("$table")');
      for (final c in cols) {
        final colName = c['name'] as String;
        final type = ((c['type'] as String?) ?? '').toLowerCase();
        if (type.contains('text') || type.contains('varchar') || type == '') {
          // sample up to 200 rows for the column
          final rows = await db.rawQuery(
            'SELECT $colName AS v FROM $table LIMIT 200',
          );
          var hits = 0;
          for (final r in rows) {
            final v = r['v'];
            if (v is String &&
                (v.toLowerCase().contains('"size"') ||
                    v.toLowerCase().contains('size:') ||
                    v.toLowerCase().contains('"color"') ||
                    v.toLowerCase().contains('color:') ||
                    v.contains('المقاس') ||
                    v.contains('اللون'))) {
              hits++;
              if (hits <= 5) {
                final excerpt = v.length > 120
                    ? '${v.substring(0, 120)}...'
                    : v;
                print('Found in $table.$colName (excerpt): $excerpt');
              }
            }
          }
          if (hits > 0) {
            print('-> $hits hits in sample of $table.$colName');
          }
        }
      }
    }

    print('\nDiscovery complete.');
  } finally {
    await db.close();
  }
}
