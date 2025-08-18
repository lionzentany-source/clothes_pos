import 'package:clothes_pos/data/datasources/audit_dao.dart';

class AuditRepository {
  final AuditDao dao;
  AuditRepository(this.dao);

  Future<void> logChange({
    int? userId,
    required String entity,
    required String field,
    String? oldValue,
    String? newValue,
  }) async {
    await dao.insertEvent(
      userId: userId,
      entity: entity,
      field: field,
      oldValue: oldValue,
      newValue: newValue,
    );
  }
}

