import 'package:get_it/get_it.dart';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/core/di/di_modules.dart';

final sl = GetIt.instance;

Future<void> setupLocator() async {
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);
  registerDataModules();
}
