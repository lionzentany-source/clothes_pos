import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:intl/date_symbol_data_local.dart';

// App imports
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/core/di/locator.dart';

import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';
import 'package:clothes_pos/data/models/payment.dart';
import 'package:clothes_pos/core/printing/receipt_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Checkout E2E', () {
    setUpAll(() async {
      // Ensure a fresh on-disk DB used by DatabaseHelper
      // Initialize sqflite_common_ffi for desktop
      // ignore: invalid_use_of_visible_for_testing_member
      sqfliteFfiInit();
      // ignore: invalid_use_of_visible_for_testing_member
      databaseFactory = databaseFactoryFfi;
      final dbDir = await getDatabasesPath();
      final path = p.join(dbDir, 'clothes_pos.db');
      await deleteDatabase(path);
      await setupLocator();
      // Touch the database to trigger onCreate
      await sl<DatabaseHelper>().database;
      // Initialize Arabic locale for date formatting used in receipt
      await initializeDateFormatting('ar');
    });

    tearDownAll(() async {
      final dbDir = await getDatabasesPath();
      final path = p.join(dbDir, 'clothes_pos.db');
      await deleteDatabase(path);
    });

    test('Create sale, update inventory/cash, and generate receipt', () async {
      // Seed minimal data
      // final productRepo = sl<ProductRepository>();
      final salesRepo = sl<SalesRepository>();
      final cashRepo = sl<CashRepository>();
      final settings = sl<SettingsRepository>();

      // Create required base rows using raw access
      final db = await sl<DatabaseHelper>().database;
      final catId = await db.insert('categories', {'name': 'تصنيف-اختبار'});
      await db.insert('brands', {'name': 'ACME'});
      final userId = await db.insert('users', {
        'username': 'tester',
        'password_hash': 'x',
      });

      final parentId = await db.insert('parent_products', {
        'name': 'قميص أبيض',
        'category_id': catId,
      });
      final variantId = await db.insert('product_variants', {
        'parent_product_id': parentId,
        'sku': 'SKU-1',
        'size': 'M',
        'color': 'White',
        'sale_price': 15.0,
        'cost_price': 8.0,
        'quantity': 10,
      });

      // Open cash session
      final sessionId = await cashRepo.openSession(
        openedBy: userId,
        openingFloat: 0,
      );

      // Inject guards on SalesRepository
      sl<SalesRepository>().setGuards(
        permission: (_) => true,
        openSession: () async => {'id': sessionId},
      );

      // Perform sale
      final saleId = await salesRepo.createSale(
        sale: Sale(userId: userId, totalAmount: 0, saleDate: DateTime.now()),
        items: [
          SaleItem(
            saleId: 0,
            variantId: variantId,
            quantity: 2,
            pricePerUnit: 15.0,
            costAtSale: 8.0,
          ),
        ],
        payments: [
          Payment(
            id: null,
            saleId: null,
            amount: 30.0,
            method: PaymentMethod.cash,
            cashSessionId: sessionId,
            createdAt: DateTime.now(),
          ),
        ],
      );

      expect(saleId, greaterThan(0));

      // Verify inventory decreased
      final stockRow = await db.query(
        'product_variants',
        where: 'id = ?',
        whereArgs: [variantId],
      );
      expect(stockRow.first['quantity'], 8);

      // Verify cash IN movement recorded
      final cashRows = await db.query(
        'cash_movements',
        where: 'cash_session_id = ?',
        whereArgs: [sessionId],
      );
      expect(cashRows.length, 1);
      expect((cashRows.first['amount'] as num).toDouble(), 30.0);

      // Configure minimal settings for receipt
      await settings.set('store_name', 'Clothes POS');
      await settings.set('store_phone', '0912345678');

      // Generate receipt PDF
      final receipt = await ReceiptPdfService().generate(saleId, locale: 'ar');
      expect(await receipt.exists(), true);
      final bytes = await receipt.readAsBytes();
      expect(bytes.length, greaterThan(1000));
    });
  });
}
