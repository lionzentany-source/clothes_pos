import 'package:clothes_pos/data/datasources/expense_dao.dart';
import 'package:clothes_pos/data/models/expense.dart';
import 'package:clothes_pos/data/models/expense_category.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/audit_repository.dart';

class ExpenseRepository {
  final ExpenseDao dao;
  ExpenseRepository(this.dao);

  Future<List<ExpenseCategory>> listCategories({bool onlyActive = true}) =>
      dao.listCategories(onlyActive: onlyActive);
  Future<int> createCategory(String name) => dao.createCategory(name);
  Future<void> renameCategory(int id, String newName) =>
      dao.renameCategory(id, newName);
  Future<void> setCategoryActive(int id, bool active) =>
      dao.setCategoryActive(id, active);

  Future<int> createExpense(Expense e, {int? userId}) async {
    final id = await dao.createExpense(e);
    try {
      await sl<AuditRepository>().logChange(
        userId: userId,
        entity: 'expense:$id',
        field: 'create',
        newValue: '${e.amount}',
      );
    } catch (_) {}
    return id;
  }

  Future<void> updateExpense(Expense e, {int? userId}) async {
    final oldAmt = e.amount; // we don't fetch old row for simplicity
    await dao.updateExpense(e);
    try {
      await sl<AuditRepository>().logChange(
        userId: userId,
        entity: 'expense:${e.id}',
        field: 'update',
        newValue: '$oldAmt',
      );
    } catch (_) {}
  }

  Future<void> deleteExpense(int id, {int? userId}) async {
    await dao.deleteExpense(id);
    try {
      await sl<AuditRepository>().logChange(
        userId: userId,
        entity: 'expense:$id',
        field: 'delete',
      );
    } catch (_) {}
  }

  Future<List<Expense>> listExpenses({
    DateTime? start,
    DateTime? end,
    int? categoryId,
    String? paidVia,
    int limit = 500,
    int offset = 0,
  }) => dao.listExpenses(
    start: start,
    end: end,
    categoryId: categoryId,
    paidVia: paidVia,
    limit: limit,
    offset: offset,
  );
  Future<double> sumExpenses({
    DateTime? start,
    DateTime? end,
    int? categoryId,
  }) => dao.sumExpenses(start: start, end: end, categoryId: categoryId);
  Future<Map<String, double>> sumByCategory({DateTime? start, DateTime? end}) =>
      dao.sumByCategory(start: start, end: end);
}
