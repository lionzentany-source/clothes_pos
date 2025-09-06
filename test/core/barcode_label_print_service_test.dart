import 'dart:typed_data';
import 'package:clothes_pos/core/barcode/barcode_label_print_service.dart';
import 'package:clothes_pos/core/barcode/label_template_engine.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _MockSettings extends Mock implements SettingsRepository {}

class _FakeDriver implements PdfPrintDriver {
  String? lastDirectUrl;
  Uint8List? lastDirectBytes;
  String? lastDirectName;
  Uint8List? lastSystemBytes;
  @override
  Future<void> directPrint({
    required Uint8List bytes,
    required String url,
    String? name,
  }) async {
    lastDirectBytes = bytes;
    lastDirectUrl = url;
    lastDirectName = name;
  }

  @override
  Future<void> systemPrint({required Uint8List bytes}) async {
    lastSystemBytes = bytes;
  }
}

void main() {
  group('BarcodeLabelPrintService buildPdf', () {
    test(
      'uses testOnlyOptions to bypass settings and build multi-page PDF',
      () async {
        final settings = _MockSettings();
        final svc = BarcodeLabelPrintService(settings: settings);
        final opts = const LabelTemplateOptions(
          showName: false,
          showPrice: true,
          widthMm: 30,
          heightMm: 20,
          marginMm: 2,
          barcodeHeightMm: 10,
          fontSizePt: 8,
        );
        final bytes = await svc.buildPdf(
          barcode: '1234567890123',
          productName: 'Name',
          priceText: '9.99',
          copies: 2,
          testOnlyOptions: opts,
        );
        expect(bytes, isA<Uint8List>());
        expect(bytes.lengthInBytes, greaterThan(500));
        verifyZeroInteractions(settings);
      },
    );
  });

  group('BarcodeLabelPrintService printer selection', () {
    test(
      'direct prints when barcode_printer_url is set, else system print',
      () async {
        final settings = _MockSettings();
        final driver = _FakeDriver();
        final svc = BarcodeLabelPrintService(
          settings: settings,
          driver: driver,
        );
        // Stub only printer keys for this test; buildPdf within printLabel will call _loadOptions
        await svc.printLabel(
          barcode: '1234567890123',
          testOnlyOptions: const LabelTemplateOptions(),
          testBypassSettings: true,
        );
        expect(driver.lastSystemBytes, isNotNull);
        expect(driver.lastDirectUrl, isNull);

        // Case 2: dedicated printer -> direct print
        driver.lastSystemBytes = null;
        await svc.printLabel(
          barcode: '1234567890123',
          testOnlyOptions: const LabelTemplateOptions(),
          testBypassSettings: true,
          testOnlyPrinterUrl: 'ipp://printer-1',
          testOnlyPrinterName: 'P1',
        );
        expect(driver.lastDirectUrl, 'ipp://printer-1');
        expect(driver.lastDirectBytes, isNotNull);
        expect(driver.lastSystemBytes, isNull);
      },
    );
  });
}
