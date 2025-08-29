import 'dart:io';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/migrations/migrate_legacy_attributes.dart';
import 'package:clothes_pos/core/logging/app_logger.dart'; // For AppLogger

void main(List<String> args) async {
  // Parse simple CLI args: --dry-run (default true), --sample=N, --commit
  var dryRun = true;
  int? sampleLimit;
  if (args.contains('--commit')) dryRun = false;
  for (final a in args) {
    if (a.startsWith('--sample=')) {
      final parts = a.split('=');
      if (parts.length == 2) {
        sampleLimit = int.tryParse(parts[1]);
      }
    }
    if (a == '--dry-run') dryRun = true;
  }

  AppLogger.i(
    'temp_run_migration started with dryRun=$dryRun sampleLimit=$sampleLimit',
  );

  // Initialize database helper
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database; // Ensure database is initialized and opened

  final migrator = LegacyAttributesMigrator(
    dbHelper,
    dryRun: dryRun,
    sampleLimit: sampleLimit,
  );
  try {
    await migrator.migrate();
    AppLogger.i('Migration script executed successfully. dryRun=$dryRun');
  } catch (e, st) {
    AppLogger.e('Error executing migration script', error: e, stackTrace: st);
    exitCode = 2;
  }
}
