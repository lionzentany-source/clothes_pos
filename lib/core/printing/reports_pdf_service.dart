import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

class ReportsPdfService {
  String _sanitize(String s) => s.replaceAll(RegExp(r'[\u200e\u200f]'), '');

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
    Directory? outputDir,
  }) async {
    final pdf = pw.Document();

    String money(num v) {
      final f = NumberFormat.currency(locale: locale, symbol: '');
      return f.format(v);
    }

    // Load fonts for better glyph coverage
    final isArabic = locale.startsWith('ar');
    final notoRegular = await _tryLoadFont(
      'assets/fonts/NotoNaskhArabic-Regular.ttf',
    );
    final notoBold = await _tryLoadFont(
      'assets/fonts/NotoNaskhArabic-Bold.ttf',
    );
    final sfArabic = await _tryLoadFont(
      'assets/db/fonts/sfpro/alfont_com_SFProAR_semibold.ttf',
    );
    final latinRegular = await _tryLoadFont(
      'assets/db/fonts/sfpro/SFPRODISPLAYREGULAR.otf',
    );
    final latinBold = await _tryLoadFont(
      'assets/db/fonts/sfpro/SFPRODISPLAYBOLD.otf',
    );

    final arabicRegular = isArabic ? (notoRegular ?? sfArabic) : null;
    final arabicBold = isArabic ? (notoBold ?? sfArabic ?? notoRegular) : null;
    final baseRegular = arabicRegular ?? latinRegular;
    final baseBold = arabicBold ?? latinBold ?? latinRegular;

    pw.Widget sectionTitle(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
      child: pw.Text(
        _sanitize(text),
        style: pw.TextStyle(fontSize: 12, font: baseBold),
      ),
    );
    final fallbackFonts = <pw.Font>[
      if (arabicRegular != null) arabicRegular,
      if (arabicBold != null) arabicBold,
      if (latinRegular != null) latinRegular,
      if (latinBold != null) latinBold,
    ];

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(16),
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.DefaultTextStyle(
              style: pw.TextStyle(
                font: baseRegular,
                fontFallback: fallbackFonts,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _sanitize(title ?? 'Reports Snapshot'),
                    style: pw.TextStyle(fontSize: 16, font: baseBold),
                  ),
                  pw.SizedBox(height: 8),

                  // Daily sales
                  sectionTitle(dailySalesLabel ?? 'Daily Sales (last 90 days)'),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      for (final r in byDay)
                        pw.Text(
                          _sanitize(
                            "${r['d']}: ${r['cnt']} - ${money((r['total'] as num?) ?? 0)}",
                          ),
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
                          _sanitize(
                            "${r['m']}: ${r['cnt']} - ${money((r['total'] as num?) ?? 0)}",
                          ),
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
                          _sanitize(
                            "SKU ${r['sku']}: ${r['qty']} - ${money((r['rev'] as num?) ?? 0)}",
                          ),
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
                          _sanitize(
                            "${r['username']}: ${r['cnt']} - ${money((r['total'] as num?) ?? 0)}",
                          ),
                        ),
                    ],
                  ),

                  // Purchases total
                  sectionTitle(
                    purchasesTotalLabel ?? 'Purchases Total (period)',
                  ),
                  pw.Text(_sanitize(money(purchasesTotal))),

                  // Stock status (low first)
                  sectionTitle(stockStatusLabel ?? 'Stock Status (low first)'),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      for (final r in stockStatus)
                        pw.Text(
                          _sanitize(
                            skuPattern
                                .replaceAll('{sku}', '${r['sku']}')
                                .replaceAll('{qty}', '${r['quantity']}')
                                .replaceAll('{rp}', '${r['reorder_point']}'),
                          ),
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

    final dir = outputDir ?? await getTemporaryDirectory();
    final file = File(
      '${dir.path}/reports_snapshot_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
