import 'package:clothes_pos/data/datasources/expense_dao.dart';
import 'package:clothes_pos/data/models/expense.dart';
import 'package:clothes_pos/data/models/expense_category.dart';

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

  Future<int> createExpense(Expense e) => dao.createExpense(e);
  Future<void> updateExpense(Expense e) => dao.updateExpense(e);
  Future<void> deleteExpense(int id) => dao.deleteExpense(id);
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
