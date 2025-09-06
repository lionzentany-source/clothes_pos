import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/core/barcode/label_template_engine.dart';
import 'package:clothes_pos/core/printing/reports_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PDF Arabic font smoke', () {
    test('LabelTemplateEngine generates bytes with Arabic name', () async {
      final engine = LabelTemplateEngine();
      final bytes = await engine.buildLabels(
        barcode: '1234567890128',
        productName: 'تيشيرت رجالي مقاس L',
        priceText: 'السعر: 99.00',
        copies: 1,
      );
      expect(bytes, isNotEmpty);
    });

    test('ReportsPdfService generates a file for Arabic locale', () async {
      final svc = ReportsPdfService();
      final tmp = Directory.systemTemp.createTempSync('pdf_smoke_');
      final file = await svc.generate(
        byDay: const [
          {'d': '2025-09-01', 'cnt': 3, 'total': 150.0},
          {'d': '2025-09-02', 'cnt': 2, 'total': 99.0},
        ],
        byMonth: const [
          {'m': '2025-08', 'cnt': 50, 'total': 2500.0},
        ],
        topProducts: const [
          {'sku': 'TSHIRT-L', 'qty': 12, 'rev': 600.0},
        ],
        staffPerf: const [
          {'username': 'saleh', 'cnt': 10, 'total': 500.0},
        ],
        stockStatus: const [
          {'sku': 'TSHIRT-L', 'quantity': 3, 'reorder_point': 5},
        ],
        purchasesTotal: 320.0,
        locale: 'ar',
        title: 'تقرير سريع',
        dailySalesLabel: 'مبيعات يومية',
        monthlySalesLabel: 'مبيعات شهرية',
        topProductsLabel: 'أفضل المنتجات',
        staffPerformanceLabel: 'أداء الموظفين',
        purchasesTotalLabel: 'إجمالي المشتريات',
        stockStatusLabel: 'حالة المخزون',
        outputDir: tmp,
      );
      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(1000));
      // Cleanup
      try {
        await file.delete();
      } catch (_) {}
      try {
        tmp.deleteSync(recursive: true);
      } catch (_) {}
    });
  });
}
