import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

import 'package:clothes_pos/core/di/locator.dart' as app;
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/repositories/returns_repository.dart';
import 'package:clothes_pos/data/datasources/returns_dao.dart';
import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';
import 'package:clothes_pos/data/models/payment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mixed payments return E2E', () {
    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final dbDir = await getDatabasesPath();
      final path = p.join(dbDir, 'clothes_pos.db');
      await deleteDatabase(path);
      await app.setupLocator();
      await sl<DatabaseHelper>().database;
    });

    test('sale with cash+card then partial return with refund', () async {
      final db = await sl<DatabaseHelper>().database;
      final sales = sl<SalesRepository>();
      final returnsRepo = sl<ReturnsRepository>();
      final cashRepo = sl<CashRepository>();

      final userId = await db.insert('users', {'username': 'mix', 'password_hash': 'x'});
      final catId = await db.insert('categories', {'name': 'فئة'});
      final parentId = await db.insert('parent_products', {'name': 'جاكيت', 'category_id': catId});
      final variantId = await db.insert('product_variants', {
        'parent_product_id': parentId,
        'sku': 'MIX-1',
        'size': 'L',
        'color': 'Gray',
        'sale_price': 50.0,
        'cost_price': 30.0,
        'quantity': 10,
      });

      final sessionId = await cashRepo.openSession(openedBy: userId, openingFloat: 0);

      // Sale 2 items: total 100. Payments: 60 cash, 40 card
      final saleId = await sales.createSale(
        sale: Sale(userId: userId, totalAmount: 0, saleDate: DateTime.now()),
        items: [SaleItem(saleId: 0, variantId: variantId, quantity: 2, pricePerUnit: 50.0, costAtSale: 30.0)],
        payments: [
          Payment(id: null, saleId: null, amount: 60.0, method: PaymentMethod.cash, cashSessionId: sessionId, createdAt: DateTime.now()),
          Payment(id: null, saleId: null, amount: 40.0, method: PaymentMethod.card, cashSessionId: null, createdAt: DateTime.now()),
        ],
      );

      // Return 1 item at 50, pay refund (recorded as REFUND payment)
      final saleItemId = (await db.query('sale_items', where: 'sale_id=?', whereArgs: [saleId], limit: 1)).first['id'] as int;
      final retId = await returnsRepo.createReturn(
        saleId: saleId,
        userId: userId,
        reason: 'size',
        items: [ReturnLineInput(saleItemId: saleItemId, variantId: variantId, quantity: 1, refundAmount: 50.0)],
      );
      expect(retId, greaterThan(0));

      // Stock: 10 - 2 + 1 = 9
      final stockRow = await db.query('product_variants', where: 'id=?', whereArgs: [variantId]);
      expect(stockRow.first['quantity'], 9);

      // Verify refund payment recorded (method=REFUND for saleId)
      final refunds = await db.query('payments', where: 'sale_id=? AND method=?', whereArgs: [saleId, 'REFUND']);
      expect(refunds.length, 1);
      expect((refunds.first['amount'] as num).toDouble(), 50.0);
    });
  });
}

