import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/models/user.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';

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
    AppLogger.d('AuthDao.verifyPassword start username=$username');
    final db = await _dbHelper.database;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (rows.isEmpty) {
      AppLogger.d('AuthDao.verifyPassword user_not_found username=$username');
      return false;
    }
    final userId = rows.first['id'] as int;
    final stored = rows.first['password_hash'] as String? ?? '';
    final storedPreview = stored == 'SET_ME'
        ? 'SET_ME'
        : stored.length > 8
        ? '${stored.substring(0, 6)}...len=${stored.length}'
        : stored;
    AppLogger.d(
      'AuthDao.verifyPassword fetched userId=$userId hash=$storedPreview',
    );

    // First-time setup: if placeholder value, accept provided password (with minimal length) and upgrade to bcrypt
    if (stored == 'SET_ME') {
      if (password.trim().length < 4) {
        AppLogger.d('AuthDao.verifyPassword placeholder_reject length<4');
        return false; // enforce minimal length on initial set
      }
      final newHash = BCrypt.hashpw(password, BCrypt.gensalt());
      await updatePasswordHash(userId, newHash);
      AppLogger.d(
        'AuthDao.verifyPassword placeholder_accepted upgraded_to_bcrypt',
      );
      return true;
    }

    bool isBcrypt(String h) =>
        h.startsWith(r'$2a$') || h.startsWith(r'$2b$') || h.startsWith(r'$2y$');
    if (isBcrypt(stored)) {
      try {
        final ok = BCrypt.checkpw(password, stored);
        if (ok) {
          AppLogger.d('AuthDao.verifyPassword bcrypt_success');
          return true;
        } else {
          AppLogger.d('AuthDao.verifyPassword bcrypt_mismatch');
        }
      } catch (e) {
        AppLogger.d('AuthDao.verifyPassword bcrypt_error $e');
      }
    }

    // Legacy plain text fallback
    if (stored == password) {
      // Upgrade to bcrypt
      final newHash = BCrypt.hashpw(password, BCrypt.gensalt());
      await updatePasswordHash(userId, newHash);
      AppLogger.d(
        'AuthDao.verifyPassword legacy_plaintext_match upgraded_to_bcrypt',
      );
      return true;
    }
    AppLogger.d('AuthDao.verifyPassword failed_all_branches');
    return false;
  }

  // Debug / maintenance helpers (لا تظهر كلمات المرور الفعلية)
  Future<bool> setPassword(String username, String newPassword) async {
    if (newPassword.trim().length < 4) return false;
    final db = await _dbHelper.database;
    final rows = await db.query(
      'users',
      where: 'username = ? LIMIT 1',
      whereArgs: [username],
      columns: ['id'],
    );
    if (rows.isEmpty) return false;
    final id = rows.first['id'] as int;
    final hash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
    await updatePasswordHash(id, hash);
    AppLogger.d('AuthDao.setPassword success username=$username');
    return true;
  }

  Future<bool> resetPasswordToPlaceholder(String username) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'users',
      where: 'username = ? LIMIT 1',
      whereArgs: [username],
      columns: ['id'],
    );
    if (rows.isEmpty) return false;
    final id = rows.first['id'] as int;
    await db.update(
      'users',
      {'password_hash': 'SET_ME'},
      where: 'id = ?',
      whereArgs: [id],
    );
    AppLogger.d('AuthDao.resetPasswordToPlaceholder username=$username');
    return true;
  }

  /// Returns true if the stored password_hash for [username] is the placeholder 'SET_ME'.
  Future<bool> isPasswordPlaceholder(String username) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'users',
      columns: ['password_hash'],
      where: 'username = ? LIMIT 1',
      whereArgs: [username],
    );
    if (rows.isEmpty) return false;
    return (rows.first['password_hash'] as String?) == 'SET_ME';
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
