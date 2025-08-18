import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/repositories/returns_repository.dart';
import 'package:clothes_pos/data/datasources/returns_dao.dart';
import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';
import 'package:clothes_pos/data/models/payment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Returns E2E', () {
    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final dbDir = await getDatabasesPath();
      final path = p.join(dbDir, 'clothes_pos.db');
      await deleteDatabase(path);
      await setupLocator();
      await sl<DatabaseHelper>().database;
    });

    test('sale then return updates stock and records refund', () async {
      final db = await sl<DatabaseHelper>().database;
      // seed
      final userId = await db.insert('users', {
        'username': 'ret-tester',
        'password_hash': 'x',
      });
      final catId = await db.insert('categories', {'name': 'مرجعات'});
      final parentId = await db.insert('parent_products', {
        'name': 'قميص مرجع',
        'category_id': catId,
      });
      final variantId = await db.insert('product_variants', {
        'parent_product_id': parentId,
        'sku': 'RET-1',
        'size': 'L',
        'color': 'Black',
        'sale_price': 20.0,
        'cost_price': 10.0,
        'quantity': 5,
      });

      // open cash session for sale
      final sessionId = await (await sl<DatabaseHelper>().database).insert(
        'cash_sessions',
        {'opened_by': userId, 'opening_float': 0},
      );

      // create sale
      final sales = sl<SalesRepository>();
      final saleId = await sales.createSale(
        sale: Sale(userId: userId, totalAmount: 0, saleDate: DateTime.now()),
        items: [
          SaleItem(
            saleId: 0,
            variantId: variantId,
            quantity: 2,
            pricePerUnit: 20.0,
            costAtSale: 10.0,
          ),
        ],
        payments: [
          Payment(
            id: null,
            saleId: null,
            amount: 40.0,
            method: PaymentMethod.cash,
            cashSessionId: sessionId,
            createdAt: DateTime.now(),
          ),
        ],
      );

      // perform return of 1 item
      final returnsRepo = sl<ReturnsRepository>();
      final retId = await returnsRepo.createReturn(
        saleId: saleId,
        userId: userId,
        reason: 'Wrong size',
        items: [
          ReturnLineInput(
            saleItemId:
                (await db.query(
                      'sale_items',
                      where: 'sale_id=?',
                      whereArgs: [saleId],
                      limit: 1,
                    )).first['id']
                    as int,
            variantId: variantId,
            quantity: 1,
            refundAmount: 20.0,
          ),
        ],
      );
      expect(retId, greaterThan(0));

      // verify stock
      final stock = await db.query(
        'product_variants',
        where: 'id=?',
        whereArgs: [variantId],
      );
      expect(stock.first['quantity'], 4); // 5 - 2 + 1 = 4

      // verify refund payment recorded
      final payments = await db.query(
        'payments',
        where: 'sale_id=? AND method=?',
        whereArgs: [saleId, 'REFUND'],
      );
      expect(payments.length, 1);
      expect((payments.first['amount'] as num).toDouble(), 20.0);
    });
  });
}
