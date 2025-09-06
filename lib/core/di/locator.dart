import 'package:get_it/get_it.dart';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/core/di/di_modules.dart';
import 'package:clothes_pos/core/logging/usage_logger.dart';
import 'package:clothes_pos/assistant/ai/ai_settings_loader.dart';
import 'package:clothes_pos/assistant/ai/ai_client.dart';
import 'package:clothes_pos/assistant/ai/ai_service.dart';
// ...existing imports...
import 'package:clothes_pos/data/datasources/settings_dao.dart';
import 'package:clothes_pos/data/datasources/secure_settings.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';

final sl = GetIt.instance;

/// Set [registerAggregatedReports] to false in tests to avoid opening the
/// database during DI registration. Some async singletons (eg. aggregated
/// reports) open the DB immediately which races with test DB reset/close.
Future<void> setupLocator({bool registerAggregatedReports = true}) async {
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);
  sl.registerLazySingleton<UsageLogger>(() => UsageLogger());
  // Secure storage for sensitive settings
  sl.registerLazySingleton(() => SecureSettings());

  // Register AiService as an async singleton
  sl.registerSingletonAsync<AiService>(() async {
    final settings = await loadAiSettings();
    return AiService.fromSettings(OpenAiCompatibleClient(), settings);
  });

  // Facebook services removed: removed factory registrations as part of
  // feature cleanup (see backups/facebook_bot_backup_*/ for originals).

  registerDataModules(registerAggregatedReports: registerAggregatedReports);

  // Override SettingsRepository registration to include secure settings
  // (registerDataModules registers SettingsRepository via dao; replace it)
  final settingsDao = sl<SettingsDao>();
  final secure = sl<SecureSettings>();
  sl.unregister<SettingsRepository>();
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository.withSecure(settingsDao, secure),
  );
}
