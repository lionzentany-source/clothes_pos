// ignore_for_file: avoid_print
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  sqfliteFfiInit();
  final repoRoot = Directory.current.path;
  final dbDir = p.join(
    repoRoot,
    '.dart_tool',
    'sqflite_common_ffi',
    'databases',
  );
  Directory(dbDir).createSync(recursive: true);
  final dbPath = p.join(dbDir, 'clothes_pos.db');

  final db = await databaseFactoryFfi.openDatabase(dbPath);
  final schema = File(p.join(repoRoot, 'assets', 'db', 'schema.sql'));
  if (!schema.existsSync()) {
    stderr.writeln('schema.sql not found at ${schema.path}');
    exit(2);
  }
  final sql = schema.readAsStringSync();
  final statements = sql.split(';');
  for (final s in statements) {
    final st = s.trim();
    if (st.isNotEmpty) {
      try {
        await db.execute(st);
      } catch (e) {
        // ignore partial errors
      }
    }
  }
  await db.close();
  print('Created DB at $dbPath');
}
