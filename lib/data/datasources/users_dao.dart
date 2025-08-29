import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/models/user.dart';
import 'package:clothes_pos/core/auth/auth_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:bcrypt/bcrypt.dart';

class UsersDao {
  final DatabaseHelper _dbHelper;
  UsersDao(this._dbHelper);

  /// Ensure that an 'admin' user exists, is active, linked to the 'Admin' role,
  /// and that the Admin role contains all current permissions.
  /// If password is placeholder (SET_ME) it is left for first login initialization.
  Future<void> ensureAdminUser() async {
    // Delegate to AuthService for consistent admin user setup
    await AuthService.instance.setupInitialAdminUserIfNeeded();
  }

  Future<List<AppUser>> listAllUsers({int limit = 100}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'users',
      columns: ['id', 'username', 'full_name', 'is_active'],
      orderBy: 'full_name COLLATE NOCASE ASC',
      limit: limit,
    );
    return rows
        .map(
          (u) => AppUser(
            id: u['id'] as int,
            username: u['username'] as String,
            fullName: u['full_name'] as String?,
            isActive: (u['is_active'] as int) == 1,
          ),
        )
        .toList();
  }

  Future<int> createUser({
    required String username,
    String? fullName,
    required String password,
    List<int> roleIds = const [],
  }) async {
    final db = await _dbHelper.database;
    return await db.transaction<int>((txn) async {
      final hash = BCrypt.hashpw(password, BCrypt.gensalt());
      final userId = await txn.insert('users', {
        'username': username.trim(),
        'full_name': fullName?.trim(),
        'password_hash': hash,
        'is_active': 1,
      });
      for (final r in roleIds) {
        await txn.insert('user_roles', {
          'user_id': userId,
          'role_id': r,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      return userId;
    });
  }

  Future<void> updateUser({
    required int id,
    String? fullName,
    bool? isActive,
  }) async {
    final db = await _dbHelper.database;
    final data = <String, Object?>{};
    if (fullName != null) data['full_name'] = fullName;
    if (isActive != null) data['is_active'] = isActive ? 1 : 0;
    if (data.isEmpty) return;
    await db.update('users', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> deleteUserHard(int id) async {
    final db = await _dbHelper.database;
    try {
      final count = await db.delete('users', where: 'id = ?', whereArgs: [id]);
      return count > 0;
    } catch (_) {
      return false; // likely due to FK constraints
    }
  }

  Future<void> deactivateUser(int id) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> changePassword(int userId, String newPassword) async {
    final db = await _dbHelper.database;
    final hash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
    await db.update(
      'users',
      {'password_hash': hash},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<Map<String, Object?>>> listRoles({int limit = 50}) async {
    final db = await _dbHelper.database;
    return db.query('roles', orderBy: 'name COLLATE NOCASE ASC', limit: limit);
  }

  Future<List<int>> getUserRoleIds(int userId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'user_roles',
      columns: ['role_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return rows.map((e) => e['role_id'] as int).toList();
  }

  Future<void> setUserRoles(int userId, List<int> roleIds) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('user_roles', where: 'user_id = ?', whereArgs: [userId]);
      for (final r in roleIds) {
        await txn.insert('user_roles', {'user_id': userId, 'role_id': r});
      }
    });
  }

  Future<List<Map<String, Object?>>> listPermissions() async {
    final db = await _dbHelper.database;
    return db.query('permissions', orderBy: 'code COLLATE NOCASE ASC');
  }

  // ---- Roles & Permissions management helpers ----
  Future<List<int>> getRolePermissionIds(int roleId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'role_permissions',
      columns: ['permission_id'],
      where: 'role_id = ?',
      whereArgs: [roleId],
    );
    return rows.map((e) => e['permission_id'] as int).toList();
  }

  Future<void> setRolePermissions(int roleId, List<int> permissionIds) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(
        'role_permissions',
        where: 'role_id = ?',
        whereArgs: [roleId],
      );
      for (final p in permissionIds) {
        await txn.insert('role_permissions', {
          'role_id': roleId,
          'permission_id': p,
        });
      }
    });
  }

  Future<int> createRole(String name) async {
    final db = await _dbHelper.database;
    return db.insert('roles', {'name': name.trim()});
  }

  Future<void> renameRole(int roleId, String newName) async {
    final db = await _dbHelper.database;
    await db.update(
      'roles',
      {'name': newName.trim()},
      where: 'id = ?',
      whereArgs: [roleId],
    );
  }

  Future<bool> deleteRole(int roleId) async {
    final db = await _dbHelper.database;
    try {
      final c = await db.delete('roles', where: 'id = ?', whereArgs: [roleId]);
      return c > 0;
    } catch (_) {
      return false; // Maybe FK restriction
    }
  }
}
