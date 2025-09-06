import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSettings {
  final FlutterSecureStorage _storage;
  SecureSettings([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> get(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      if (kDebugMode) print('SecureSettings.get error: $e');
      return null;
    }
  }

  Future<void> set(String key, String? value) async {
    try {
      if (value == null) {
        await _storage.delete(key: key);
      } else {
        await _storage.write(key: key, value: value);
      }
    } catch (e) {
      if (kDebugMode) print('SecureSettings.set error: $e');
    }
  }
}
