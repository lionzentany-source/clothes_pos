import 'package:flutter/cupertino.dart';
import 'dart:ui'; // Import dart:ui for PlatformDispatcher
import 'dart:io' show Platform, Directory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/di/locator.dart';
import 'package:clothes_pos/core/logging/usage_logger.dart'; // Import UsageLogger
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
import 'package:clothes_pos/assistant/theme_provider.dart';
import 'package:clothes_pos/core/auth/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/presentation/pos/bloc/pos_cubit.dart';
import 'package:clothes_pos/presentation/settings/bloc/settings_cubit.dart';
import 'package:clothes_pos/presentation/inventory/bloc/inventory_cubit.dart';
import 'package:clothes_pos/presentation/returns/bloc/returns_cubit.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:clothes_pos/data/migrations/migrate_legacy_attributes.dart';

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
  try {
    await setupLocator();
  } catch (e) {
    AppLogger.e('Failed to setup locator: $e');
    // Handle critical error, maybe show a dialog and exit
  }

  // Initialize UsageLogger for global error handling
  final usageLogger = sl<UsageLogger>();

  // Global error handling for Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details); // Still show the error in debug mode
    usageLogger.logEvent(
      'flutter_error',
      {
        'exception': details.exception.toString(),
        'stack_trace': details.stack.toString(),
        'context': details.context?.toString(),
      },
    );
  };

  // Global error handling for Dart VM errors
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    usageLogger.logEvent(
      'dart_error',
      {
        'error': error.toString(),
        'stack_trace': stack.toString(),
      },
    );
    return true; // Return true to indicate the error has been handled
  };

  // The line below is for testing the first-run flow.
  // It will wipe the database on every run.
  // Please comment it out for production use.
  // await DatabaseHelper.instance.resetForTests();

  // Set up the initial admin user if it's the first run.
  // This is called after resetForTests to ensure it runs on a clean DB.
  await AuthService.instance.setupInitialAdminUserIfNeeded();

  // Run legacy attributes migration if not already done
  final settingsRepo = sl<SettingsRepository>();
  final isMigrated = (await settingsRepo.get('legacy_attributes_migrated')) == 'true';
  if (!isMigrated) {
    AppLogger.i('Running legacy attributes data migration...');
    final migrator = LegacyAttributesMigrator(sl<DatabaseHelper>());
    try {
      await migrator.migrate();
      await settingsRepo.set('legacy_attributes_migrated', 'true');
      AppLogger.i('Legacy attributes data migration completed successfully.');
    } catch (e, st) {
      AppLogger.e('Failed to run legacy attributes data migration', error: e, stackTrace: st);
    }
  }

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
  // ThemeProvider
  sl.registerSingleton<ThemeProvider>(ThemeProvider());

  AppLogger.i('Application started');

  // The app will always start at the AppRoot now.
  // The login screen within AppRoot will handle the initial password setup flow.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => sl<ThemeProvider>(),
        ),
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => PosCubit()..loadCategories()),
        BlocProvider(
          create: (_) => SettingsCubit(sl<SettingsRepository>())..load(),
        ),
        BlocProvider(create: (_) => InventoryCubit()),
        BlocProvider(create: (_) => ReturnsCubit(sl(), sl())),
      ],
      child: Builder(
        builder: (context) {
          final settings = context.watch<SettingsCubit>().state;
          final theme = settings.themeMode == ThemeMode.dark
              ? AppTheme.dark()
              : AppTheme.light();
          return CupertinoApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: const [Locale('ar')],
            theme: theme,
            onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
            home: const AppRoot(),
          );
        },
      ),
    ),
  );
}