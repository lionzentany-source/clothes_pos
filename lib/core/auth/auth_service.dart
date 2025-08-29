import 'package:sqflite/sqflite.dart';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:bcrypt/bcrypt.dart';

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  // This placeholder MUST match the one in AuthDao to work correctly.
  static const String initialPasswordPlaceholder = 'SET_ME';

  Future<void> setupInitialAdminUserIfNeeded() async {
    try {
      // First, ensure all permissions from AppPermissions are in the database
      await _ensurePermissionsSeeded();
      
      final hasUsers = await _anyUserExists();
      if (!hasUsers) {
        AppLogger.i('No users found. Creating initial admin user...');
        await _createInitialAdminUser();
      } else {
        // Even if users exist, ensure admin user has all current permissions
        await _refreshAdminPermissions();
      }
    } catch (e, st) {
      AppLogger.e('Error during initial admin user setup', error: e, stackTrace: st);
    }
  }

  Future<void> _refreshAdminPermissions() async {
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      // Find admin role
      final adminRoleId = await _getOrCreateAdminRole(txn);
      
      // Ensure admin role has all current permissions
      await _ensureAdminHasAllPermissions(txn, adminRoleId);
      
      AppLogger.i('Refreshed admin permissions to include all current permissions');
    });
  }

  Future<void> _ensurePermissionsSeeded() async {
    final db = await _dbHelper.database;
    
    // Map of permission codes to their Arabic descriptions
    final permissionDescriptions = {
      AppPermissions.viewReports: 'عرض التقارير',
      AppPermissions.editProducts: 'تعديل المنتجات',
      AppPermissions.performSales: 'إجراء المبيعات',
      AppPermissions.performPurchases: 'إجراء المشتريات',
      AppPermissions.adjustStock: 'تعديل المخزون',
      AppPermissions.manageUsers: 'إدارة المستخدمين',
      AppPermissions.manageCustomers: 'إدارة العملاء',
      AppPermissions.recordExpenses: 'تسجيل المصروفات',
    };
    
    // Insert permissions that don't exist
    for (final permission in AppPermissions.all) {
      final description = permissionDescriptions[permission] ?? permission;
      try {
        await db.insert(
          'permissions',
          {
            'code': permission,
            'description': description,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        AppLogger.d('Ensured permission exists: $permission');
      } catch (e) {
        AppLogger.w('Failed to insert permission $permission: $e');
      }
    }
  }

  Future<bool> _anyUserExists() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM users'),
    );
    return (count ?? 0) > 0;
  }

  Future<void> _createInitialAdminUser() async {
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      // 1. Ensure Admin role exists
      final adminRoleId = await _getOrCreateAdminRole(txn);
      
      // 2. Create admin user
      final userId = await txn.insert(
        'users',
        {
          'username': 'admin',
          'password_hash': initialPasswordPlaceholder,
          'full_name': 'Administrator',
          'is_active': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      
      // 3. Assign admin role to user
      if (userId != 0) {
        await txn.insert('user_roles', {
          'user_id': userId,
          'role_id': adminRoleId,
        });
        AppLogger.i('Successfully created initial "admin" user and assigned admin role.');
      }
      
      // 4. Ensure admin role has ALL current permissions
      await _ensureAdminHasAllPermissions(txn, adminRoleId);
    });
  }

  Future<int> _getOrCreateAdminRole(Transaction txn) async {
    // Try to find existing admin role (case-insensitive)
    final List<Map<String, dynamic>> result = await txn.query(
      'roles',
      columns: ['id'],
      where: 'LOWER(name) = ?',
      whereArgs: ['admin'],
    );
    
    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    
    // Create admin role if it doesn't exist
    final roleId = await txn.insert('roles', {'name': 'Admin'});
    AppLogger.i('Created Admin role with ID: $roleId');
    return roleId;
  }
  
  Future<void> _ensureAdminHasAllPermissions(Transaction txn, int adminRoleId) async {
    // Get all permission IDs from the database
    final permissionRows = await txn.query('permissions', columns: ['id']);
    final permissionIds = permissionRows.map((row) => row['id'] as int).toList();
    
    // Assign all permissions to admin role (ignore conflicts)
    for (final permissionId in permissionIds) {
      await txn.insert(
        'role_permissions',
        {
          'role_id': adminRoleId,
          'permission_id': permissionId,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    
    AppLogger.i('Ensured Admin role has all ${permissionIds.length} permissions');
  }

  Future<int?> _getAdminRoleId(Database db) async {
    final List<Map<String, dynamic>> result = await db.query(
      'roles',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: ['admin'],
    );
    if (result.isNotEmpty) {
      return result.first['id'] as int?;
    }
    return null;
  }

  Future<bool> hasAdminUser() async {
    try {
      final db = await _dbHelper.database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM users WHERE is_active = 1'),
      );
      AppLogger.d('AuthService.hasAdminUser: User count = $count');
      return (count ?? 0) > 0;
    } catch (e, st) {
      AppLogger.e('Error checking for admin user', error: e, stackTrace: st);
      return false;
    }
  }

  Future<void> createAdminUser(String username, String password) async {
    try {
      final db = await _dbHelper.database;
      final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

      final adminRoleId = await _getAdminRoleId(db);
      if (adminRoleId == null) {
        throw Exception('Admin role not found. Cannot create admin user.');
      }

      final userId = await db.insert(
        'users',
        {
          'username': username,
          'password_hash': passwordHash,
          'full_name': username,
          'is_active': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await db.insert('user_roles', {
        'user_id': userId,
        'role_id': adminRoleId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      AppLogger.i('Admin user "$username" created successfully.');
    } catch (e, st) {
      AppLogger.e('Error creating admin user', error: e, stackTrace: st);
      rethrow;
    }
  }
}