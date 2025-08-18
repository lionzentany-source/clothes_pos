import 'package:clothes_pos/data/datasources/cash_dao.dart';

class CashRepository {
  final CashDao dao;
  CashRepository(this.dao);

  Future<Map<String, Object?>?> getOpenSession() => dao.getOpenSession();
  Future<int> openSession({
    required int openedBy,
    required double openingFloat,
  }) => dao.openSession(openedBy: openedBy, openingFloat: openingFloat);
  Future<double> closeSession({
    required int sessionId,
    required int closedBy,
    required double closingAmount,
  }) => dao.closeSession(
    sessionId: sessionId,
    closedBy: closedBy,
    closingAmount: closingAmount,
  );
  Future<void> cashIn({
    required int sessionId,
    required double amount,
    String? reason,
  }) => dao.addMovement(
    sessionId: sessionId,
    amount: amount,
    type: 'IN',
    reason: reason,
  );
  Future<void> cashOut({
    required int sessionId,
    required double amount,
    String? reason,
  }) => dao.addMovement(
    sessionId: sessionId,
    amount: amount,
    type: 'OUT',
    reason: reason,
  );
  Future<Map<String, Object?>> getSessionSummary(int sessionId) =>
      dao.getSessionSummary(sessionId);
}
