// ignore_for_file: avoid_print
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

/// Standalone migration runner that works without Flutter.
/// Usage:
/// dart run tool/migrate_runner.dart --dry-run --sample=50
/// dart run tool/migrate_runner.dart --commit

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

  print('[migrate_runner] dryRun=$dryRun sampleLimit=$sampleLimit');

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
  if (!File(dbPath).existsSync()) {
    stderr.writeln('Database not found at $dbPath');
    exit(1);
  }

  final db = await databaseFactoryFfi.openDatabase(dbPath);
  try {
    // Step 1: ensure attributes exist and get their ids
    final synonyms = <String, List<String>>{
      'Size': ['Size', 'المقاس'],
      'Color': ['Color', 'اللون'],
    };

    final sizeAttrId = await _getOrCreateAttribute(
      db,
      synonyms['Size']!,
      dryRun,
    );
    final colorAttrId = await _getOrCreateAttribute(
      db,
      synonyms['Color']!,
      dryRun,
    );

    // If user asked for report-only (print CSV of planned operations) we will
    // collect planned inserts/links and print as CSV at the end. (not used yet)

    // Step 2: migrate unique values (respect sample if provided by limiting source rows)
    await _migrateUniqueValues(db, 'size', sizeAttrId, dryRun, sampleLimit);
    await _migrateUniqueValues(db, 'color', colorAttrId, dryRun, sampleLimit);

    // Step 3: link variants
    await _linkVariantAttributes(
      db,
      sizeAttrId,
      colorAttrId,
      dryRun,
      sampleLimit,
    );
    // Optional: run attributes canonicalizer as part of the migration if requested
    if (args.contains('--canonicalize')) {
      // ignore: avoid_print$([Environment]::NewLine)
      // ignore: avoid_print$([Environment]::NewLine)
      print(
        '[migrate_runner] Running attributes canonicalizer (dryRun=$dryRun sampleLimit=$sampleLimit)',
      );
      final procArgs = <String>['run', 'tool/canonicalize_attributes.dart'];
      procArgs.add(dryRun ? '--dry-run' : '--commit');
      if (sampleLimit != null) procArgs.add('--sample=$sampleLimit');
      if (dbArg != null && dbArg.isNotEmpty) procArgs.add('--db=$dbArg');
      // Ensure we run via `dart run` so the tool can use package imports
      final res = await Process.run('dart', procArgs, runInShell: true);
      if (res.stdout != null && (res.stdout as String).isNotEmpty) {
        stdout.write(res.stdout);
      }
      if (res.stderr != null && (res.stderr as String).isNotEmpty) {
        stderr.write(res.stderr);
      }
      if (res.exitCode != 0) {
        print('[migrate_runner] canonicalize tool exited with ${res.exitCode}');
        if (!dryRun) {
          // propagate failure when committing
          exit(res.exitCode);
        }
      }
    }
    print('[migrate_runner] Completed. dryRun=$dryRun');
  } finally {
    await db.close();
  }
}

// ... old _insertAttributeIfMissing removed; using _getOrCreateAttribute instead

Future<int> _getOrCreateAttribute(
  Database db,
  List<String> possibleNames,
  bool dryRun,
) async {
  // Find any existing attributes matching any of the possible names
  final placeholders = List.filled(possibleNames.length, '?').join(',');
  final rows = await db.rawQuery(
    'SELECT id, name FROM attributes WHERE name IN ($placeholders)',
    possibleNames,
  );

  if (rows.isNotEmpty) {
    // Prefer the canonical (first in possibleNames) if it exists, otherwise pick the first found
    final canonicalName = possibleNames.first;
    Map<String, Object?>? foundCanonical;
    for (final r in rows) {
      if (r['name'] == canonicalName) {
        foundCanonical = r;
        break;
      }
    }
    final canonicalRow = foundCanonical ?? rows.first;
    final canonicalId = canonicalRow['id'] as int;

    if (rows.length > 1) {
      // Merge duplicates: move attribute_values from duplicates into canonical, then delete duplicate attributes
      final duplicateIds = rows
          .map((r) => r['id'] as int)
          .where((id) => id != canonicalId)
          .toList();
      print(
        '[migrate_runner] Found existing attribute(s) for $possibleNames. Using id=$canonicalId (name=${canonicalRow['name']}).',
      );
      if (duplicateIds.isNotEmpty) {
        print(
          '[migrate_runner] Will merge duplicate attribute ids ${duplicateIds.join(', ')} into $canonicalId',
        );
        if (!dryRun) {
          final dupPlaceholders = List.filled(
            duplicateIds.length,
            '?',
          ).join(',');
          final updateArgs = [canonicalId, ...duplicateIds];
          await db.rawUpdate(
            'UPDATE attribute_values SET attribute_id = ? WHERE attribute_id IN ($dupPlaceholders)',
            updateArgs,
          );
          await db.rawDelete(
            'DELETE FROM attributes WHERE id IN ($dupPlaceholders)',
            duplicateIds,
          );
        }
      }
    }
    return canonicalId;
  }

  final canonical = possibleNames.first;
  print(
    '[migrate_runner] attribute "$canonical" not found among synonyms $possibleNames -> will create',
  );
  if (dryRun) return -1;
  return await db.insert('attributes', {'name': canonical});
}

