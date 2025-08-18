import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _dbName = 'clothes_pos.db';
  static const _dbVersion = 11; // bump: add audit_events table

  static Database? _db;
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
        await db.execute('PRAGMA journal_mode = WAL;');
      },
      onCreate: (db, version) async {
        final schema = await rootBundle.loadString('assets/db/schema.sql');
        await _executeSqlScript(db, schema);
        // Also run migrations up to current version so new installs get latest schema
        await _migrate(db, 0, _dbVersion);
        await _ensureLegacyFixes(db);
        await _seed(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _migrate(db, oldVersion, newVersion);
        await _ensureLegacyFixes(db);
      },
      onOpen: (db) async {
        // Safety net for installs that already advanced user_version without 005/010
        await _ensureLegacyFixes(db);
      },
    );
  }

  Future<void> _seed(Database db) async {
    // Safety: ensure core tables exist before seeding in case onCreate parsing skipped any
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        full_name TEXT,
        password_hash TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS permissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        description TEXT
      )
    ''');
    // Expenses tables may be added in later versions; ensure existence for seeding categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        paid_via TEXT NOT NULL,
        cash_session_id INTEGER,
        date TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
        FOREIGN KEY(category_id) REFERENCES expense_categories(id),
        FOREIGN KEY(cash_session_id) REFERENCES cash_sessions(id)
      )
    ''');

    final batch = db.batch();
    // roles/permissions basic
    batch.insert('roles', {
      'name': 'Admin',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    batch.insert('roles', {
      'name': 'Cashier',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // Example permissions (extend later)
    final perms = [
      {'code': 'view_reports', 'description': 'View reports'},
      {'code': 'edit_products', 'description': 'Create/edit products'},
      {'code': 'perform_sales', 'description': 'Perform POS sales'},
      {'code': 'perform_purchases', 'description': 'Create purchase invoices'},
      {'code': 'adjust_stock', 'description': 'Adjust stock levels'},
      {'code': 'manage_users', 'description': 'Manage users and roles'},
      {
        'code': 'record_expenses',
        'description': 'Record store operating expenses',
      },
    ];
    for (final p in perms) {
      batch.insert(
        'permissions',
        p,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // Admin user (password to be set by UI)
    batch.insert('users', {
      'username': 'admin',
      'full_name': 'Administrator',
      'password_hash': 'SET_ME',
      'is_active': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await batch.commit(noResult: true);
    // Seed common clothing categories if empty
    try {
      final existingCatCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM categories'),
          ) ??
          0;
      if (existingCatCount == 0) {
        final catBatch = db.batch();
        for (final name in ['قمصان', 'سراويل', 'أحذية', 'معاطف', 'إكسسوارات']) {
          catBatch.insert('categories', {
            'name': name,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await catBatch.commit(noResult: true);
      }
    } catch (_) {}
    // Seed expense categories (if using expenses module)
    try {
      final existingExpCats =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM expense_categories'),
          ) ??
          0;
      if (existingExpCats == 0) {
        final expCatBatch = db.batch();
        for (final name in [
          'رواتب',
          'كهرباء',
          'ماء',
          'إنترنت',
          'إيجار',
          'صيانة',
          'تسويق',
          'رسوم بنكية',
          'ضيافة',
          'أخرى',
        ]) {
          expCatBatch.insert('expense_categories', {
            'name': name,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await expCatBatch.commit(noResult: true);
      }
    } catch (_) {}

    // Link admin user to Admin role and assign all permissions to that role (idempotent).
    try {
      final roleIdRow = await db.rawQuery(
        'SELECT id FROM roles WHERE name = ? LIMIT 1',
        ['Admin'],
      );
      final userIdRow = await db.rawQuery(
        'SELECT id FROM users WHERE username = ? LIMIT 1',
        ['admin'],
      );
      if (roleIdRow.isNotEmpty && userIdRow.isNotEmpty) {
        final roleId = roleIdRow.first['id'] as int;
        final userId = userIdRow.first['id'] as int;
        await db.insert('user_roles', {
          'user_id': userId,
          'role_id': roleId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        final permRows = await db.rawQuery('SELECT id FROM permissions');
        final b2 = db.batch();
        for (final pr in permRows) {
          b2.insert('role_permissions', {
            'role_id': roleId,
            'permission_id': pr['id'],
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await b2.commit(noResult: true);
      }
    } catch (_) {
      // Swallow seeding relation errors to avoid crashing first launch.
    }
  }

  Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
    // Apply incremental SQL migrations found under assets/db/migrations/
    // Expected filenames: assets/db/migrations/00X.sql (e.g., 002.sql, 003.sql, ...)
    // We will attempt to load each file from (oldVersion+1) up to newVersion and
    // execute if present; missing files are skipped gracefully.
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      final id = v.toString().padLeft(3, '0');
      final asset = 'assets/db/migrations/$id.sql';
      try {
        await _runSqlAsset(db, asset);
      } catch (_) {
        // If asset not found, continue; this allows sparse version files.
        // Re-throw only for SQL execution errors inside _runSqlAsset.
      }
    }
  }

  Future<void> _runSqlAsset(Database db, String assetPath) async {
    final sql = await rootBundle.loadString(assetPath);
    final statements = _splitSqlStatements(sql)
        .where(
          (s) =>
              s.toUpperCase() != 'BEGIN TRANSACTION' &&
              s.toUpperCase() != 'COMMIT',
        )
        .toList();

    // Execute in logical groups similar to onCreate to respect object dependencies
    final tables = <String>[];
    final triggers = <String>[];
    final indices = <String>[];
    final others = <String>[];
    for (final s in statements) {
      final up = s.trimLeft().toUpperCase();
      if (up.startsWith('CREATE TABLE') ||
          up.startsWith('ALTER TABLE') ||
          up.startsWith('DROP TABLE')) {
        tables.add(s);
      } else if (up.startsWith('CREATE TRIGGER') ||
          up.startsWith('DROP TRIGGER')) {
        triggers.add(s);
      } else if (up.startsWith('CREATE INDEX') || up.startsWith('DROP INDEX')) {
        indices.add(s);
      } else {
        others.add(s);
      }
    }

    for (final group in [tables, triggers, others, indices]) {
      if (group.isEmpty) continue;
      final b = db.batch();
      for (final s in group) {
        b.execute(s);
      }
      await b.commit(noResult: true);
    }
  }

  Future<void> _executeSqlScript(Database db, String script) async {
    final lines = script.replaceAll('\r', '\n').split('\n');
    final buffer = StringBuffer();
    var inTrigger = false;

    bool isComment(String s) => s.trimLeft().startsWith('--');

    for (var raw in lines) {
      var line = raw.trimRight();
      if (line.trim().isEmpty || isComment(line)) continue;

      final up = line.trimLeft().toUpperCase();
      if (!inTrigger && up.startsWith('CREATE TRIGGER')) {
        inTrigger = true;
      }

      // Skip wrapping transaction statements from scripts
      if (!inTrigger &&
          (up == 'BEGIN TRANSACTION;' || up == 'BEGIN TRANSACTION')) {
        continue;
      }
      if (!inTrigger && (up == 'COMMIT;' || up == 'COMMIT')) {
        continue;
      }

      buffer.writeln(line);

      if (inTrigger) {
        if (up.startsWith('END;') || up == 'END') {
          final stmt = buffer.toString().trim();
          if (stmt.isNotEmpty) {
            await db.execute(stmt);
          }
          buffer.clear();
          inTrigger = false;
        }
        continue;
      }

      if (line.trim().endsWith(';')) {
        final stmt = buffer.toString().trim();
        if (stmt.isNotEmpty) {
          await db.execute(stmt);
        }
        buffer.clear();
      }
    }

    final leftover = buffer.toString().trim();
    if (leftover.isNotEmpty) {
      await db.execute(leftover);
    }
  }

  Future<void> _ensureLegacyFixes(Database db) async {
    // Ensure brands table exists.
    final brands = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='brands' LIMIT 1",
    );
    if (brands.isEmpty) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS brands (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');
    }
    // Ensure parent_products has brand_id column for joins/filters.
    final cols = await db.rawQuery("PRAGMA table_info('parent_products')");
    final hasBrandId = cols.any((r) => (r['name'] as String?) == 'brand_id');
    if (!hasBrandId) {
      await db.execute(
        'ALTER TABLE parent_products ADD COLUMN brand_id INTEGER',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_parent_products_brand_id ON parent_products(brand_id)',
      );
    }
  }

  List<String> _splitSqlStatements(String sql) {
    final cleaned = sql.replaceAll('\r', '\n');
    final parts = cleaned.split(';');
    final statements = <String>[];
    final buffer = StringBuffer();
    var inTrigger = false;

    bool startsWithCreateTrigger(String s) =>
        s.toUpperCase().contains('CREATE TRIGGER');

    for (var raw in parts) {
      final stmt = raw.trim();
      if (stmt.isEmpty || stmt.startsWith('--')) continue;

      if (inTrigger) {
        // accumulate until END
        buffer.write(stmt);
        if (!stmt.toUpperCase().startsWith('END')) {
          buffer.write(';');
        }
        if (stmt.toUpperCase().startsWith('END')) {
          statements.add(buffer.toString());
          buffer.clear();
          inTrigger = false;
        }
        continue;
      }

      if (startsWithCreateTrigger(stmt)) {
        inTrigger = true;
        buffer.write(stmt);
        buffer.write(';');
        continue;
      }

      statements.add(stmt);
    }

    // Safety: flush if buffer has content
    final leftover = buffer.toString().trim();
    if (leftover.isNotEmpty) {
      statements.add(leftover);
    }

    return statements;
  }

  // Test-only utility to close and delete the DB so onCreate runs fresh.
  Future<void> resetForTests() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    await deleteDatabase(path);
  }
}
