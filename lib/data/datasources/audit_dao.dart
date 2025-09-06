import 'package:clothes_pos/core/db/database_helper.dart';

class AuditDao {
  final DatabaseHelper _dbHelper;
  AuditDao(this._dbHelper);

  Future<int> insertEvent({
    int? userId,
    required String entity,
    required String field,
    String? oldValue,
    String? newValue,
  }) async {
    final db = await _dbHelper.database;
    return db.insert('audit_events', {
      'user_id': userId,
      'entity': entity,
      'field': field,
      'old_value': oldValue,
      'new_value': newValue,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}

