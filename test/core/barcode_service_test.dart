import 'package:clothes_pos/core/barcode/barcode_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarcodeService EAN-13', () {
    final svc = const BarcodeService();

    test('validates correct EAN-13 codes', () {
      // Known valid EAN-13 example: base 590123412345 + checksum 7 => 5901234123457
      expect(svc.validate('5901234123457', BarcodeType.ean13), isTrue);
    });

    test('rejects invalid EAN-13 checksum', () {
      expect(svc.validate('5901234123458', BarcodeType.ean13), isFalse);
    });

    test('generateEan13FromBase pads/truncates and adds checksum', () {
      expect(svc.generateEan13FromBase('123'), hasLength(13));
      expect(svc.generateEan13FromBase('123456789012'), hasLength(13));
      final code = svc.generateEan13FromBase('123456789012345');
      expect(code, hasLength(13));
      expect(svc.validate(code, BarcodeType.ean13), isTrue);
    });
  });
}
