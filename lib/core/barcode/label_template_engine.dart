import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle; // for loading fonts
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:barcode/barcode.dart' as bc;

class LabelTemplateOptions {
  final double widthMm;
  final double heightMm;
  final double marginMm;
  final bool showName;
  final bool showPrice;
  final double barcodeHeightMm;
  final double fontSizePt;

  const LabelTemplateOptions({
    this.widthMm = 58,
    this.heightMm = 40,
    this.marginMm = 3,
    this.showName = true,
    this.showPrice = false,
    this.barcodeHeightMm = 18,
    this.fontSizePt = 9,
  });

  LabelTemplateOptions copyWith({
    double? widthMm,
    double? heightMm,
    double? marginMm,
    bool? showName,
    bool? showPrice,
    double? barcodeHeightMm,
    double? fontSizePt,
  }) {
    return LabelTemplateOptions(
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      marginMm: marginMm ?? this.marginMm,
      showName: showName ?? this.showName,
      showPrice: showPrice ?? this.showPrice,
      barcodeHeightMm: barcodeHeightMm ?? this.barcodeHeightMm,
      fontSizePt: fontSizePt ?? this.fontSizePt,
    );
  }
}

/// Minimal label pdf generator. It draws a placeholder barcode (text + bars)
/// to avoid adding a runtime dependency now. It can be replaced by an image
/// or a proper barcode painter later.
class LabelTemplateEngine {
  const LabelTemplateEngine();

  Future<Uint8List> buildLabel({
    required String barcode,
    String? productName,
    String? priceText,
    LabelTemplateOptions options = const LabelTemplateOptions(),
  }) async {
    // Delegate to multi-label builder with a single copy for API compatibility
    return buildLabels(
      barcode: barcode,
      productName: productName,
      priceText: priceText,
      options: options,
      copies: 1,
    );
  }

  /// Build a PDF document that contains [copies] identical labels.
  Future<Uint8List> buildLabels({
    required String barcode,
    String? productName,
    String? priceText,
    LabelTemplateOptions options = const LabelTemplateOptions(),
    int copies = 1,
  }) async {
    final pdf = pw.Document();
    final pageFormat = PdfPageFormat(
      options.widthMm * PdfPageFormat.mm,
      options.heightMm * PdfPageFormat.mm,
      marginAll: options.marginMm * PdfPageFormat.mm,
    );

    // Load fonts for Arabic shaping/fallback (safe if assets missing).
    // Order of preference: Explicit Noto Naskh (regular) -> bundled Arabic SF Pro -> Latin SF Pro.
    final pw.Font? notoRegular = await _tryLoadFont(
      'assets/fonts/NotoNaskhArabic-Regular.ttf',
    );
    final pw.Font? notoBold = await _tryLoadFont(
      'assets/fonts/NotoNaskhArabic-Bold.ttf',
    );
    final pw.Font? sfArabic = await _tryLoadFont(
      'assets/db/fonts/sfpro/alfont_com_SFProAR_semibold.ttf',
    );
    final pw.Font? sfLatin = await _tryLoadFont(
      'assets/db/fonts/sfpro/SFPRODISPLAYREGULAR.otf',
    );

    final primaryArabic = notoRegular ?? sfArabic;
    final primaryLatin = sfLatin;
    final fallbackFonts = <pw.Font>[
      if (primaryArabic != null) primaryArabic,
      if (notoBold != null) notoBold,
      if (sfArabic != null && sfArabic != primaryArabic) sfArabic,
      if (primaryLatin != null) primaryLatin,
    ];

    void addPage() {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (c) {
            final children = <pw.Widget>[];
            if (options.showName && (productName ?? '').isNotEmpty) {
              children.add(
                pw.Text(
                  productName!,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: options.fontSizePt),
                ),
              );
              children.add(pw.SizedBox(height: 2));
            }

            // Render a real barcode. Prefer EAN-13 if digits length 13, else Code128.
            children.add(_barcodeWidget(barcode, options));
            children.add(pw.SizedBox(height: 2));

            children.add(
              pw.Text(
                barcode,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: options.fontSizePt),
              ),
            );

            if (options.showPrice && (priceText ?? '').isNotEmpty) {
              children.add(pw.SizedBox(height: 2));
              children.add(
                pw.Text(
                  priceText!,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: options.fontSizePt),
                ),
              );
            }

            final content = pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: children,
            );

            // Apply a default text style with Arabic-capable fonts and RTL direction.
            return pw.DefaultTextStyle(
              style: pw.TextStyle(
                font: primaryArabic ?? primaryLatin,
                fontFallback: fallbackFonts,
              ),
              child: pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: content,
              ),
            );
          },
        ),
      );
    }

    final total = copies <= 0 ? 1 : copies;
    for (var i = 0; i < total; i++) {
      addPage();
    }
    return pdf.save();
  }

  pw.Widget _barcodeWidget(String value, LabelTemplateOptions o) {
    final h = o.barcodeHeightMm * PdfPageFormat.mm;
    final is13Digits = RegExp(r'^\d{13}$').hasMatch(value);
    bool validEan13(String v) {
      if (!is13Digits) return false;
      int sum = 0;
      for (var i = 0; i < 12; i++) {
        final digit = int.parse(v[i]);
        sum += (i % 2 == 0) ? digit : digit * 3;
      }
      final check = (10 - (sum % 10)) % 10;
      return check == int.parse(v[12]);
    }

    final useEan13 = validEan13(value);
    // Fallback to Code128 for any non-13-digit input or invalid checksum.
    final barcode = useEan13 ? bc.Barcode.ean13() : bc.Barcode.code128();
    return pw.Center(
      child: pw.Container(
        height: h,
        alignment: pw.Alignment.center,
        child: pw.BarcodeWidget(
          barcode: barcode,
          data: value,
          drawText: false,
          height: h,
        ),
      ),
    );
  }

  Future<pw.Font?> _tryLoadFont(String asset) async {
    try {
      final data = await rootBundle.load(asset);
      return pw.Font.ttf(data);
    } catch (_) {
      return null;
    }
  }
}
