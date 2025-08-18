import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

import 'package:clothes_pos/core/di/locator.dart' as app;
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';
import 'package:clothes_pos/data/models/payment.dart';
import 'package:clothes_pos/data/repositories/expense_repository.dart';
import 'package:clothes_pos/data/models/expense.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cash close variance E2E', () {
    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final dbDir = await getDatabasesPath();
      final path = p.join(dbDir, 'clothes_pos.db');
      await deleteDatabase(path);
      await app.setupLocator();
      await sl<DatabaseHelper>().database;
    });

    test('open session, sale cash, movements/expenses, close & verify variance', () async {
      final db = await sl<DatabaseHelper>().database;
      final cash = sl<CashRepository>();
      final sales = sl<SalesRepository>();
      final expenses = sl<ExpenseRepository>();

      final userId = await db.insert('users', {'username': 'variance', 'password_hash': 'x'});
      final catId = await db.insert('categories', {'name': 'فئة'});
      final parentId = await db.insert('parent_products', {'name': 'قميص', 'category_id': catId});
      final variantId = await db.insert('product_variants', {
        'parent_product_id': parentId,
        'sku': 'V-1',
        'size': 'M',
        'color': 'Blue',
        'sale_price': 10.0,
        'cost_price': 6.0,
        'quantity': 5,
      });

      final sessionId = await cash.openSession(openedBy: userId, openingFloat: 100);

      // Sale cash 20.0
      final saleId = await sales.createSale(
        sale: Sale(userId: userId, totalAmount: 0, saleDate: DateTime.now()),
        items: [SaleItem(saleId: 0, variantId: variantId, quantity: 2, pricePerUnit: 10.0, costAtSale: 6.0)],
        payments: [Payment(id: null, saleId: null, amount: 20.0, method: PaymentMethod.cash, cashSessionId: sessionId, createdAt: DateTime.now())],
      );
      expect(saleId, greaterThan(0));

      // Cash IN (misc) 30, Cash OUT 5
      await cash.cashIn(sessionId: sessionId, amount: 30, reason: 'Misc IN');
      await cash.cashOut(sessionId: sessionId, amount: 5, reason: 'Misc OUT');

      // Expense cash: 12.5
      final cat = (await expenses.listCategories()).first.id!;
      await expenses.createExpense(Expense(categoryId: cat, amount: 12.5, paidVia: 'cash', cashSessionId: sessionId, date: DateTime.now(), description: 'Ops'));

      // Expected cash = opening 100 + sales cash 20 + IN 30 - OUT 5 - cash expenses 12.5 = 132.5
      // If we count exactly 132.0 physically, variance should be -0.5
      final variance = await cash.closeSession(sessionId: sessionId, closedBy: userId, closingAmount: 132.0);
      expect(variance, closeTo(-0.5, 0.0001));
    });
  });
}

