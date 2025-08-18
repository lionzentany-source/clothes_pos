import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:clothes_pos/main.dart' as app;
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/core/db/database_helper.dart';

import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/data/repositories/purchase_repository.dart';
import 'package:clothes_pos/data/repositories/supplier_repository.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/repositories/returns_repository.dart';
import 'package:clothes_pos/data/repositories/expense_repository.dart';
import 'package:clothes_pos/data/repositories/category_repository.dart';
import 'package:clothes_pos/data/repositories/auth_repository.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';

import 'package:clothes_pos/data/models/parent_product.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/data/models/purchase_invoice.dart';
import 'package:clothes_pos/data/models/purchase_invoice_item.dart';
import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';
import 'package:clothes_pos/data/models/payment.dart';
import 'package:clothes_pos/data/models/expense.dart';
import 'package:clothes_pos/data/datasources/returns_dao.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UAT 2 days: purchase/sale/return/expense and SQL cross-checks', (
    tester,
  ) async {
    await app.main();

    final products = sl<ProductRepository>();
    final purchases = sl<PurchaseRepository>();
    final suppliers = sl<SupplierRepository>();
    final sales = sl<SalesRepository>();
    final returnsRepo = sl<ReturnsRepository>();
    final expenses = sl<ExpenseRepository>();
    final categories = sl<CategoryRepository>();
    final auth = sl<AuthRepository>();
    final cash = sl<CashRepository>();

    final admin = (await auth.listActiveUsers()).first;

    final now = DateTime.now();
    final day1 = now.subtract(const Duration(days: 1));
    final day2 = now;

    final catId = (await categories.listAll(limit: 1)).first.id!;
    final supplierId = await suppliers.create(
      'UAT Supplier ${now.millisecondsSinceEpoch}',
    );

    final sku = 'UAT_${now.millisecondsSinceEpoch}';
    final parentId = await products.createWithVariants(
      ParentProduct(
        id: null,
        name: 'UAT Prod',
        description: 'UAT two-day flow',
        categoryId: catId,
        supplierId: supplierId,
        brandId: null,
        imagePath: null,
      ),
      [
        ProductVariant(
          id: null,
          parentProductId: 0,
          size: 'M',
          color: 'أسود',
          sku: sku,
          barcode: null,
          rfidTag: null,
          costPrice: 8.0,
          salePrice: 15.0,
          reorderPoint: 0,
          quantity: 0,
        ),
      ],
    );
    expect(parentId, greaterThan(0));
    final variantId = (await products.searchVariants(sku: sku)).first.id!;

    // Day 1: purchase 10 at 8, sell 3 at 15, expense 20 cash
    await purchases.createInvoiceWithRfids(
      PurchaseInvoice(
        supplierId: supplierId,
        reference: 'UAT1',
        receivedDate: day1,
      ),
      [
        PurchaseInvoiceItem(
          purchaseInvoiceId: 0,
          variantId: variantId,
          quantity: 10,
          costPrice: 8.0,
        ),
      ],
      [<String>[]],
    );
    final sale1Id = await sales.createSale(
      sale: Sale(
        userId: admin.id,
        customerId: null,
        totalAmount: 0,
        saleDate: day1,
        reference: 'UAT-S1',
      ),
      items: [
        SaleItem(
          id: null,
          saleId: 0,
          variantId: variantId,
          quantity: 3,
          pricePerUnit: 15.0,
          costAtSale: 8.0,
        ),
      ],
      payments: [
        Payment(
          id: null,
          saleId: null,
          amount: 45.0,
          method: PaymentMethod.cash,
          cashSessionId: null,
          createdAt: day1,
        ),
      ],
    );
    expect(sale1Id, greaterThan(0));
    final cat =
        (await expenses.listCategories()).firstOrNull?.id ??
        await expenses.createCategory('تشغيلي');
    final exp1Id = await expenses.createExpense(
      Expense(
        categoryId: cat,
        amount: 20.0,
        paidVia: 'cash',
        cashSessionId: null,
        date: day1,
        description: 'UAT day1',
      ),
    );
    expect(exp1Id, greaterThan(0));

    // Day 2: purchase 5 at 9, sell 4 at 16 (10 cash + 54 card), return 1 from sale1, expense 12 cash linked to session
    await purchases.createInvoiceWithRfids(
      PurchaseInvoice(
        supplierId: supplierId,
        reference: 'UAT2',
        receivedDate: day2,
      ),
      [
        PurchaseInvoiceItem(
          purchaseInvoiceId: 0,
          variantId: variantId,
          quantity: 5,
          costPrice: 9.0,
        ),
      ],
      [<String>[]],
    );

    final sessionId = await cash.openSession(
      openedBy: admin.id,
      openingFloat: 50.0,
    );
    expect(sessionId, greaterThan(0));

    final sale2Id = await sales.createSale(
      sale: Sale(
        userId: admin.id,
        customerId: null,
        totalAmount: 0,
        saleDate: day2,
        reference: 'UAT-S2',
      ),
      items: [
        SaleItem(
          id: null,
          saleId: 0,
          variantId: variantId,
          quantity: 4,
          pricePerUnit: 16.0,
          costAtSale: 9.0,
        ),
      ],
      payments: [
        Payment(
          id: null,
          saleId: null,
          amount: 30.0,
          method: PaymentMethod.cash,
          cashSessionId: sessionId,
          createdAt: day2,
        ),
        Payment(
          id: null,
          saleId: null,
          amount: 34.0,
          method: PaymentMethod.card,
          cashSessionId: null,
          createdAt: day2,
        ),
      ],
    );
    expect(sale2Id, greaterThan(0));

    // Return 1 item from sale1 (refund recorded with created_at = now by DAO; that's day2)
    final returnables = await returnsRepo.getReturnableItems(sale1Id);
    final line = returnables.firstWhere(
      (r) => (r['variant_id'] as int) == variantId,
    );
    final saleItemId = line['sale_item_id'] as int;
    final retId = await returnsRepo.createReturn(
      saleId: sale1Id,
      userId: admin.id,
      reason: 'UAT sizing',
      items: [
        ReturnLineInput(
          saleItemId: saleItemId,
          variantId: variantId,
          quantity: 1,
          refundAmount: 15.0,
        ),
      ],
    );
    expect(retId, greaterThan(0));

    final exp2Id = await expenses.createExpense(
      Expense(
        categoryId: cat,
        amount: 12.0,
        paidVia: 'cash',
        cashSessionId: sessionId,
        date: day2,
        description: 'UAT day2',
      ),
    );
    expect(exp2Id, greaterThan(0));

    // Cross-check via SQL
    final db = await DatabaseHelper.instance.database;

    // Payments net by day (refund as negative) limited to our sales only
    final payRows = await db.rawQuery(
      '''
      SELECT date(p.created_at) as d,
             SUM(CASE WHEN p.method = 'REFUND' THEN -p.amount ELSE p.amount END) AS net
      FROM payments p
      WHERE p.sale_id IN (?, ?)
      GROUP BY date(p.created_at)
      ''',
      [sale1Id, sale2Id],
    );
    // Build map
    final payMap = {
      for (final r in payRows)
        (r['d'] as String): ((r['net'] as num?)?.toDouble() ?? 0.0),
    };
    final d1key = DateTime(
      day1.year,
      day1.month,
      day1.day,
    ).toIso8601String().substring(0, 10);
    final d2key = DateTime(
      day2.year,
      day2.month,
      day2.day,
    ).toIso8601String().substring(0, 10);

    expect(payMap[d1key], 45.0);
    expect(payMap[d2key], 49.0); // 30 cash + 34 card - 15 refund

    // Expenses by day
    final expRows = await db.rawQuery('''
      SELECT date(date) as d, SUM(amount) total
      FROM expenses
      GROUP BY date(date)
      ''');
    final expMap = {
      for (final r in expRows)
        (r['d'] as String): ((r['total'] as num?)?.toDouble() ?? 0.0),
    };
    expect(expMap[d1key]! >= 20.0, true);
    expect(expMap[d2key]! >= 12.0, true);

    // Stock check: expected 9 (10 + 5 - 3 - 4 + 1)
    final stockRows = await db.rawQuery(
      'SELECT quantity FROM product_variants WHERE id = ?',
      [variantId],
    );
    final qty = (stockRows.first['quantity'] as num).toInt();
    expect(qty, 9);

    // Cash session expected cash: 50 opening + 30 cash sales - 12 cash expense = 68
    final summary = await cash.getSessionSummary(sessionId);
    final expectedCash = (summary['expected_cash'] as num).toDouble();
    expect(expectedCash, 68.0);
    final variance = await cash.closeSession(
      sessionId: sessionId,
      closedBy: admin.id,
      closingAmount: expectedCash,
    );
    expect(variance, 0.0);
  });
}
