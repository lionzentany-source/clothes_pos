import 'package:clothes_pos/data/datasources/auth_dao.dart';
import 'package:clothes_pos/data/models/user.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';

class AuthRepository {
  final AuthDao dao;
  AuthRepository(this.dao);

  Future<AppUser?> login(String username, String password) async {
    AppLogger.d('AuthRepository.login attempt username=$username');
    final ok = await dao.verifyPassword(username, password);
    if (!ok) {
      AppLogger.d('AuthRepository.login failed username=$username');
      return null;
    }
    final user = await dao.getByUsername(username);
    AppLogger.d(
      'AuthRepository.login success username=$username id=${user?.id}',
    );
    return user;
  }

  Future<AppUser?> getById(int id) => dao.getById(id);
  Future<List<AppUser>> listActiveUsers() => dao.listActiveUsers();
  Future<bool> isPasswordPlaceholder(String username) =>
      dao.isPasswordPlaceholder(username);
  Future<bool> setPassword(String username, String newPassword) =>
      dao.setPassword(username, newPassword);
  Future<bool> resetPasswordToPlaceholder(String username) =>
      dao.resetPasswordToPlaceholder(username);
}
