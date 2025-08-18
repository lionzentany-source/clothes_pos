import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:clothes_pos/main.dart' as app;
import 'package:clothes_pos/core/di/locator.dart';

import 'package:clothes_pos/data/repositories/expense_repository.dart';
import 'package:clothes_pos/data/models/expense.dart';
import 'cleanup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDownAll(() async {
    await cleanupTestData();
  });

  testWidgets('E2E Expenses: create expense and sum by date', (tester) async {
    await app.main();

    final repo = sl<ExpenseRepository>();

    // Pick any existing expense category (seeded) or create one
    final cats = await repo.listCategories();
    final catId = cats.isNotEmpty ? cats.first.id! : await repo.createCategory('تشغيلي');

    // Create an expense for today
    final amt = 37.50;
    final eId = await repo.createExpense(Expense(
      categoryId: catId,
      amount: amt,
      paidVia: 'cash',
      cashSessionId: null,
      date: DateTime.now(),
      description: 'E2E test expense',
    ));
    expect(eId, greaterThan(0));

    // Sum expenses for today (date filter)
    final start = DateTime.now();
    final end = DateTime.now();
    final sum = await repo.sumExpenses(start: start, end: end);
    expect(sum >= amt, true);
  });
}

