import 'package:clothes_pos/data/datasources/settings_dao.dart';
import 'package:clothes_pos/data/datasources/secure_settings.dart';

const _secureKeys = {
  'facebook_page_access_token',
  'facebook_verify_token',
  'facebook_page_id',
};

class SettingsRepository {
  final SettingsDao dao;
  final SecureSettings secure;
  SettingsRepository(this.dao) : secure = SecureSettings();

  SettingsRepository.withSecure(this.dao, this.secure);

  Future<String?> get(String key) async {
    if (_secureKeys.contains(key)) {
      return await secure.get(key);
    }
    return await dao.get(key);
  }

  Future<void> set(String key, String? value) async {
    if (_secureKeys.contains(key)) {
      await secure.set(key, value);
      return;
    }
    await dao.set(key, value);
  }
}
