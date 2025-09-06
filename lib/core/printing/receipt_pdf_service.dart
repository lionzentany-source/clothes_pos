import 'dart:io';
import 'dart:convert';
import 'package:clothes_pos/core/format/currency_formatter.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/datasources/product_dao.dart';
import 'package:clothes_pos/data/datasources/sales_dao.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:clothes_pos/core/config/feature_flags.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

// دالة لفحص وجود أحرف عربية في النص
// دالة لفحص إذا كان النص عبارة عن أرقام فقط (أو يحتوي على أرقام ورموز)
bool isNumeric(String text) {
  // يدعم الأرقام العربية والهندية والرموز الرقمية
  return RegExp(
    r'^[\d\u0660-\u0669\u06F0-\u06F9\s\.,:؛-]+$',
  ).hasMatch(text.trim());
}

bool isArabic(String text) {
  return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
}

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

    // Load Latin and symbols fallback fonts (if available)
    pw.Font? latinFont;
    pw.Font? symbolsFont;
    try {
      final data = await rootBundle.load(
        'assets/db/fonts/sfpro/SFPRODISPLAYREGULAR.otf',
      );
      latinFont = pw.Font.ttf(data);
    } catch (_) {}
    // If you add a dedicated symbols/emoji font under assets, load it here similarly.
    // try {
    //   final data = await rootBundle.load('assets/fonts/NotoEmoji-Regular.ttf');
    //   symbolsFont = pw.Font.ttf(data);
    // } catch (_) {}
    final fallbackFonts = <pw.Font>[
      if (latinFont case final f?) f,
      if (symbolsFont case final s?) s,
    ];

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
    var itemRows = await _sales.itemRowsForSale(saleId);
    // If dynamic attributes are enabled, enrich item rows with attributes
    if (FeatureFlags.useDynamicAttributes && itemRows.isNotEmpty) {
      try {
        final variantIds = <int>[];
        for (final r in itemRows) {
          final vid =
              (r['variant_id'] as int?) ?? (r['variant_id'] as num?)?.toInt();
          if (vid != null) variantIds.add(vid);
        }
        if (variantIds.isNotEmpty) {
          final prodDao = sl<ProductDao>();
          final variants = await prodDao.getVariantsByIds(
            variantIds.toSet().toList(),
          );
          final mapById = {for (var v in variants) v.id!: v};
          for (final row in itemRows) {
            final vid =
                (row['variant_id'] as int?) ??
                (row['variant_id'] as num?)?.toInt();
            if (vid != null && mapById.containsKey(vid)) {
              row['attributes'] = mapById[vid]!.attributes ?? [];
            }
          }
        }
      } catch (_) {
        // ignore enrichment failures - continue without attributes
      }
    }
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
              style: pw.TextStyle(
                fontSize: baseFont,
                font: arabicFont,
                fontFallback: fallbackFonts,
              ),
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
                        font:
                            isArabic(storeName) &&
                                arabicFont != null &&
                                !isNumeric(storeName)
                            ? arabicFont
                            : null,
                      ),
                    ),
                  ),
                  if (showSlogan && slogan.isNotEmpty)
                    pw.Center(
                      child: pw.Text(
                        slogan,
                        style: pw.TextStyle(
                          fontSize: 8,
                          font:
                              isArabic(slogan) &&
                                  arabicFont != null &&
                                  !isNumeric(slogan)
                              ? arabicFont
                              : null,
                        ),
                      ),
                    ),
                  if (showAddress && storeAddress.isNotEmpty)
                    pw.Center(
                      child: pw.Text(
                        storeAddress,
                        style: pw.TextStyle(
                          fontSize: 9,
                          font:
                              isArabic(storeAddress) &&
                                  arabicFont != null &&
                                  !isNumeric(storeAddress)
                              ? arabicFont
                              : null,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  if (showPhone && storePhone.isNotEmpty)
                    pw.Center(
                      child: pw.Text(
                        '${phoneLabel ?? 'Phone'}: $storePhone',
                        style: pw.TextStyle(
                          fontSize: 9,
                          font:
                              isArabic(storePhone) &&
                                  arabicFont != null &&
                                  !isNumeric(storePhone)
                              ? arabicFont
                              : null,
                        ),
                      ),
                    ),
                  if (showTaxId && taxId.isNotEmpty)
                    pw.Center(
                      child: pw.Text(
                        'TAX: $taxId',
                        style: pw.TextStyle(
                          fontSize: 8,
                          font:
                              isArabic(taxId) &&
                                  arabicFont != null &&
                                  !isNumeric(taxId)
                              ? arabicFont
                              : null,
                        ),
                      ),
                    ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${saleReceiptLabel ?? 'Sale Receipt'} #$saleId - $dateStr',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      font:
                          isArabic(
                                '${saleReceiptLabel ?? 'Sale Receipt'} #$saleId - $dateStr',
                              ) &&
                              arabicFont != null &&
                              !isNumeric(
                                '${saleReceiptLabel ?? 'Sale Receipt'} #$saleId - $dateStr',
                              )
                          ? arabicFont
                          : null,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${userLabel ?? 'User'}: ${cashierName ?? 'User #${sale.userId}'}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      font:
                          isArabic(
                                '${userLabel ?? 'User'}: ${cashierName ?? 'User #${sale.userId}'}',
                              ) &&
                              arabicFont != null &&
                              !isNumeric(
                                '${userLabel ?? 'User'}: ${cashierName ?? 'User #${sale.userId}'}',
                              )
                          ? arabicFont
                          : null,
                    ),
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
                      // Extract attribute values if dynamic attributes are enabled
                      List<String> attributeValues() {
                        if (!FeatureFlags.useDynamicAttributes) return [];
                        final rawAttrs = (it['attributes'] as List?) ?? [];
                        return rawAttrs
                            .map((a) {
                              if (a == null) return '';
                              if (a is String) return a;
                              if (a is Map) {
                                return (a['value'] ?? '').toString();
                              }
                              try {
                                final dyn = a as dynamic;
                                return (dyn.value ?? '').toString();
                              } catch (_) {
                                return a.toString();
                              }
                            })
                            .where((s) => s.isNotEmpty)
                            .toList();
                      }

                      final attrs = attributeValues();

                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    '$displayName x$qty',
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      font:
                                          isArabic('$displayName x$qty') &&
                                              arabicFont != null &&
                                              !isNumeric('$displayName x$qty')
                                          ? arabicFont
                                          : null,
                                    ),
                                  ),
                                  if (attrs.isNotEmpty) pw.SizedBox(height: 2),
                                  if (attrs.isNotEmpty)
                                    pw.Text(
                                      attrs.join(' • '),
                                      style: pw.TextStyle(
                                        fontSize: 8,
                                        color: PdfColors.grey700,
                                        font:
                                            (isArabic(attrs.join(' • ')) &&
                                                arabicFont != null &&
                                                !isNumeric(attrs.join(' • ')))
                                            ? arabicFont
                                            : null,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            pw.Text(
                              CurrencyFormatter.format(
                                lineTotal,
                                currency: currency,
                                locale: locale,
                              ),
                              style: pw.TextStyle(
                                fontSize: 9,
                                font:
                                    isNumeric(
                                      CurrencyFormatter.format(
                                        lineTotal,
                                        currency: currency,
                                        locale: locale,
                                      ),
                                    )
                                    ? null
                                    : (isArabic(
                                                CurrencyFormatter.format(
                                                  lineTotal,
                                                  currency: currency,
                                                  locale: locale,
                                                ),
                                              ) &&
                                              arabicFont != null
                                          ? arabicFont
                                          : null),
                              ),
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
                          font:
                              isArabic(totalLabel ?? 'Total') &&
                                  arabicFont != null &&
                                  !isNumeric(totalLabel ?? 'Total')
                              ? arabicFont
                              : null,
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
                          font:
                              isNumeric(
                                CurrencyFormatter.format(
                                  total,
                                  currency: currency,
                                  locale: locale,
                                ),
                              )
                              ? null
                              : (isArabic(
                                          CurrencyFormatter.format(
                                            total,
                                            currency: currency,
                                            locale: locale,
                                          ),
                                        ) &&
                                        arabicFont != null
                                    ? arabicFont
                                    : null),
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
                      font:
                          isArabic(
                                '${paymentMethodsLabel ?? 'Payment Methods'}:',
                              ) &&
                              arabicFont != null &&
                              !isNumeric(
                                '${paymentMethodsLabel ?? 'Payment Methods'}:',
                              )
                          ? arabicFont
                          : null,
                    ),
                  ),
                  ...payments.map(
                    (p) => pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          methodLabel(p.method.toString().split('.').last),
                          style: pw.TextStyle(
                            fontSize: 9,
                            font:
                                isArabic(
                                      methodLabel(
                                        p.method.toString().split('.').last,
                                      ),
                                    ) &&
                                    arabicFont != null &&
                                    !isNumeric(
                                      methodLabel(
                                        p.method.toString().split('.').last,
                                      ),
                                    )
                                ? arabicFont
                                : null,
                          ),
                        ),
                        pw.Text(
                          CurrencyFormatter.format(
                            p.amount,
                            currency: currency,
                            locale: locale,
                          ),
                          style: pw.TextStyle(
                            fontSize: 9,
                            font:
                                isNumeric(
                                  CurrencyFormatter.format(
                                    p.amount,
                                    currency: currency,
                                    locale: locale,
                                  ),
                                )
                                ? null
                                : (isArabic(
                                            CurrencyFormatter.format(
                                              p.amount,
                                              currency: currency,
                                              locale: locale,
                                            ),
                                          ) &&
                                          arabicFont != null
                                      ? arabicFont
                                      : null),
                          ),
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
                      style: pw.TextStyle(
                        fontSize: 9,
                        font:
                            isArabic(
                                  (customThanks != null &&
                                          customThanks.trim().isNotEmpty)
                                      ? customThanks.trim()
                                      : (thanksLabel ??
                                            'Thank you for shopping!'),
                                ) &&
                                arabicFont != null &&
                                !isNumeric(
                                  (customThanks != null &&
                                          customThanks.trim().isNotEmpty)
                                      ? customThanks.trim()
                                      : (thanksLabel ??
                                            'Thank you for shopping!'),
                                )
                            ? arabicFont
                            : null,
                      ),
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

    // Load Latin and symbols fallback fonts (if available)
    pw.Font? latinFont;
    pw.Font? symbolsFont;
    try {
      final data = await rootBundle.load(
        'assets/db/fonts/sfpro/SFPRODISPLAYREGULAR.otf',
      );
      latinFont = pw.Font.ttf(data);
    } catch (_) {}
    // If you add a dedicated symbols/emoji font under assets, load it here similarly.
    // try {
    //   final data = await rootBundle.load('assets/fonts/NotoEmoji-Regular.ttf');
    //   symbolsFont = pw.Font.ttf(data);
    // } catch (_) {}
    final fallbackFonts = <pw.Font>[
      if (latinFont case final f?) f,
      if (symbolsFont case final s?) s,
    ];

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
            style: pw.TextStyle(
              fontSize: baseFont,
              font: arabicFont,
              fontFallback: fallbackFonts,
            ),
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
                pw.Text('TEST RECEIPT - Preview Layout'),
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
