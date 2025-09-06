import 'dart:typed_data';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/core/printing/system_pdf_printer.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:printing/printing.dart';
import 'label_template_engine.dart';

/// Abstraction over actual printing to allow unit testing the selection logic.
abstract class PdfPrintDriver {
  Future<void> directPrint({
    required Uint8List bytes,
    required String url,
    String? name,
  });
  Future<void> systemPrint({required Uint8List bytes});
}

class DefaultPdfPrintDriver implements PdfPrintDriver {
  @override
  Future<void> directPrint({
    required Uint8List bytes,
    required String url,
    String? name,
  }) async {
    await Printing.directPrintPdf(
      printer: Printer(url: url, name: name ?? 'Barcode printer'),
      onLayout: (_) async => bytes,
    );
  }

  @override
  Future<void> systemPrint({required Uint8List bytes}) async {
    await SystemPdfPrinter().printPdfBytes(bytes);
  }
}

class BarcodeLabelPrintService {
  final SettingsRepository _settings;
  final LabelTemplateEngine _engine;
  final PdfPrintDriver _driver;

  BarcodeLabelPrintService({
    SettingsRepository? settings,
    LabelTemplateEngine? engine,
    PdfPrintDriver? driver,
  }) : _settings = settings ?? sl<SettingsRepository>(),
       _engine = engine ?? const LabelTemplateEngine(),
       _driver = driver ?? DefaultPdfPrintDriver();

  Future<LabelTemplateOptions> _loadOptions() async {
    double parseDouble(String? v, double d) => double.tryParse(v ?? '') ?? d;
    final width = parseDouble(await _settings.get('label_width_mm'), 58);
    final height = parseDouble(await _settings.get('label_height_mm'), 40);
    final margin = parseDouble(await _settings.get('label_margin_mm'), 3);
    final font = parseDouble(await _settings.get('label_font_pt'), 9);
    final bh = parseDouble(await _settings.get('label_barcode_h_mm'), 18);
    final showName = (await _settings.get('label_show_name')) != '0';
    final showPrice = (await _settings.get('label_show_price')) == '1';
    return LabelTemplateOptions(
      widthMm: width,
      heightMm: height,
      marginMm: margin,
      fontSizePt: font,
      barcodeHeightMm: bh,
      showName: showName,
      showPrice: showPrice,
    );
  }

  Future<Uint8List> buildPdf({
    required String barcode,
    String? productName,
    String? priceText,
    int copies = 1,
    LabelTemplateOptions? overrideOptions,
    // testOnlyOptions allows bypassing repository lookups in unit tests
    LabelTemplateOptions? testOnlyOptions,
  }) async {
    final opts = testOnlyOptions ?? overrideOptions ?? await _loadOptions();
    // Normalize price to include Arabic currency if it's just a number
    final normalizedPrice = _normalizePrice(priceText);
    // Build a document with [copies] pages for deterministic copy counts
    return _engine.buildLabels(
      barcode: barcode,
      productName: productName,
      priceText: normalizedPrice,
      options: opts,
      copies: copies,
    );
  }

  Future<void> printLabel({
    required String barcode,
    String? productName,
    String? priceText,
    int copies = 1,
    LabelTemplateOptions? overrideOptions,
    LabelTemplateOptions? testOnlyOptions,
    // Test-only overrides to bypass async settings lookups
    bool testBypassSettings = false,
    String? testOnlyPrinterUrl,
    String? testOnlyPrinterName,
  }) async {
    final normalizedPrice = _normalizePrice(priceText);
    final bytes = await buildPdf(
      barcode: barcode,
      productName: productName,
      priceText: normalizedPrice,
      copies: copies,
      overrideOptions: overrideOptions,
      testOnlyOptions: testOnlyOptions,
    );
    // Prefer dedicated barcode printer if configured; otherwise use SystemPdfPrinter flow
    String? url;
    String? name;
    if (testBypassSettings) {
      url = testOnlyPrinterUrl;
      name = testOnlyPrinterName;
    } else {
      url = testOnlyPrinterUrl ?? await _settings.get('barcode_printer_url');
      name = testOnlyPrinterName ?? await _settings.get('barcode_printer_name');
    }
    if (url != null && url.isNotEmpty) {
      try {
        await _driver.directPrint(bytes: bytes, url: url, name: name);
        return;
      } catch (_) {
        // Fall through to generic printing if direct fails
      }
    }
    await _driver.systemPrint(bytes: bytes);
  }

  String? _normalizePrice(String? priceText) {
    final raw = priceText?.trim();
    if (raw == null || raw.isEmpty) return null;
    // If it already contains Arabic letters or currency markers, keep it.
    // Dart RegExp does not yet support Unicode script properties like \p{Arabic}.
    // Use explicit Arabic Unicode ranges instead (primary + supplementary + presentation forms).
    // Ranges covered:
    //   0600–06FF, 0750–077F, 08A0–08FF, FB50–FDFF, FE70–FEFF
    final hasLetters = RegExp(
      r'[A-Za-z\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    ).hasMatch(raw);
    final hasCurrency =
        raw.contains('د.ل') ||
        raw.contains('LYD') ||
        raw.contains('ريال') ||
        raw.contains('SAR');
    if (hasLetters || hasCurrency) return raw;
    // Else format as: "السعر {raw} د.ل"
    return 'السعر $raw د.ل';
  }
}
