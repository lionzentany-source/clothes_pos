import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  sqfliteFfiInit();
  final dbName = 'clothes_pos.db';
  final dbPath = p.join(
    p.current,
    '.dart_tool',
    'sqflite_common_ffi',
    'databases',
    dbName,
  );
  final db = await databaseFactoryFfi.openDatabase(dbPath);
  try {
    final attrs = await db.rawQuery('SELECT id, name FROM attributes');
    final values = await db.rawQuery(
      'SELECT id, attribute_id, value FROM attribute_values',
    );
    final links = await db.rawQuery(
      'SELECT variant_id, attribute_value_id FROM variant_attributes',
    );
    print('attributes (${attrs.length}):');
    for (final r in attrs) {
      print(r);
    }
    print('\nattribute_values (${values.length}):');
    for (final r in values) {
      print(r);
    }
    print('\nvariant_attributes (${links.length}):');
    for (final r in links) {
      print(r);
    }
  } finally {
    await db.close();
  }
}