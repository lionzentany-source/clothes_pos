import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:clothes_pos/main.dart' as app;
import 'package:clothes_pos/core/di/locator.dart';

import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/data/repositories/purchase_repository.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/repositories/returns_repository.dart';
import 'package:clothes_pos/data/repositories/reports_repository.dart';
import 'package:clothes_pos/data/repositories/auth_repository.dart';

import 'package:clothes_pos/data/models/parent_product.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/data/models/purchase_invoice.dart';
import 'package:clothes_pos/data/models/purchase_invoice_item.dart';
import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';
import 'package:clothes_pos/data/models/payment.dart';
import 'package:clothes_pos/data/datasources/returns_dao.dart';
import 'cleanup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDownAll(() async {
    await cleanupTestData();
  });

  testWidgets('E2E Returns: sale then return and verify stock/report', (tester) async {
    await app.main();

    final products = sl<ProductRepository>();
    final purchases = sl<PurchaseRepository>();
    final sales = sl<SalesRepository>();
    final returnsRepo = sl<ReturnsRepository>();
    final reports = sl<ReportsRepository>();
    final auth = sl<AuthRepository>();

    final admin = (await auth.listActiveUsers()).firstWhere((u) => u.username == 'admin');

    final suffix = DateTime.now().millisecondsSinceEpoch.toString();
    final sku = 'RET_$suffix';

    // Create product + variant
    final parentId = await products.createWithVariants(
      ParentProduct(
        id: null,
        name: 'RET Product $suffix',
        description: 'Return flow',
        categoryId: 1, // seeded
        supplierId: null,
        brandId: null,
        imagePath: null,
      ),
      [
        ProductVariant(
          id: null,
          parentProductId: 0,
          size: 'M',
          color: 'أبيض',
          sku: sku,
          barcode: null,
          rfidTag: null,
          costPrice: 10,
          salePrice: 20,
          reorderPoint: 0,
          quantity: 0,
        ),
      ],
    );
    expect(parentId, greaterThan(0));

    final variantId = (await products.searchVariants(sku: sku)).first.id!;

    // Purchase 3 items
    await purchases.createInvoiceWithRfids(
      PurchaseInvoice(supplierId: 1, reference: 'RINV-$suffix', receivedDate: DateTime.now()),
      [PurchaseInvoiceItem(purchaseInvoiceId: 0, variantId: variantId, quantity: 3, costPrice: 9)],
      [<String>[]],
    );

    // Sell 2 items
    final saleId = await sales.createSale(
      sale: Sale(userId: admin.id, totalAmount: 0, saleDate: DateTime.now(), reference: 'RS-$suffix'),
      items: [SaleItem(id: null, saleId: 0, variantId: variantId, quantity: 2, pricePerUnit: 20, costAtSale: 9)],
      payments: [Payment(id: null, saleId: null, amount: 40, method: PaymentMethod.cash, cashSessionId: null, createdAt: DateTime.now())],
    );
    expect(saleId, greaterThan(0));

    // Return 1 item from the sale
    final returnables = await returnsRepo.getReturnableItems(saleId);
    expect(returnables.isNotEmpty, true);
    final line = returnables.firstWhere((r) => (r['variant_id'] as int) == variantId);
    final saleItemId = line['sale_item_id'] as int;
    final retId = await returnsRepo.createReturn(
      saleId: saleId,
      userId: admin.id,
      reason: 'size issue',
      items: [ReturnLineInput(saleItemId: saleItemId, variantId: variantId, quantity: 1, refundAmount: 20)],
    );
    expect(retId, greaterThan(0));

    // Verify stock back to 2 (3 purchased - 2 sold + 1 returned = 2)
    final stock = await reports.stockStatus();
    final row = stock.firstWhere((r) => (r['sku']?.toString() ?? '') == sku, orElse: () => <String, Object?>{});
    expect(row.isNotEmpty, true);
    expect((row['quantity'] as num).toInt(), 2);
  });
}

