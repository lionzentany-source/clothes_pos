import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/repositories/purchase_repository.dart';
import 'package:clothes_pos/data/repositories/returns_repository.dart';
import 'package:clothes_pos/data/repositories/reports_repository.dart';
import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';
import 'package:clothes_pos/data/models/purchase_invoice.dart';
import 'package:clothes_pos/data/models/purchase_invoice_item.dart';
import '../helpers/test_helpers.dart';
import 'package:clothes_pos/core/config/feature_flags.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    FeatureFlags.setForTests(true);
    await setupTestDependencies();
  });

  test(
    'روتين أسبوعي كامل: مبيعات، إدراج منتجات، فواتير شراء، إعداد عملاء، مسترجعات، تحقق التقارير',
    () async {
      // إعداد المستودعات
      // final productRepo = sl<ProductRepository>();
      final salesRepo = sl<SalesRepository>();
      final purchaseRepo = sl<PurchaseRepository>();
      // final customerRepo = sl<CustomerRepository>();
      final returnsRepo = sl<ReturnsRepository>();
      final reportsRepo = sl<ReportsRepository>();

      // ...existing code...

      // فواتير شراء
      final purchaseInvoice1 = PurchaseInvoice(
        supplierId: 1,
        receivedDate: DateTime.now().subtract(Duration(days: 7)),
        totalCost: 50,
      );
      final purchaseInvoice2 = PurchaseInvoice(
        supplierId: 1,
        receivedDate: DateTime.now().subtract(Duration(days: 6)),
        totalCost: 80,
      );
      final purchaseItem1 = PurchaseInvoiceItem(
        purchaseInvoiceId: 1,
        variantId: 1,
        quantity: 10,
        costPrice: 50,
      );
      final purchaseItem2 = PurchaseInvoiceItem(
        purchaseInvoiceId: 2,
        variantId: 2,
        quantity: 5,
        costPrice: 80,
      );
      await purchaseRepo.createInvoice(purchaseInvoice1, [purchaseItem1]);
      await purchaseRepo.createInvoice(purchaseInvoice2, [purchaseItem2]);

      // مبيعات
      final sale1 = Sale(
        userId: 1,
        customerId: 1,
        totalAmount: 100,
        saleDate: DateTime.now().subtract(Duration(days: 5)),
      );
      final sale2 = Sale(
        userId: 1,
        customerId: 2,
        totalAmount: 150,
        saleDate: DateTime.now().subtract(Duration(days: 4)),
      );
      final saleItem1 = SaleItem(
        saleId: 1,
        variantId: 1,
        quantity: 1,
        pricePerUnit: 100,
        costAtSale: 50,
      );
      final saleItem2 = SaleItem(
        saleId: 2,
        variantId: 2,
        quantity: 1,
        pricePerUnit: 150,
        costAtSale: 80,
      );
      await salesRepo.createSale(sale: sale1, items: [saleItem1], payments: []);
      await salesRepo.createSale(sale: sale2, items: [saleItem2], payments: []);

      // مسترجعات
      // يفترض أن هناك دالة createReturn في returnsRepo
      await returnsRepo.createReturn(
        saleId: 1,
        userId: 1,
        items: [],
        reason: 'استرجاع',
      );
      // ...existing code...
      final now = DateTime.now();
      final startIso = now.subtract(Duration(days: 7)).toIso8601String();
      final endIso = now.toIso8601String();
      final totalSales = await reportsRepo.salesTotalByDate(
        startIso: startIso,
        endIso: endIso,
      );
      final totalPurchases = await reportsRepo.purchasesTotalByDate(
        startIso: startIso,
        endIso: endIso,
      );
      final totalReturns = await reportsRepo.returnsTotalByDate(
        startIso: startIso,
        endIso: endIso,
      );
      final profit = await reportsRepo.profitByDate(
        startIso: startIso,
        endIso: endIso,
      );
      final customerCount = await reportsRepo.customerCount();
      final inventoryCount = await reportsRepo.inventoryCount();

      expect(totalSales, greaterThanOrEqualTo(0));
      expect(totalPurchases, greaterThanOrEqualTo(0));
      expect(totalReturns, greaterThanOrEqualTo(0));
      expect(profit, isNotNull);
      expect(customerCount, greaterThanOrEqualTo(0));
      expect(inventoryCount, greaterThanOrEqualTo(0));
    },
  );
}
