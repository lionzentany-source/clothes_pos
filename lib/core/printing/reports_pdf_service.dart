import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

class ReportsPdfService {
  Future<pw.Font?> _tryLoadFont(String asset) async {
    try {
      final data = await rootBundle.load(asset);
      return pw.Font.ttf(data);
    } catch (_) {
      return null;
    }
  }

  Future<File> generate({
    required List<Map<String, Object?>> byDay,
    required List<Map<String, Object?>> byMonth,
    required List<Map<String, Object?>> topProducts,
    required List<Map<String, Object?>> staffPerf,
    required List<Map<String, Object?>> stockStatus,
    required double purchasesTotal,
    String locale = 'ar',
    // Localized labels passed in from UI layer (so we don't depend on Flutter l10n inside pure service)
    String? title,
    String? dailySalesLabel,
    String? monthlySalesLabel,
    String? topProductsLabel,
    String? staffPerformanceLabel,
    String? purchasesTotalLabel,
    String? stockStatusLabel,
    String skuPattern = 'SKU {sku}: {qty} - RP {rp}',
  }) async {
    final pdf = pw.Document();

    String money(num v) {
      final f = NumberFormat.currency(locale: locale, symbol: '');
      return f.format(v);
    }

    pw.Widget sectionTitle(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
    );

    // Load fonts for better glyph coverage
    final isArabic = locale.startsWith('ar');
    final arabicFont = isArabic
        ? await _tryLoadFont(
                'assets/db/fonts/sfpro/alfont_com_SFProAR_semibold.ttf',
              ) ??
              await _tryLoadFont('assets/fonts/NotoNaskhArabic-Regular.ttf')
        : null;
    final latinFont = await _tryLoadFont(
      'assets/db/fonts/sfpro/SFPRODISPLAYREGULAR.otf',
    );
    final fallbackFonts = <pw.Font>[
      if (arabicFont != null) arabicFont,
      if (latinFont != null) latinFont,
    ];

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(16),
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.DefaultTextStyle(
              style: pw.TextStyle(
                font: arabicFont ?? latinFont,
                fontFallback: fallbackFonts,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    title ?? 'Reports Snapshot',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  // Daily sales
                  sectionTitle(dailySalesLabel ?? 'Daily Sales (last 90 days)'),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      for (final r in byDay)
                        pw.Text(
                          "${r['d']}: ${r['cnt']} - ${money((r['total'] as num?) ?? 0)}",
                        ),
                    ],
                  ),

                  // Monthly sales
                  sectionTitle(
                    monthlySalesLabel ?? 'Monthly Sales (last 24 months)',
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      for (final r in byMonth)
                        pw.Text(
                          "${r['m']}: ${r['cnt']} - ${money((r['total'] as num?) ?? 0)}",
                        ),
                    ],
                  ),

                  // Top products
                  sectionTitle(topProductsLabel ?? 'Top Products (by qty)'),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      for (final r in topProducts)
                        pw.Text(
                          "SKU ${r['sku']}: ${r['qty']} - ${money((r['rev'] as num?) ?? 0)}",
                        ),
                    ],
                  ),

                  // Staff performance
                  sectionTitle(staffPerformanceLabel ?? 'Staff Performance'),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      for (final r in staffPerf)
                        pw.Text(
                          "${r['username']}: ${r['cnt']} - ${money((r['total'] as num?) ?? 0)}",
                        ),
                    ],
                  ),

                  // Purchases total
                  sectionTitle(
                    purchasesTotalLabel ?? 'Purchases Total (period)',
                  ),
                  pw.Text(money(purchasesTotal)),

                  // Stock status (low first)
                  sectionTitle(stockStatusLabel ?? 'Stock Status (low first)'),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      for (final r in stockStatus)
                        pw.Text(
                          skuPattern
                              .replaceAll('{sku}', '${r['sku']}')
                              .replaceAll('{qty}', '${r['quantity']}')
                              .replaceAll('{rp}', '${r['reorder_point']}'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/reports_snapshot_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
