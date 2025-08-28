import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

String _now() => DateTime.now().toUtc().toIso8601String();

Future<String?> _findLatestPlannedFile(Directory dir) async {
  if (!dir.existsSync()) return null;
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => p.basename(f.path).startsWith('planned_inserts_'))
      .toList();
  if (files.isEmpty) return null;
  files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  return files.first.path;
}

Future<void> main(List<String> args) async {
  sqfliteFfiInit();
  final cwd = p.current;
  final reportsDir = Directory(p.join(cwd, 'backups', 'migration_reports'));
  final plannedPathArg = args.firstWhere(
    (a) => a.startsWith('--csv='),
    orElse: () => '',
  );
  final dryRun = args.contains('--dry-run') || !args.contains('--apply');
  final doBackup = args.contains('--backup');

  String? plannedPath;
  if (plannedPathArg.isNotEmpty) plannedPath = plannedPathArg.split('=')[1];
  plannedPath ??= await _findLatestPlannedFile(reportsDir);
  if (plannedPath == null) {
    stderr.writeln(
      'No planned_inserts_*.csv found in ${reportsDir.path}. Use --csv=path to specify.',
    );
    exit(1);
  }

  final dbName = 'clothes_pos.db';
  String? dbArg;
  for (final a in args) if (a.startsWith('--db=')) dbArg = a.split('=')[1];
  final dbPath = dbArg != null && dbArg.isNotEmpty
      ? dbArg
      : p.join(cwd, '.dart_tool', 'sqflite_common_ffi', 'databases', dbName);
  if (!File(dbPath).existsSync()) {
    stderr.writeln('Database not found at $dbPath');
    exit(1);
  }

  if (doBackup) {
    final backupsDir = Directory(p.join(cwd, 'backups'));
    if (!backupsDir.existsSync()) backupsDir.createSync(recursive: true);
    final dest = p.join(
      backupsDir.path,
      'clothes_pos_db_backup_${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}.db',
    );
    File(dbPath).copySync(dest);
    print('Backup created at $dest');
  }

  final auditFile = File(
    p.join(
      reportsDir.path,
      'commit_audit_${DateTime.now().toUtc().toIso8601String().replaceAll(':', '-')}.csv',
    ),
  );
  final auditSink = auditFile.openWrite();
  auditSink.writeln(
    'timestamp_utc,action,attribute,normalized_value,raw_value,source,notes',
  );

  final db = await databaseFactoryFfi.openDatabase(dbPath);
  try {
    final planned = File(plannedPath).readAsLinesSync();
    if (planned.length <= 1) {
      print('Planned file has no rows to process: $plannedPath');
    }
    // parse CSV lines skipping header
    for (var i = 1; i < planned.length; i++) {
      final line = planned[i];
      if (line.trim().isEmpty) continue;
      // attribute,normalized_value,example_raw_value,source_column
      // naive CSV parse (we produced simple CSV)
      final parts = line.split(',');
      if (parts.length < 4) continue;
      final attribute = parts[0];
      final normalized = parts[1].replaceAll('"', '').trim();
      final raw = parts[2].replaceAll('"', '').trim();
      final source = parts.sublist(3).join(',');

      // get or create attribute id
      final attrRows = await db.query(
        'attributes',
        where: 'name = ?',
        whereArgs: [attribute],
      );
      int attrId;
      if (attrRows.isNotEmpty) {
        attrId = attrRows.first['id'] as int;
      } else {
        if (dryRun) {
          print('[dry-run] would create attribute $attribute');
          auditSink.writeln(
            '${_now()},would_create_attribute,$attribute, , ,$source,dry-run',
          );
          continue;
        } else {
          attrId = await db.insert('attributes', {'name': attribute});
          auditSink.writeln(
            '${_now()},created_attribute,$attribute, , ,$source,ok',
          );
        }
      }

      // check attribute_values
      final valRows = await db.query(
        'attribute_values',
        where: 'attribute_id = ? AND value = ?',
        whereArgs: [attrId, normalized],
      );
      if (valRows.isEmpty) {
        if (dryRun) {
          print(
            '[dry-run] would insert attribute_value($attribute) = $normalized (example: $raw)',
          );
          auditSink.writeln(
            '${_now()},would_insert_value,$attribute,$normalized,${raw.replaceAll(',', ' ')},$source,dry-run',
          );
        } else {
          final id = await db.insert('attribute_values', {
            'attribute_id': attrId,
            'value': normalized,
          });
          auditSink.writeln(
            '${_now()},inserted_value,$attribute,$normalized,${raw.replaceAll(',', ' ')},$source,ok_id=$id',
          );
        }
      } else {
        auditSink.writeln(
          '${_now()},skipped_existing_value,$attribute,$normalized,${raw.replaceAll(',', ' ')},$source,exists',
        );
      }
    }

    await auditSink.flush();
    await auditSink.close();
    print('Audit written to ${auditFile.path}');
  } finally {
    await db.close();
  }
}
