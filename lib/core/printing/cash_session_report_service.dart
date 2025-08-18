import 'dart:io';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class CashSessionReportService {
  final _cash = sl<CashRepository>();

  Future<File> generateXReport(
    int sessionId, {
    required String title,
    required String sessionLabel,
    required String openingFloatLabel,
    required String cashSalesLabel,
    required String depositsLabel,
    required String withdrawalsLabel,
    required String expectedCashLabel,
  }) async {
    final summary = await _cash.getSessionSummary(sessionId);
    if (summary.isEmpty) throw Exception('Session not found');
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (c) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 8),
                pw.Text(sessionLabel.replaceFirst('{id}', '$sessionId')),
                pw.Text(
                  openingFloatLabel.replaceFirst(
                    '{value}',
                    _f(summary['opening_float']),
                  ),
                ),
                pw.Text(
                  cashSalesLabel.replaceFirst(
                    '{value}',
                    _f(summary['sales_cash']),
                  ),
                ),
                pw.Text(
                  depositsLabel.replaceFirst('{value}', _f(summary['cash_in'])),
                ),
                pw.Text(
                  withdrawalsLabel.replaceFirst(
                    '{value}',
                    _f(summary['cash_out']),
                  ),
                ),
                pw.Divider(),
                pw.Text(
                  expectedCashLabel.replaceFirst(
                    '{value}',
                    _f(summary['expected_cash']),
                  ),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/x_report_$sessionId.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  Future<File> generateZReport(
    int sessionId, {
    double? closingAmount,
    double? variance,
    required String title,
    required String sessionLabel,
    required String openingFloatLabel,
    required String cashSalesLabel,
    required String depositsLabel,
    required String withdrawalsLabel,
    required String expectedCashLabel,
    required String actualAmountLabel,
    required String varianceLabelTemplate,
  }) async {
    final summary = await _cash.getSessionSummary(sessionId);
    if (summary.isEmpty) throw Exception('Session not found');
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (c) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 8),
              pw.Text(sessionLabel.replaceFirst('{id}', '$sessionId')),
              pw.Text(
                openingFloatLabel.replaceFirst(
                  '{value}',
                  _f(summary['opening_float']),
                ),
              ),
              pw.Text(
                cashSalesLabel.replaceFirst(
                  '{value}',
                  _f(summary['sales_cash']),
                ),
              ),
              pw.Text(
                depositsLabel.replaceFirst('{value}', _f(summary['cash_in'])),
              ),
              pw.Text(
                withdrawalsLabel.replaceFirst(
                  '{value}',
                  _f(summary['cash_out']),
                ),
              ),
              pw.Divider(),
              pw.Text(
                expectedCashLabel.replaceFirst(
                  '{value}',
                  _f(summary['expected_cash']),
                ),
              ),
              if (closingAmount != null)
                pw.Text(
                  actualAmountLabel.replaceFirst('{value}', _f(closingAmount)),
                ),
              if (variance != null)
                pw.Text(
                  varianceLabelTemplate.replaceFirst('{value}', _f(variance)),
                ),
            ],
          ),
        ),
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/z_report_$sessionId.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  String _f(Object? v) {
    if (v is num) return v.toStringAsFixed(2);
    return v?.toString() ?? '0.00';
  }
}
