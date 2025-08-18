import 'package:clothes_pos/data/datasources/settings_dao.dart';

class SettingsRepository {
  final SettingsDao dao;
  SettingsRepository(this.dao);

  Future<String?> get(String key) => dao.get(key);
  Future<void> set(String key, String? value) => dao.set(key, value);
}

