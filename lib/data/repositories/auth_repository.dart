import 'package:clothes_pos/data/datasources/auth_dao.dart';
import 'package:clothes_pos/data/models/user.dart';

class AuthRepository {
  final AuthDao dao;
  AuthRepository(this.dao);

  Future<AppUser?> login(String username, String password) async {
    final ok = await dao.verifyPassword(username, password);
    if (!ok) return null;
    final user = await dao.getByUsername(username);
    return user;
  }

  Future<AppUser?> getById(int id) => dao.getById(id);
  Future<List<AppUser>> listActiveUsers() => dao.listActiveUsers();
}
