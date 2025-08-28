import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

import 'package:sqflite/sqflite.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';

class DatabaseHelper {
  static const _dbName = 'clothes_pos.db';
  static const _dbVersion =
      17; // v17: legacy user/role/permission backfill + expense ordering index; v16: expense indices + busy_timeout + diagnostics; v15: branch_id columns + composite brand/category index + migration tracking

  static Database? _db;
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    final swMain = Stopwatch()..start();
    AppLogger.d('DatabaseHelper.get database init start');
    try {
      _db = await _initDatabase();
      swMain.stop();
      AppLogger.d(
        'DatabaseHelper.get database init success in \\${swMain.elapsedMilliseconds}ms',
      );
      return _db!;
    } catch (e, st) {
      swMain.stop();
      AppLogger.e(
        'DatabaseHelper.get database init failed after \\${swMain.elapsedMilliseconds}ms',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    final swInit = Stopwatch()..start();
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
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
          'DatabaseHelper.onConfigure done in \${cfgSw.elapsedMilliseconds}ms',
        );
      },
      onCreate: (db, version) async {
        AppLogger.d('DatabaseHelper.onCreate start version=$version');
        final createSw = Stopwatch()..start();
        // Use a robust splitter that preserves CREATE TRIGGER blocks (BEGIN..END;)
        final schema = await rootBundle.loadString('assets/db/test_schema.sql');
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
          'DatabaseHelper.onCreate complete in \\${createSw.elapsedMilliseconds}ms',
        );
      },
      // يمكن إضافة منطق التحديث لاحقاً إذا لزم الأمر
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
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    await deleteDatabase(path);
  }
}
