import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/models/customer.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';

/// Data Access Object for Customer operations
class CustomerDao {
  final DatabaseHelper _dbHelper;
  
  CustomerDao(this._dbHelper);

  /// Get all customers with pagination
  Future<List<Customer>> listAll({
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'customers',
        limit: limit,
        offset: offset,
        orderBy: 'name COLLATE NOCASE ASC',
      );
      return rows.map((e) => Customer.fromMap(e)).toList();
    } catch (e, st) {
      AppLogger.e('CustomerDao.listAll failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Search customers by name or phone number
  Future<List<Customer>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final db = await _dbHelper.database;
      final searchTerm = '%$query%';
      final rows = await db.query(
        'customers',
        where: 'name LIKE ? OR phone_number LIKE ?',
        whereArgs: [searchTerm, searchTerm],
        limit: limit,
        offset: offset,
        orderBy: 'name COLLATE NOCASE ASC',
      );
      return rows.map((e) => Customer.fromMap(e)).toList();
    } catch (e, st) {
      AppLogger.e('CustomerDao.search failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Get customer by ID
  Future<Customer?> getById(int id) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'customers',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return Customer.fromMap(rows.first);
    } catch (e, st) {
      AppLogger.e('CustomerDao.getById failed', error: e, stackTrace: st);
      return null;
    }
  }

  /// Get customer by phone number
  Future<Customer?> getByPhoneNumber(String phoneNumber) async {
    try {
      final db = await _dbHelper.database;
      final rows = await db.query(
        'customers',
        where: 'phone_number = ?',
        whereArgs: [phoneNumber],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return Customer.fromMap(rows.first);
    } catch (e, st) {
      AppLogger.e('CustomerDao.getByPhoneNumber failed', error: e, stackTrace: st);
      return null;
    }
  }

  /// Insert a new customer
  Future<int> insert(Customer customer) async {
    try {
      final db = await _dbHelper.database;
      return await db.insert('customers', customer.toMap());
    } catch (e, st) {
      AppLogger.e('CustomerDao.insert failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Update an existing customer
  Future<void> update(Customer customer) async {
    try {
      if (customer.id == null) {
        throw ArgumentError('Customer ID cannot be null for update');
      }
      final db = await _dbHelper.database;
      await db.update(
        'customers',
        customer.toMap(),
        where: 'id = ?',
        whereArgs: [customer.id],
      );
    } catch (e, st) {
      AppLogger.e('CustomerDao.update failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Delete a customer by ID
  Future<void> delete(int id) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'customers',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      AppLogger.e('CustomerDao.delete failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Check if a phone number already exists (for validation)
  Future<bool> phoneNumberExists(String phoneNumber, {int? excludeId}) async {
    try {
      final db = await _dbHelper.database;
      String where = 'phone_number = ?';
      List<Object?> whereArgs = [phoneNumber];
      
      if (excludeId != null) {
        where += ' AND id != ?';
        whereArgs.add(excludeId);
      }
      
      final rows = await db.query(
        'customers',
        where: where,
        whereArgs: whereArgs,
        limit: 1,
      );
      return rows.isNotEmpty;
    } catch (e, st) {
      AppLogger.e('CustomerDao.phoneNumberExists failed', error: e, stackTrace: st);
      return false;
    }
  }

  /// Get customer count
  Future<int> getCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
      return (result.first['count'] as int?) ?? 0;
    } catch (e, st) {
      AppLogger.e('CustomerDao.getCount failed', error: e, stackTrace: st);
      return 0;
    }
  }

  /// Get customers with recent sales (for analytics)
  Future<List<Map<String, Object?>>> getCustomersWithSalesStats({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final db = await _dbHelper.database;
      String whereClause = '';
      List<Object?> whereArgs = [];
      
      if (startDate != null || endDate != null) {
        whereClause = 'WHERE ';
        if (startDate != null) {
          whereClause += 's.sale_date >= ?';
          whereArgs.add(startDate.toIso8601String());
        }
        if (endDate != null) {
          if (startDate != null) whereClause += ' AND ';
          whereClause += 's.sale_date <= ?';
          whereArgs.add(endDate.toIso8601String());
        }
      }
      
      final query = '''
        SELECT 
          c.id,
          c.name,
          c.phone_number,
          COUNT(s.id) as total_sales,
          COALESCE(SUM(s.total_amount), 0) as total_spent,
          MAX(s.sale_date) as last_sale_date
        FROM customers c
        LEFT JOIN sales s ON c.id = s.customer_id $whereClause
        GROUP BY c.id, c.name, c.phone_number
        ORDER BY total_spent DESC, c.name COLLATE NOCASE ASC
        LIMIT ? OFFSET ?
      ''';
      
      whereArgs.addAll([limit, offset]);
      return await db.rawQuery(query, whereArgs);
    } catch (e, st) {
      AppLogger.e('CustomerDao.getCustomersWithSalesStats failed', error: e, stackTrace: st);
      return [];
    }
  }
}
