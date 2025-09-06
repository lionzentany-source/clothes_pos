import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

import 'package:sqflite/sqflite.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';

class DatabaseHelper {
  static const _dbName = 'clothes_pos.db';
  static const _dbVersion = 21; // v21: Add dynamic attributes tables

  static Database? _db;
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    final swMain = Stopwatch()..start();
    AppLogger.d('DatabaseHelper.get database init start');
    try {
      _db = await _initDatabase();
      // تحقق من وجود عمود image_path وأضفه إذا كان غير موجود
      final columns = await _db!.rawQuery(
        'PRAGMA table_info(product_variants)',
      );
      final hasImagePathColumn = columns.any(
        (column) => column['name'] == 'image_path',
      );
      if (!hasImagePathColumn) {
        await _db!.execute(
          'ALTER TABLE product_variants ADD COLUMN image_path TEXT;',
        );
        AppLogger.i(
          'تمت إضافة عمود image_path تلقائيًا إلى جدول product_variants',
        );
      }
      // Ensure dynamic attributes tables exist (fix for older DBs created
      // before dynamic attributes migration). This is defensive: if the
      // migration didn't create these tables previously, create them now so
      // runtime operations (saving products/parent attributes) won't fail.
      try {
        final tables = await _db!.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('attributes','attribute_values','parent_attributes','variant_attributes')",
        );
        final existing = tables.map((r) => r.values.first as String).toSet();

        if (!existing.contains('attributes')) {
          await _db!.execute('''
            CREATE TABLE IF NOT EXISTS attributes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL
            );
          ''');
          AppLogger.i('Created missing table: attributes');
        }

        if (!existing.contains('attribute_values')) {
          await _db!.execute('''
            CREATE TABLE IF NOT EXISTS attribute_values (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              attribute_id INTEGER NOT NULL,
              value TEXT NOT NULL,
              FOREIGN KEY (attribute_id) REFERENCES attributes(id) ON DELETE CASCADE,
              UNIQUE(attribute_id, value)
            );
          ''');
          AppLogger.i('Created missing table: attribute_values');
        }

        if (!existing.contains('parent_attributes')) {
          await _db!.execute('''
            CREATE TABLE IF NOT EXISTS parent_attributes (
              parent_id INTEGER NOT NULL,
              attribute_id INTEGER NOT NULL,
              PRIMARY KEY (parent_id, attribute_id),
              FOREIGN KEY (parent_id) REFERENCES parent_products(id) ON DELETE CASCADE,
              FOREIGN KEY (attribute_id) REFERENCES attributes(id) ON DELETE CASCADE
            );
          ''');
          AppLogger.i('Created missing table: parent_attributes');
        }

        if (!existing.contains('variant_attributes')) {
          await _db!.execute('''
            CREATE TABLE IF NOT EXISTS variant_attributes (
              variant_id INTEGER NOT NULL,
              attribute_value_id INTEGER NOT NULL,
              PRIMARY KEY (variant_id, attribute_value_id),
              FOREIGN KEY (variant_id) REFERENCES product_variants(id) ON DELETE CASCADE,
              FOREIGN KEY (attribute_value_id) REFERENCES attribute_values(id) ON DELETE CASCADE
            );
          ''');
          AppLogger.i('Created missing table: variant_attributes');
        }
      } catch (e, st) {
        AppLogger.e(
          'Failed to ensure dynamic-attributes tables exist',
          error: e,
          stackTrace: st,
        );
      }
      // Ensure held-sales tables exist and have expected columns
      try {
        await _db!.execute('''
          CREATE TABLE IF NOT EXISTS held_sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            ts TEXT NOT NULL
          );
        ''');
        await _db!.execute('''
          CREATE TABLE IF NOT EXISTS held_sale_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            held_sale_id INTEGER NOT NULL,
            variant_id INTEGER NOT NULL,
            quantity INTEGER NOT NULL,
            price REAL NOT NULL,
            FOREIGN KEY (held_sale_id) REFERENCES held_sales(id) ON DELETE CASCADE
          );
        ''');
        // Patch missing columns on existing installs
        final cols = await _db!.rawQuery('PRAGMA table_info(held_sale_items)');
        final hasAttributes = cols.any(
          (c) => (c['name'] as String?) == 'attributes',
        );
        final hasPriceOverride = cols.any(
          (c) => (c['name'] as String?) == 'price_override',
        );
        if (!hasAttributes) {
          await _db!.execute(
            'ALTER TABLE held_sale_items ADD COLUMN attributes TEXT;',
          );
        }
        if (!hasPriceOverride) {
          await _db!.execute(
            'ALTER TABLE held_sale_items ADD COLUMN price_override REAL;',
          );
        }
        // Helpful indexes
        await _db!.execute(
          'CREATE INDEX IF NOT EXISTS idx_held_sales_ts ON held_sales(ts);',
        );
        await _db!.execute(
          'CREATE INDEX IF NOT EXISTS idx_held_sale_items_held ON held_sale_items(held_sale_id);',
        );
      } catch (e, st) {
        AppLogger.e(
          'Failed to ensure held-sales tables/columns',
          error: e,
          stackTrace: st,
        );
      }
      swMain.stop();
      AppLogger.d(
        'DatabaseHelper.get database init success in ${swMain.elapsedMilliseconds}ms',
      );
      return _db!;
    } catch (e, st) {
      swMain.stop();
      AppLogger.e(
        'DatabaseHelper.get database init failed after ${swMain.elapsedMilliseconds}ms',
        error: e,
        stackTrace: st,
      );
      AppLogger.e('Database open error: $e\nStack: $st');
      _db = null;
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    final swInit = Stopwatch()..start();
    // استخدم المسار الفعلي للقاعدة لضمان الترقية
    final path = p.join(
      p.current,
      '.dart_tool',
      'sqflite_common_ffi',
      'databases',
      _dbName,
    );
    AppLogger.d('DatabaseHelper._initDatabase path=$path');

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        final cfgSw = Stopwatch()..start();
        await db.execute('PRAGMA foreign_keys = ON;');
        await db.execute('PRAGMA journal_mode = WAL;');
        await db.execute('PRAGMA busy_timeout = 5000;');
        try {
          final jm = await db.rawQuery('PRAGMA journal_mode;');
          final bt = await db.rawQuery('PRAGMA busy_timeout;');
          AppLogger.d(
            'DatabaseHelper.onConfigure journal_mode=${jm.first.values.first} busy_timeout=${bt.first.values.first}',
          );
        } catch (_) {}
        cfgSw.stop();
        AppLogger.d(
          'DatabaseHelper.onConfigure done in ${cfgSw.elapsedMilliseconds}ms',
        );
      },
      onCreate: (db, version) async {
        AppLogger.d('DatabaseHelper.onCreate start version=$version');
        final createSw = Stopwatch()..start();
        // Use a robust splitter that preserves CREATE TRIGGER blocks (BEGIN..END;)
        final schema = await rootBundle.loadString('assets/db/schema.sql');
        final lines = schema.split('\n');
        final buffer = StringBuffer();
        bool inTriggerBlock = false; // inside CREATE TRIGGER ... BEGIN .. END;
        for (final rawLine in lines) {
          final line = rawLine.trimRight();
          final trimmedUpper = line.trim().toUpperCase();
          if (trimmedUpper.startsWith('--')) {
            // skip SQL comments lines
            continue;
          }
          if (!inTriggerBlock && trimmedUpper.contains('CREATE TRIGGER')) {
            inTriggerBlock = true;
          }
          buffer.writeln(line);
          if (inTriggerBlock) {
            // End trigger block when END; appears on the line
            if (trimmedUpper.contains('END;')) {
              final sql = buffer.toString().trim();
              if (sql.isNotEmpty) {
                await db.execute(sql);
              }
              buffer.clear();
              inTriggerBlock = false;
            }
          } else {
            // Non-trigger: flush on semicolon terminator
            if (trimmedUpper.endsWith(';')) {
              final sql = buffer.toString().trim();
              if (sql.isNotEmpty) {
                await db.execute(sql);
              }
              buffer.clear();
            }
          }
        }
        // Flush any remaining SQL without trailing semicolon
        final rest = buffer.toString().trim();
        if (rest.isNotEmpty) {
          await db.execute(rest);
        }
        createSw.stop();
        AppLogger.d(
          'DatabaseHelper.onCreate complete in ${createSw.elapsedMilliseconds}ms',
        );
        // Apply any initial migration scripts that are expected for the current
        // schema version (fresh DBs should include migration-created tables).
        // In particular, ensure dynamic attributes tables from 020.sql are created
        // when creating a fresh DB at version >= 21.
        try {
          if (version >= 21) {
            final mig = await rootBundle.loadString(
              'assets/db/migrations/020.sql',
            );
            final parts = mig.split(';');
            for (final part in parts) {
              final stmt = part.trim();
              if (stmt.isNotEmpty) {
                await db.execute(stmt);
              }
            }
            AppLogger.i(
              'Applied initial migration assets/db/migrations/020.sql',
            );
          }
        } catch (e, st) {
          AppLogger.e(
            'Failed applying initial migration 020.sql',
            error: e,
            stackTrace: st,
          );
        }
        // إضافة الفئات الأكثر استخداماً تلقائياً
        final defaultCategories = [
          'تيشيرتات',
          'قمصان',
          'بناطيل',
          'جواكت ومعاطف',
          'فساتين',
          'ملابس رياضية',
          'ملابس داخلية',
          'ملابس أطفال',
          'عبايات وجلابيات',
          'أحذية',
        ];
        for (final cat in defaultCategories) {
          await db.insert('categories', {'name': cat});
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        AppLogger.d(
          'DatabaseHelper.onUpgrade start from v$oldVersion to v$newVersion',
        );
        if (oldVersion < 18) {
          try {
            await db.execute(
              'ALTER TABLE product_variants ADD COLUMN image_path TEXT;',
            );
            AppLogger.i(
              'Upgraded database from v$oldVersion to v18: Added image_path to product_variants',
            );
          } catch (e) {
            AppLogger.e('Failed to upgrade database to v18', error: e);
            // If the migration fails, we might want to rethrow or handle it gracefully
          }
        }
        // Ensure usage_logs table exists for upgrades from older versions
        await db.execute('''
            CREATE TABLE IF NOT EXISTS usage_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
              event_type TEXT NOT NULL,
              event_details TEXT,
              user_id INTEGER,
              session_id TEXT,
              FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
            );
          ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_usage_logs_timestamp ON usage_logs(timestamp);',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_usage_logs_event_type ON usage_logs(event_type);',
        );
        if (oldVersion < 19) {
          try {
            // Check if column exists before adding it
            final columns = await db.rawQuery(
              'PRAGMA table_info(product_variants)',
            );

            final hasImagePathColumn = columns.any(
              (column) => column['name'] == 'image_path',
            );

            if (!hasImagePathColumn) {
              await db.execute(
                'ALTER TABLE product_variants ADD COLUMN image_path TEXT;',
              );
              AppLogger.i(
                'Upgraded database from v$oldVersion to v19: Added image_path to product_variants',
              );
            } else {
              AppLogger.i(
                'Upgraded database from v$oldVersion to v19: image_path column already exists',
              );
            }
          } catch (e) {
            AppLogger.e('Failed to upgrade database to v19', error: e);
            // If the migration fails, we might want to rethrow or handle it gracefully
          }
        }
        if (oldVersion < 21) {
          try {
            final script = await rootBundle.loadString(
              'assets/db/migrations/020.sql',
            );
            final statements = script.split(';');
            for (final statement in statements) {
              if (statement.trim().isNotEmpty) {
                await db.execute(statement);
              }
            }
            AppLogger.i(
              'Upgraded database from v$oldVersion to v21: Added dynamic attributes tables',
            );
          } catch (e) {
            AppLogger.e('Failed to upgrade database to v21', error: e);
          }
        }
      },
    );
    swInit.stop();
    AppLogger.d(
      'DatabaseHelper._initDatabase openDatabase total ${swInit.elapsedMilliseconds}ms',
    );
    return db;
  }

  // Test-only utility to close and delete the DB so onCreate runs fresh.
  Future<void> resetForTests() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
    // Delete databases from common locations used in tests and runtime.
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, _dbName);
      // Try to delete cleanly; if file is locked, open and drop tables instead.
      try {
        await deleteDatabase(path);
      } catch (_) {
        try {
          final tmpDb = await openDatabase(path);
          final tables = await tmpDb.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
          );
          for (final row in tables) {
            final name = row.values.first as String;
            try {
              await tmpDb.execute('DROP TABLE IF EXISTS $name;');
            } catch (_) {}
          }
          await tmpDb.close();
          try {
            final f = File(path);
            if (await f.exists()) await f.delete();
          } catch (_) {}
        } catch (_) {}
      }
    } catch (_) {}

    // Some codepaths (and the production openDatabase) use a path under
    // the repo working directory for ffi/sqflite tests. Delete that as well.
    // Some codepaths (and the production openDatabase) use a path under
    // the repo working directory for ffi/sqflite tests. Delete that as well.
    try {
      final altDirPath = p.join(
        p.current,
        '.dart_tool',
        'sqflite_common_ffi',
        'databases',
      );
      final altDbPath = p.join(altDirPath, _dbName);
      // Try sqflite-level delete first
      try {
        await deleteDatabase(altDbPath);
      } catch (_) {
        try {
          final tmpDb = await openDatabase(altDbPath);
          final tables = await tmpDb.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
          );
          for (final row in tables) {
            final name = row.values.first as String;
            try {
              await tmpDb.execute('DROP TABLE IF EXISTS $name;');
            } catch (_) {}
          }
          await tmpDb.close();
          final file = File(altDbPath);
          if (await file.exists()) {
            try {
              await file.delete();
            } catch (_) {}
          }
        } catch (_) {}
      }

      // Also remove any lingering files (.db, -wal, -shm) and the directory
      final altFiles = [altDbPath, '$altDbPath-wal', '$altDbPath-shm'];
      for (final f in altFiles) {
        try {
          final file = File(f);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
      final altDir = Directory(altDirPath);
      if (await altDir.exists()) {
        try {
          await altDir.delete(recursive: true);
        } catch (_) {}
      }
    } catch (_) {}
  }
}
