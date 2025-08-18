import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/models/user.dart';
import 'package:bcrypt/bcrypt.dart';

class AuthDao {
  final DatabaseHelper _dbHelper;
  AuthDao(this._dbHelper);

  Future<AppUser?> getByUsername(String username) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final u = rows.first;
    final roles = await db.rawQuery(
      '''
      SELECT p.code FROM permissions p
      INNER JOIN role_permissions rp ON rp.permission_id = p.id
      INNER JOIN user_roles ur ON ur.role_id = rp.role_id
      WHERE ur.user_id = ?
    ''',
      [u['id']],
    );
    final perms = roles.map((e) => e['code'] as String).toList();
    return AppUser(
      id: u['id'] as int,
      username: u['username'] as String,
      fullName: u['full_name'] as String?,
      isActive: (u['is_active'] as int) == 1,
      permissions: perms,
    );
  }

  Future<bool> verifyPassword(String username, String password) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final userId = rows.first['id'] as int;
    final stored = rows.first['password_hash'] as String? ?? '';

    // First-time setup: if placeholder value, accept provided password (with minimal length) and upgrade to bcrypt
    if (stored == 'SET_ME') {
      if (password.trim().length < 4) {
        return false; // enforce minimal length on initial set
      }
      final newHash = BCrypt.hashpw(password, BCrypt.gensalt());
      await updatePasswordHash(userId, newHash);
      return true;
    }

    bool isBcrypt(String h) =>
        h.startsWith(r'$2a$') || h.startsWith(r'$2b$') || h.startsWith(r'$2y$');
    if (isBcrypt(stored)) {
      try {
        if (BCrypt.checkpw(password, stored)) return true;
      } catch (_) {
        /* fallback */
      }
    }

    // Legacy plain text fallback
    if (stored == password) {
      // Upgrade to bcrypt
      final newHash = BCrypt.hashpw(password, BCrypt.gensalt());
      await updatePasswordHash(userId, newHash);
      return true;
    }
    return false;
  }

  Future<void> updatePasswordHash(int userId, String bcryptHash) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'password_hash': bcryptHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<AppUser?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final u = rows.first;
    final roles = await db.rawQuery(
      '''
      SELECT p.code FROM permissions p
      INNER JOIN role_permissions rp ON rp.permission_id = p.id
      INNER JOIN user_roles ur ON ur.role_id = rp.role_id
      WHERE ur.user_id = ?
    ''',
      [u['id']],
    );
    final perms = roles.map((e) => e['code'] as String).toList();
    return AppUser(
      id: u['id'] as int,
      username: u['username'] as String,
      fullName: u['full_name'] as String?,
      isActive: (u['is_active'] as int) == 1,
      permissions: perms,
    );
  }

  Future<List<AppUser>> listActiveUsers() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'users',
      columns: ['id', 'username', 'full_name', 'is_active'],
      where: 'is_active = 1',
      orderBy: 'full_name COLLATE NOCASE ASC',
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
}
