import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

String _nowStamp() {
  final dt = DateTime.now().toUtc();
  return '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}_${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}${dt.second.toString().padLeft(2, '0')}';
}

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
    exit(1);
  }

  final outDir = Directory(p.join(p.current, 'backups', 'migration_reports'));
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final outFile = File(
    p.join(outDir.path, 'dynamic_attributes_discovery_${_nowStamp()}.csv'),
  );

  final db = await databaseFactoryFfi.openDatabase(dbPath);
  try {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );

    final sink = outFile.openWrite();
    sink.writeln('table,column,non_empty_count,distinct_sample_values');

    for (final t in tables) {
      final table = t['name'] as String;
      final cols = await db.rawQuery('PRAGMA table_info("$table")');
      for (final c in cols) {
        final colName = c['name'] as String;
        final type = ((c['type'] as String?) ?? '').toLowerCase();
        if (colName.toLowerCase().contains('size') ||
            colName.toLowerCase().contains('color') ||
            type.contains('text') ||
            type.contains('char') ||
            type == '') {
          final countRes = await db.rawQuery(
            'SELECT COUNT(*) AS cnt FROM $table WHERE $colName IS NOT NULL AND TRIM($colName) != ""',
          );
          final cnt = (countRes.first['cnt'] as int?) ?? 0;
          final samples = await db.rawQuery(
            'SELECT DISTINCT $colName AS v FROM $table WHERE $colName IS NOT NULL AND TRIM($colName) != "" LIMIT 10',
          );
          final sampleList = samples
              .map(
                (r) => '"${(r['v'] ?? '').toString().replaceAll('"', '""')}"',
              )
              .join('|');
          sink.writeln('$table,$colName,$cnt,$sampleList');
        }
      }
    }

    await sink.flush();
    await sink.close();
    print('Report written to ${outFile.path}');
  } finally {
    await db.close();
  }
}
