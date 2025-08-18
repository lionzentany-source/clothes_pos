import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:clothes_pos/main.dart' as app;
import 'package:clothes_pos/core/di/locator.dart';

import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/data/repositories/category_repository.dart';
import 'package:clothes_pos/data/repositories/auth_repository.dart';

import 'package:clothes_pos/data/models/parent_product.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';
import 'package:clothes_pos/data/models/payment.dart';
import 'cleanup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDownAll(() async {
    await cleanupTestData();
  });

  testWidgets('E2E Cash Session: open -> sale (multi payments) -> summary -> close', (tester) async {
    await app.main();

    final cash = sl<CashRepository>();
    final sales = sl<SalesRepository>();
    final products = sl<ProductRepository>();
    final categories = sl<CategoryRepository>();
    final auth = sl<AuthRepository>();

    final admin = (await auth.listActiveUsers()).first;

    // Ensure product exists with stock (create lightweight one)
    final catId = (await categories.listAll(limit: 1)).first.id!;
    final sku = 'CS_${DateTime.now().millisecondsSinceEpoch}';
    final parentId = await products.createWithVariants(
      ParentProduct(id: null, name: 'CS Prod', description: null, categoryId: catId, supplierId: null, brandId: null, imagePath: null),
      [ProductVariant(id: null, parentProductId: 0, size: 'S', color: 'أسود', sku: sku, barcode: null, rfidTag: null, costPrice: 5, salePrice: 10, reorderPoint: 0, quantity: 3)],
    );
    expect(parentId, greaterThan(0));
    final v = (await products.searchVariants(sku: sku)).first;

    // Open session
    final sessionId = await cash.openSession(openedBy: admin.id, openingFloat: 100.0);
    expect(sessionId, greaterThan(0));

    // Make a sale with mixed payments (cash + card)
    final saleId = await sales.createSale(
      sale: Sale(userId: admin.id, customerId: null, totalAmount: 0, saleDate: DateTime.now(), reference: 'CSS'),
      items: [SaleItem(id: null, saleId: 0, variantId: v.id!, quantity: 3, pricePerUnit: 10, costAtSale: 5)],
      payments: [
        Payment(id: null, saleId: null, amount: 10.0, method: PaymentMethod.cash, cashSessionId: sessionId, createdAt: DateTime.now()),
        Payment(id: null, saleId: null, amount: 20.0, method: PaymentMethod.card, cashSessionId: null, createdAt: DateTime.now()),
      ],
    );
    expect(saleId, greaterThan(0));

    // Session summary should reflect cash 10 plus opening 100 => expected 110
    final summary = await cash.getSessionSummary(sessionId);
    expect(summary['expected_cash'] != null, true);
    final expected = (summary['expected_cash'] as num).toDouble();
    expect(expected, 110.0);

    // Close session with actual equals expected => variance 0
    final variance = await cash.closeSession(sessionId: sessionId, closedBy: admin.id, closingAmount: expected);
    expect(variance, 0.0);
  });
}

