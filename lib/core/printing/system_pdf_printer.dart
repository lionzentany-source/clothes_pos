import 'dart:typed_data';

import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:printing/printing.dart';

/// SystemPdfPrinter prints a PDF using the platform printing dialog or directly
/// to a previously picked default printer (when supported by the platform).
///
/// Settings keys used:
/// - 'print_open_dialog' => '1' | '0' (default: '1')
/// - 'print_printer_url' => String (optional)
/// - 'print_printer_name' => String (optional, for display)
class SystemPdfPrinter {
  final SettingsRepository _settings;
  SystemPdfPrinter() : _settings = sl<SettingsRepository>();

  /// Picks a default printer and persists it to settings.
  /// Returns the picked printer or null if cancelled.
  Future<Printer?> pickAndSaveDefaultPrinter(BuildContext context) async {
    final printer = await Printing.pickPrinter(context: context);
    if (printer != null) {
      await _settings.set('print_printer_url', printer.url);
      await _settings.set('print_printer_name', printer.name);
    }
    return printer;
  }

  /// Clears any saved default printer from settings.
  Future<void> clearDefaultPrinter() async {
    await _settings.set('print_printer_url', null);
    await _settings.set('print_printer_name', null);
  }

  /// Returns the saved default printer info if available.
  Future<Printer?> getSavedPrinter() async {
    final url = await _settings.get('print_printer_url');
    if (url == null || url.isEmpty) return null;
    final name = await _settings.get('print_printer_name') ?? 'Saved printer';
    return Printer(url: url, name: name);
  }

  /// Prints provided PDF bytes either via dialog or directly (if configured).
  Future<void> printPdfBytes(Uint8List bytes) async {
    final openDialog = (await _settings.get('print_open_dialog')) != '0';
    if (openDialog) {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
      return;
    }

    var saved = await getSavedPrinter();
    // No context-initiated picking here to avoid context across async gaps.
    // Let callers handle picking a printer explicitly in UI flows.

    if (saved == null) {
      // Fallback to dialog if user cancelled picking or no saved printer.
      await Printing.layoutPdf(onLayout: (_) async => bytes);
      return;
    }

    await Printing.directPrintPdf(printer: saved, onLayout: (_) async => bytes);
  }
}