Future<void> _migrateUniqueValues(
  Database db,
  String columnName,
  int attributeId,
  bool dryRun,
  int? sampleLimit,
) async {
  // Check whether the product_variants table still has this column.
  final pragma = await db.rawQuery('PRAGMA table_info(product_variants)');
  final hasColumn = pragma.any((c) {
    final n = c['name'];
    return n != null && n.toString().toLowerCase() == columnName.toLowerCase();
  });
  if (!hasColumn) {
    print(
      '[migrate_runner] Skipping $columnName: no such column on product_variants',
    );
    return;
  }
  String sql;
  if (sampleLimit != null) {
    sql =
        'SELECT DISTINCT $columnName AS val FROM (SELECT $columnName FROM product_variants LIMIT $sampleLimit) WHERE val IS NOT NULL AND TRIM(val) != ""';
  } else {
    sql =
        'SELECT DISTINCT $columnName AS val FROM product_variants WHERE $columnName IS NOT NULL AND TRIM($columnName) != ""';
  }
  final uniqueValues = await db.rawQuery(sql);
  print(
    '[migrate_runner] Found ${uniqueValues.length} unique values for $columnName (sampleLimit=$sampleLimit)',
  );
  for (final row in uniqueValues) {
    final value = row['val'];
    if (value == null) continue;
    final norm = _normalizeValue(columnName, value.toString());
    final existing = await db.query(
      'attribute_values',
      where: 'attribute_id = ? AND value = ?',
      whereArgs: [attributeId, norm],
    );
    if (existing.isEmpty) {
      print(
        '[migrate_runner] would insert attribute_value(attribute_id=$attributeId, value=$norm)',
      );
      if (!dryRun) {
        await db.insert('attribute_values', {
          'attribute_id': attributeId,
          'value': norm,
        });
      }
    } else {
      // already exists
    }
  }
}

String _normalizeValue(String columnName, String v) {
  var s = v.trim();
  if (s.isEmpty) return s;
  // simple normalization: trim and collapse internal whitespace
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  // For sizes, normalize common patterns
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
    // numeric sizes: remove trailing .0
    final numNorm = lower.replaceAll(RegExp(r'\.0+\$'), '');
    return numNorm.toUpperCase();
  }
  // For color, simple canonicalization (trim + title-case)
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

Future<void> _linkVariantAttributes(
  Database db,
  int sizeAttributeId,
  int colorAttributeId,
  bool dryRun,
  int? sampleLimit,
) async {
  final pragma = await db.rawQuery('PRAGMA table_info(product_variants)');
  final colsPresent = <String>{};
  for (final c in pragma) {
    final n = c['name'];
    if (n != null) colsPresent.add(n.toString().toLowerCase());
  }
  final hasSize = colsPresent.contains('size');
  final hasColor = colsPresent.contains('color');
  if (!hasSize && !hasColor) {
    print(
      '[migrate_runner] Skipping variant linking: product_variants has neither size nor color columns',
    );
    return;
  }
  final queryColumns = <String>['id'];
  if (hasSize) queryColumns.add('size');
  if (hasColor) queryColumns.add('color');
  final variants = await db.query(
    'product_variants',
    columns: queryColumns,
    limit: sampleLimit,
  );
  print(
    '[migrate_runner] Linking attributes for ${variants.length} variants (sampleLimit=$sampleLimit)',
  );
  for (final v in variants) {
    final variantId = v['id'] as int;
    final size = v['size'] as String?;
    final color = v['color'] as String?;
    if (size != null && size.trim().isNotEmpty) {
      final res = await db.query(
        'attribute_values',
        columns: ['id'],
        where: 'attribute_id = ? AND value = ?',
        whereArgs: [sizeAttributeId, size],
      );
      if (res.isNotEmpty) {
        final valueId = res.first['id'] as int;
        final exists = await db.query(
          'variant_attributes',
          where: 'variant_id = ? AND attribute_value_id = ?',
          whereArgs: [variantId, valueId],
        );
        if (exists.isEmpty) {
          print(
            '[migrate_runner] would link variant $variantId -> attribute_value $valueId (size)',
          );
          if (!dryRun) {
            await db.insert('variant_attributes', {
              'variant_id': variantId,
              'attribute_value_id': valueId,
            });
          }
        }
      } else {
        print(
          '[migrate_runner] WARNING: attribute value not found for size="$size" (variant $variantId)',
        );
      }
    }
    if (color != null && color.trim().isNotEmpty) {
      final res = await db.query(
        'attribute_values',
        columns: ['id'],
        where: 'attribute_id = ? AND value = ?',
        whereArgs: [colorAttributeId, color],
      );
      if (res.isNotEmpty) {
        final valueId = res.first['id'] as int;
        final exists = await db.query(
          'variant_attributes',
          where: 'variant_id = ? AND attribute_value_id = ?',
          whereArgs: [variantId, valueId],
        );
        if (exists.isEmpty) {
          print(
            '[migrate_runner] would link variant $variantId -> attribute_value $valueId (color)',
          );
          if (!dryRun) {
            await db.insert('variant_attributes', {
              'variant_id': variantId,
              'attribute_value_id': valueId,
            });
          }
        }
      } else {
        print(
          '[migrate_runner] WARNING: attribute value not found for color="$color" (variant $variantId)',
        );
      }
    }
  }
}
