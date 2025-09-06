import 'package:clothes_pos/data/datasources/users_dao.dart';
import 'package:clothes_pos/data/models/user.dart';

class UsersRepository {
  final UsersDao dao;
  UsersRepository(this.dao);

  Future<List<AppUser>> listAllUsers({int limit = 100}) =>
      dao.listAllUsers(limit: limit);
  Future<int> createUser({
    required String username,
    String? fullName,
    required String password,
    List<int> roleIds = const [],
  }) => dao.createUser(
    username: username,
    fullName: fullName,
    password: password,
    roleIds: roleIds,
  );
  Future<void> updateUser({
    required int id,
    String? fullName,
    bool? isActive,
  }) => dao.updateUser(id: id, fullName: fullName, isActive: isActive);
  Future<bool> deleteUserHard(int id) => dao.deleteUserHard(id);
  Future<void> deactivateUser(int id) => dao.deactivateUser(id);
  Future<void> changePassword(int userId, String newPassword) =>
      dao.changePassword(userId, newPassword);
  Future<List<Map<String, Object?>>> listRoles({int limit = 50}) =>
      dao.listRoles(limit: limit);
  Future<List<int>> getUserRoleIds(int userId) => dao.getUserRoleIds(userId);
  Future<void> setUserRoles(int userId, List<int> roleIds) =>
      dao.setUserRoles(userId, roleIds);
  Future<List<Map<String, Object?>>> listPermissions() => dao.listPermissions();
  Future<List<int>> getRolePermissionIds(int roleId) =>
      dao.getRolePermissionIds(roleId);
  Future<void> setRolePermissions(int roleId, List<int> permissionIds) =>
      dao.setRolePermissions(roleId, permissionIds);
  Future<int> createRole(String name) => dao.createRole(name);
  Future<void> renameRole(int roleId, String newName) =>
      dao.renameRole(roleId, newName);
  Future<bool> deleteRole(int roleId) => dao.deleteRole(roleId);
  Future<void> ensureAdminUser() => dao.ensureAdminUser();
}
