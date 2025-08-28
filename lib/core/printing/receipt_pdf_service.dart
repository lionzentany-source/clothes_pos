import 'dart:io';
import 'dart:convert';
import 'package:clothes_pos/core/format/currency_formatter.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/datasources/sales_dao.dart';

import 'package:clothes_pos/data/repositories/settings_repository.dart';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

class ReceiptPdfService {
  final SalesDao _sales;
  final SettingsRepository _settings;
  ReceiptPdfService()
    : _sales = sl<SalesDao>(),
      _settings = sl<SettingsRepository>();

  /// Generate a real sale receipt from persisted sale data.
  Future<File> generate(
    int saleId, {
    String locale = 'ar',
    String? cashierName,
    // Localized labels injected from UI (avoid direct dependency on Flutter widgets)
    String? phoneLabel,
    String? saleReceiptLabel,
    String? userLabel,
    String? totalLabel,
    String? paymentMethodsLabel,
    String? thanksLabel,
    String cashLabel = 'Cash',
    String cardLabel = 'Card',
    String mobileLabel = 'Mobile',
    String refundLabel = 'Refund',
  }) async {
    final pdf = pw.Document();

    // Directionality and optional Arabic font
    pw.Font? arabicFont;
    final textDirection = locale.startsWith('ar')
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;
    if (locale.startsWith('ar')) {
      try {
        final pref = await _settings.get('receipt_font_asset');
        final candidates = <String?>[
          pref,
          'assets/db/fonts/sfpro/alfont_com_SFProAR_semibold.ttf',
          'assets/fonts/NotoNaskhArabic-Regular.ttf',
          'assets/fonts/receipt_ar.ttf',
        ];
        for (final c in candidates) {
          if (c == null) continue;
          try {
            final data = await rootBundle.load(c);
            arabicFont = pw.Font.ttf(data);
            break;
          } catch (_) {}
        }
      } catch (_) {}
    }
    final storeName = await _settings.get('store_name') ?? 'Clothes POS';
    final storeAddress = await _settings.get('store_address') ?? '';
    final storePhone = await _settings.get('store_phone') ?? '';
    final currency = await _settings.get('currency') ?? 'LYD';
    final customThanks = await _settings.get('receipt_thanks');
    final slogan = await _settings.get('store_slogan') ?? '';
    final taxId = await _settings.get('tax_id') ?? '';
    // Visibility toggles (default true for backwards compatibility)
    Future<bool> show(String key) async =>
        ((await _settings.get(key))?.toLowerCase() ?? 'true') != 'false';
    final showLogo = await show('show_logo');
    final showSlogan = await show('show_slogan');
    final showTaxId = await show('show_tax_id');
    final showAddress = await show('show_address');
    final showPhone = await show('show_phone');
    final logoBase64 = await _settings.get('store_logo_base64');

    pw.ImageProvider? logoImg;
    if (showLogo && logoBase64 != null && logoBase64.trim().isNotEmpty) {
      try {
        final bytes = base64Decode(logoBase64);
        logoImg = pw.MemoryImage(bytes);
      } catch (_) {}
    }

    // Printing settings
    // تثبيت عرض الصفحة على 80 ملم دائماً
    final pageWidthMm = 80.0;
    final pageHeightMm = double.tryParse(
      await _settings.get('print_page_height') ?? '',
    );
    final marginMm =
        double.tryParse(await _settings.get('print_margin') ?? '') ?? 6;
    final baseFont =
        double.tryParse(await _settings.get('print_font_size') ?? '') ?? 10;
    final pageFormat = PdfPageFormat(
      pageWidthMm * PdfPageFormat.mm,
      (pageHeightMm == null || pageHeightMm <= 0)
          ? double.infinity
          : pageHeightMm * PdfPageFormat.mm,
    );
    final marginPx = marginMm * PdfPageFormat.mm;

    final sale = await _sales.getSale(saleId);
    final saleDate = sale.saleDate;
    final itemRows = await _sales.itemRowsForSale(saleId);
    final payments = await _sales.paymentsForSale(saleId);
    final total = itemRows.fold<double>(
      0,
      (s, it) =>
          s +
          ((it['price_per_unit'] as num) * (it['quantity'] as num)).toDouble(),
    );

    String methodLabel(String m) {
      switch (m.toUpperCase()) {
        case 'CASH':
          return cashLabel;
        case 'CARD':
          return cardLabel;
        case 'MOBILE':
          return mobileLabel;
        case 'REFUND':
          return refundLabel;
        default:
          return m;
      }
    }

    final dateStr = DateFormat('y-MM-dd HH:mm', locale).format(saleDate);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(marginPx),
        build: (context) {
          return pw.Directionality(
            textDirection: textDirection,
            child: pw.DefaultTextStyle(
              style: pw.TextStyle(fontSize: baseFont, font: arabicFont),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImg != null)
                    pw.Center(
                      child: pw.Container(
                        height: 60,
                        width: 120,
                        child: pw.Image(logoImg, fit: pw.BoxFit.contain),
                      ),
                    ),
                  pw.Center(
                    child: pw.Text(
                      storeName,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  if (showSlogan && slogan.isNotEmpty)
                    pw.Center(
                      child: pw.Text(
                        slogan,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  if (showAddress && storeAddress.isNotEmpty)
                    pw.Center(
                      child: pw.Text(
                        storeAddress,
                        style: const pw.TextStyle(fontSize: 9),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  if (showPhone && storePhone.isNotEmpty)
                    pw.Center(
                      child: pw.Text(
                        '${phoneLabel ?? 'Phone'}: $storePhone',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  if (showTaxId && taxId.isNotEmpty)
                    pw.Center(
                      child: pw.Text(
                        'TAX: $taxId',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${saleReceiptLabel ?? 'Sale Receipt'} #$saleId — $dateStr',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${userLabel ?? 'User'}: ${cashierName ?? 'User #${sale.userId}'}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Divider(),
                  pw.ListView.builder(
                    itemCount: itemRows.length,
                    itemBuilder: (ctx, i) {
                      final it = itemRows[i];
                      final qty = (it['quantity'] as num).toInt();
                      final price = (it['price_per_unit'] as num).toDouble();
                      final lineTotal = price * qty;
                      final parentName = (it['parent_name'] as String?)?.trim();
                      final sku = (it['sku'] as String?)?.trim();
                      final size = (it['size'] as String?)?.trim();
                      final color = (it['color'] as String?)?.trim();
                      final brand = (it['brand_name'] as String?)?.trim();
                      final base = (parentName != null && parentName.isNotEmpty)
                          ? parentName
                          : (sku != null && sku.isNotEmpty
                                ? sku
                                : 'SKU ${it['variant_id']}');
                      final variantText = [
                        size,
                        color,
                      ].where((e) => (e ?? '').isNotEmpty).join(' ');
                      final displayName = [
                        if (brand != null && brand.isNotEmpty) '[$brand] ',
                        base,
                        if (variantText.isNotEmpty) ' $variantText',
                      ].join().trim();
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                '$displayName x$qty',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            ),
                            pw.Text(
                              CurrencyFormatter.format(
                                lineTotal,
                                currency: currency,
                                locale: locale,
                              ),
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        totalLabel ?? 'Total',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        CurrencyFormatter.format(
                          total,
                          currency: currency,
                          locale: locale,
                        ),
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    '${paymentMethodsLabel ?? 'Payment Methods'}:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  ...payments.map(
                    (p) => pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          methodLabel(p.method.toString().split('.').last),
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          CurrencyFormatter.format(
                            p.amount,
                            currency: currency,
                            locale: locale,
                          ),
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Center(
                    child: pw.Text(
                      (customThanks != null && customThanks.trim().isNotEmpty)
                          ? customThanks.trim()
                          : (thanksLabel ?? 'Thank you for shopping!'),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/receipt_$saleId.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Generate a lightweight test receipt (no DB dependency on real sale data)
  /// to preview layout & header settings.
  Future<File> generateTest({String locale = 'ar'}) async {
    final pdf = pw.Document();

    // Directionality and optional Arabic font
    pw.Font? arabicFont;
    final textDirection = locale.startsWith('ar')
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;
    if (locale.startsWith('ar')) {
      try {
        final pref = await _settings.get('receipt_font_asset');
        final candidates = <String?>[
          pref,
          'assets/db/fonts/sfpro/alfont_com_SFProAR_semibold.ttf',
          'assets/fonts/NotoNaskhArabic-Regular.ttf',
          'assets/fonts/receipt_ar.ttf',
        ];
        for (final c in candidates) {
          if (c == null) continue;
          try {
            final data = await rootBundle.load(c);
            arabicFont = pw.Font.ttf(data);
            break;
          } catch (_) {}
        }
      } catch (_) {}
    }
    final storeName = await _settings.get('store_name') ?? 'Clothes POS';
    final storeAddress = await _settings.get('store_address') ?? '';
    final storePhone = await _settings.get('store_phone') ?? '';
    final currency = await _settings.get('currency') ?? 'LYD';
    final slogan = await _settings.get('store_slogan') ?? '';
    final taxId = await _settings.get('tax_id') ?? '';
    final customThanks = await _settings.get('receipt_thanks');
    Future<bool> show(String key) async =>
        ((await _settings.get(key))?.toLowerCase() ?? 'true') != 'false';
    final showLogo = await show('show_logo');
    final showSlogan = await show('show_slogan');
    final showTaxId = await show('show_tax_id');
    final showAddress = await show('show_address');
    final showPhone = await show('show_phone');
    final logoBase64 = await _settings.get('store_logo_base64');
    pw.ImageProvider? logoImg;
    if (showLogo && logoBase64 != null && logoBase64.trim().isNotEmpty) {
      try {
        logoImg = pw.MemoryImage(base64Decode(logoBase64));
      } catch (_) {}
    }
    // تثبيت عرض الصفحة على 80 ملم دائماً
    final pageWidthMm = 80.0;
    final marginMm =
        double.tryParse(await _settings.get('print_margin') ?? '') ?? 6;
    final baseFont =
        double.tryParse(await _settings.get('print_font_size') ?? '') ?? 10;
    final pageFormat = PdfPageFormat(
      pageWidthMm * PdfPageFormat.mm,
      double.infinity,
    );
    final marginPx = marginMm * PdfPageFormat.mm;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(marginPx),
        build: (_) => pw.Directionality(
          textDirection: textDirection,
          child: pw.DefaultTextStyle(
            style: pw.TextStyle(fontSize: baseFont, font: arabicFont),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logoImg != null)
                  pw.Center(child: pw.Image(logoImg, height: 60)),
                pw.Center(
                  child: pw.Text(
                    storeName,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                if (showSlogan && slogan.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      slogan,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                if (showAddress && storeAddress.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      storeAddress,
                      style: const pw.TextStyle(fontSize: 9),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                if (showPhone && storePhone.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      'Phone: $storePhone',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                if (showTaxId && taxId.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      'TAX: $taxId',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                pw.SizedBox(height: 8),
                pw.Text('TEST RECEIPT — Preview Layout'),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Sample Item x2'),
                    pw.Text('20.00 $currency'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Another Item x1'),
                    pw.Text('10.00 $currency'),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      '30.00 $currency',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    (customThanks != null && customThanks.trim().isNotEmpty)
                        ? customThanks.trim()
                        : 'Thank you for shopping!',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/receipt_test.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
