import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

String _stamp() {
  final t = DateTime.now().toUtc();
  return '${t.year}${t.month.toString().padLeft(2, '0')}${t.day.toString().padLeft(2, '0')}_${t.hour.toString().padLeft(2, '0')}${t.minute.toString().padLeft(2, '0')}${t.second.toString().padLeft(2, '0')}';
}

String normalizeValue(String columnName, String v) {
  var s = v.trim();
  if (s.isEmpty) return s;
  s = s.replaceAll(RegExp(r"\s+"), ' ');
  if (columnName == 'size') {
    final lower = s.toLowerCase();
    final sizeMap = {
      'small': 'S',
      's': 'S',
      'medium': 'M',
      'm': 'M',
      'large': 'L',
      'l': 'L',
    };
    if (sizeMap.containsKey(lower)) return sizeMap[lower]!;
    final numNorm = lower.replaceAll(RegExp(r"\.0+\$"), '');
    return numNorm.toUpperCase();
  }
  if (columnName == 'color') {
    final lower = s.toLowerCase();
    final colorMap = {
      'أحمر': 'أحمر',
      'الأحمر': 'أحمر',
      'red': 'Red',
      'blue': 'Blue',
      'أسود': 'أسود',
    };
    if (colorMap.containsKey(lower)) return colorMap[lower]!;
    return s[0].toUpperCase() + s.substring(1);
  }
  return s;
}

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
  final outDir = Directory(p.join(p.current, 'backups', 'migration_reports'));
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final stamp = _stamp();
  final extractedFile = File(
    p.join(outDir.path, 'extracted_values_$stamp.csv'),
  );
  final plannedFile = File(p.join(outDir.path, 'planned_inserts_$stamp.csv'));

  final db = await databaseFactoryFfi.openDatabase(dbPath);
  try {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );

    final Map<String, Set<String>> extractedSizes = {};
    final Map<String, Set<String>> extractedColors = {};

    for (final t in tables) {
      final table = t['name'] as String;
      final cols = await db.rawQuery('PRAGMA table_info("$table")');
      for (final c in cols) {
        final colName = c['name'] as String;
        final type = ((c['type'] as String?) ?? '').toLowerCase();
        if (!(type.contains('text') ||
            type.contains('char') ||
            type == '' ||
            colName.toLowerCase().contains('description') ||
            colName.toLowerCase().contains('name') ||
            colName.toLowerCase().contains('details'))) {
          continue;
        }
        final rows = await db.rawQuery(
          'SELECT $colName AS v, ROWID AS rid FROM $table LIMIT 1000',
        );
        for (final r in rows) {
          final v = r['v'];
          if (v is! String) continue;
          final s = v;
          // JSON key patterns
          final jsonSize = RegExp(
            r'"size"\s*:\s*"([^"]+)"'
            , caseSensitive: false,
          ).firstMatch(s);
          if (jsonSize != null) {
            extractedSizes
                .putIfAbsent('$table.$colName', () => {})
                .add(jsonSize.group(1)!.trim());
          }
          final jsonColor = RegExp(
            r'"color"\s*:\s*"([^"]+)"'
            , caseSensitive: false,
          ).firstMatch(s);
          if (jsonColor != null) {
            extractedColors
                .putIfAbsent('$table.$colName', () => {})
                .add(jsonColor.group(1)!.trim());
          }
          // key:value patterns
          final kvSize = RegExp(
            r'\bsize\s*[:=]\s*([A-Za-z0-9\-\u0600-\u06FF\s]+)',
            caseSensitive: false,
          ).firstMatch(s);
          if (kvSize != null) {
            extractedSizes
                .putIfAbsent('$table.$colName', () => {})
                .add(kvSize.group(1)!.trim());
          }
          final kvColor = RegExp(
            r'\bcolor\s*[:=]\s*([A-Za-z0-9\-\u0600-\u06FF\s]+)',
            caseSensitive: false,
          ).firstMatch(s);
          if (kvColor != null) {
            extractedColors
                .putIfAbsent('$table.$colName', () => {})
                .add(kvColor.group(1)!.trim());
          }
          // Arabic keywords
          final arSize = RegExp(r'المقاس\s*[:\-]\s*([^,;\n]+)').firstMatch(s);
          if (arSize != null) {
            extractedSizes
                .putIfAbsent('$table.$colName', () => {})
                .add(arSize.group(1)!.trim());
          }
          final arColor = RegExp(r'اللون\s*[:\-]\s*([^,;\n]+)').firstMatch(s);
          if (arColor != null) {
            extractedColors
                .putIfAbsent('$table.$colName', () => {})
                .add(arColor.group(1)!.trim());
          }
          // slash-separated tokens
          final slashParts = s.split(RegExp(r'[\/|]'));
          if (slashParts.length >= 2) {
            for (final part in slashParts) {
              final tkn = part.trim();
              if (tkn.length <= 4 &&
                  RegExp(
                    r'^[A-Za-z0-9]+$',
                  ).hasMatch(tkn.substring(0, tkn.length))) {
                continue;
              }
              // heuristics: if token matches known size words
              final low = tkn.toLowerCase();
              if ([ 
                's',
                'm',
                'l',
                'small',
                'medium',
                'large',
                'xs',
                'xl',
                'xxl',
              ].contains(low)) {
                extractedSizes
                    .putIfAbsent('$table.$colName', () => {})
                    .add(tkn);
              } else if ([ 
                'red',
                'blue',
                'green',
                'black',
                'white',
                'أحمر',
                'أزرق',
                'أسود',
                'أبيض',
                'أسود',
              ].contains(low)) {
                extractedColors
                    .putIfAbsent('$table.$colName', () => {})
                    .add(tkn);
              }
            }
          }
        }
      }
    }

    // Write extracted_values CSV
    final exSink = extractedFile.openWrite();
    exSink.writeln('attribute,source_column,distinct_count,samples');
    final plannedInserts = <Map<String, String>>[];

    void writeExtracted(Map<String, Set<String>> map, String attribute) {
      for (final entry in map.entries) {
        final src = entry.key;
        final vals = entry.value.where((v) => v.trim().isNotEmpty).toList();
        final samples = vals
            .take(10)
            .map((v) => '"${v.replaceAll('"', '""')}"')
            .join('|');
        exSink.writeln('$attribute,$src,${vals.length},$samples');
        for (final v in vals) {
          final norm = normalizeValue(attribute, v);
          plannedInserts.add({
            'attribute': attribute,
            'value': v,
            'normalized': norm,
            'source': src,
          });
        }
      }
    }

    writeExtracted(extractedSizes, 'size');
    writeExtracted(extractedColors, 'color');
    await exSink.flush();
    await exSink.close();

    // Write planned inserts CSV (dedupe by attribute+normalized)
    final dedup = <String, Map<String, String>>{};
    for (final p in plannedInserts) {
      final key = '${p['attribute']}::${p['normalized']}';
      dedup.putIfAbsent(key, () => p);
    }
    final planSink = plannedFile.openWrite();
    planSink.writeln(
      'attribute,normalized_value,example_raw_value,source_column',
    );
    for (final v in dedup.values) {
      planSink.writeln(
        '${v['attribute']},"${v['normalized']}","${v['value']}",${v['source']}',
      );
    }
    await planSink.flush();
    await planSink.close();

    print('Extraction complete. Files:');
    print(' - ${extractedFile.path}');
    print(' - ${plannedFile.path}');
    print('Found ${dedup.length} planned normalized inserts (dry-run).');
  } finally {
    await db.close();
  }
}
