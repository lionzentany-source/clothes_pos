import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

/// Service for handling printing operations
class PrintService {
  /// Print a PDF document using the system print dialog
  static Future<void> printPdf(pw.Document document) async {
    await Printing.layoutPdf(onLayout: (format) => document.save());
  }

  /// Share a PDF document
  static Future<void> sharePdf(pw.Document document, String filename) async {
    await Printing.sharePdf(bytes: await document.save(), filename: filename);
  }

  /// Get available printers
  static Future<List<Printer>> getAvailablePrinters() async {
    return await Printing.listPrinters();
  }

  /// Print directly to a specific printer
  static Future<void> printToPrinter(
    pw.Document document,
    Printer printer,
  ) async {
    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (format) => document.save(),
    );
  }
}
