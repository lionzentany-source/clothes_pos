import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:clothes_pos/main.dart' as app;
import 'package:clothes_pos/core/di/locator.dart';

import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/data/repositories/supplier_repository.dart';
import 'package:clothes_pos/data/repositories/purchase_repository.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/repositories/reports_repository.dart';
import 'package:clothes_pos/data/repositories/category_repository.dart';
import 'package:clothes_pos/data/repositories/auth_repository.dart';

import 'package:clothes_pos/data/models/parent_product.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/data/models/purchase_invoice.dart';
import 'package:clothes_pos/data/models/purchase_invoice_item.dart';
import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';
import 'package:clothes_pos/data/models/payment.dart';
import 'cleanup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDownAll(() async {
    // Clean test data
    await cleanupTestData();
  });

  testWidgets('E2E via repos: create product -> purchase -> sale -> verify reports', (tester) async {
    // Boot app to initialize DB and DI
    await app.main();

    final products = sl<ProductRepository>();
    final suppliers = sl<SupplierRepository>();
    final purchases = sl<PurchaseRepository>();
    final sales = sl<SalesRepository>();
    final reports = sl<ReportsRepository>();
    final categories = sl<CategoryRepository>();
    final auth = sl<AuthRepository>();

    // Resolve admin user id
    final users = await auth.listActiveUsers();
    final admin = users.firstWhere((u) => u.username == 'admin');

    // Unique values for this run
    final suffix = DateTime.now().millisecondsSinceEpoch.toString();
    final sku = 'E2E_$suffix';
    final productName = 'E2E Product $suffix';
    final supplierName = 'Supplier $suffix';

    // Ensure we have a category id
    final cats = await categories.listAll(limit: 1);
    expect(cats.isNotEmpty, true, reason: 'At least one category must be seeded');
    final categoryId = cats.first.id!;

    // 1) Create product + variant
    final parent = ParentProduct(
      id: null,
      name: productName,
      description: 'E2E scenario',
      categoryId: categoryId,
      supplierId: null,
      brandId: null,
      imagePath: null,
    );
    final variant = ProductVariant(
      id: null,
      parentProductId: 0, // will be set by repo
      size: 'L',
      color: 'أسود',
      sku: sku,
      barcode: null,
      rfidTag: null,
      costPrice: 10.0,
      salePrice: 25.0,
      reorderPoint: 0,
      quantity: 0,
    );
    final parentId = await products.createWithVariants(parent, [variant]);
    expect(parentId, greaterThan(0));

    // Fetch the created variant id
    final createdVariants = await products.searchVariants(sku: sku, limit: 1);
    expect(createdVariants.isNotEmpty, true);
    final v = createdVariants.first;
    final variantId = v.id!;

    // 2) Create supplier and purchase invoice (increase stock)
    final supplierId = await suppliers.create(supplierName);
    expect(supplierId, greaterThan(0));

    final purchaseQty = 5;
    final purchaseCost = 12.5; // override cost on purchase
    final invoiceId = await purchases.createInvoiceWithRfids(
      PurchaseInvoice(
        supplierId: supplierId,
        reference: 'INV-$suffix',
        receivedDate: DateTime.now(),
      ),
      [
        PurchaseInvoiceItem(
          purchaseInvoiceId: 0,
          variantId: variantId,
          quantity: purchaseQty,
          costPrice: purchaseCost,
        ),
      ],
      [<String>[]],
    );
    expect(invoiceId, greaterThan(0));

    // 3) Create a sale for some quantity (decrease stock)
    final saleQty = 2;
    final salePrice = 30.0; // use explicit sale price
    final saleId = await sales.createSale(
      sale: Sale(
        userId: admin.id,
        customerId: null,
        totalAmount: 0, // will be computed by DAO
        saleDate: DateTime.now(),
        reference: 'SALE-$suffix',
      ),
      items: [
        SaleItem(
          id: null,
          saleId: 0,
          variantId: variantId,
          quantity: saleQty,
          pricePerUnit: salePrice,
          costAtSale: purchaseCost,
        ),
      ],
      payments: [
        Payment(
          id: null,
          saleId: null,
          amount: saleQty * salePrice,
          method: PaymentMethod.cash,
          cashSessionId: null,
          createdAt: DateTime.now(),
        ),
      ],
    );
    expect(saleId, greaterThan(0));

    // 4) Verify reports reflect our operations
    // byDay should include today's sale amount at least our sale total
    final byDay = await reports.salesByDay();
    expect(byDay.isNotEmpty, true);

    // top products should include our SKU with qty >= saleQty and rev >= saleQty*salePrice
    final top = await reports.topProducts();
    final topRow = top.firstWhere((r) => (r['sku']?.toString() ?? '') == sku,
        orElse: () => <String, Object?>{});
    expect(topRow.isNotEmpty, true, reason: 'Top products should include our SKU');
    expect((topRow['qty'] as num).toInt(), greaterThanOrEqualTo(saleQty));
    expect((topRow['rev'] as num).toDouble(), greaterThanOrEqualTo(saleQty * salePrice));

    // stock status should show our SKU quantity == purchaseQty - saleQty
    final stock = await reports.stockStatus();
    final stockRow = stock.firstWhere((r) => (r['sku']?.toString() ?? '') == sku,
        orElse: () => <String, Object?>{});
    expect(stockRow.isNotEmpty, true, reason: 'Stock report should include our SKU');
    expect((stockRow['quantity'] as num).toInt(), purchaseQty - saleQty);
  });
}

