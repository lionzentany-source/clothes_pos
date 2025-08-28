import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'dart:io' show Platform, Directory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/di/locator.dart';
import 'presentation/app_root.dart';
import 'data/repositories/settings_repository.dart';
import 'core/integrity/integrity_monitor.dart';
import 'core/logging/app_logger.dart';
import 'core/hardware/uhf/uhf_health_monitor.dart';
import 'core/hardware/uhf/uhf_reader.dart';
import 'core/hardware/uhf/noop_uhf_reader.dart';
import 'core/backup/backup_service.dart';
import 'package:path/path.dart' as p;
import 'core/db/database_helper.dart';
import 'data/datasources/expense_dao.dart';

Future<void> _seedExpenseCategoriesIfEmpty() async {
  try {
    final dao = sl<ExpenseDao>();
    final existing = await dao.listCategories(onlyActive: false);
    if (existing.isEmpty) {
      for (final name in const [
        'كهرباء',
        'ماء',
        'إيجار',
        'رواتب',
        'تسويق',
        'صيانة',
        'إنترنت',
        'ضرائب',
        'نقل',
        'أخرى',
      ]) {
        await dao.createCategory(name);
      }
    }
  } catch (_) {}
}

// Application entry point. Any long-running pre-run initialization should be awaited here.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize FFI database on desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await setupLocator();
  // Seed default expense categories once (idempotent)
  await _seedExpenseCategoriesIfEmpty();
  // Start integrity monitor (non-blocking)
  IntegrityMonitor(dbHelper: sl()).start();
  // Start UHF health monitor (non-blocking)
  try {
    if (sl.isRegistered<UHFReader>()) {
      final reader = sl<UHFReader>();
      if (reader is! NoopUHFReader) {
        UHFHealthMonitor().start();
      }
    }
  } catch (_) {}
  // Ensure Arabic receipt font asset is set once (safe if already set)
  try {
    final settings = sl<SettingsRepository>();
    final current = await settings.get('receipt_font_asset');
    if (current == null || current.trim().isEmpty) {
      await settings.set(
        'receipt_font_asset',
        'assets/db/fonts/sfpro/alfont_com_SFProAR_semibold.ttf',
      );
    }
  } catch (_) {}
  // Start periodic database backup (best-effort, desktop only)
  try {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final dbHelper = sl<DatabaseHelper>();
      final db = await dbHelper.database; // ensure opened
      final dbPath = db.path;
      final backupsDir = Directory(p.join(p.dirname(dbPath), 'backups'));
      final backupService = BackupService(
        dbPath: dbPath,
        backupRoot: backupsDir,
        interval: const Duration(hours: 6),
        maxFiles: 24,
        maxAge: const Duration(days: 30),
      );
      // Register for UI access if not already
      if (!sl.isRegistered<BackupService>()) {
        sl.registerSingleton<BackupService>(backupService);
      }
      // ignore: discarded_futures
      backupService.start();
    }
  } catch (e) {
    AppLogger.w('BackupService failed to start: $e');
  }
  AppLogger.i('Application started');
  runApp(const AppRoot());
}
