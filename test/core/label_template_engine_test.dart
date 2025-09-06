import 'dart:typed_data';
import 'package:clothes_pos/core/barcode/label_template_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LabelTemplateEngine copies', () {
    final engine = const LabelTemplateEngine();

    test('buildLabels(copies: n) returns non-empty PDF', () async {
      final bytes = await engine.buildLabels(
        barcode: '1234567890123',
        productName: 'Test',
        priceText: '10.00',
        options: const LabelTemplateOptions(),
        copies: 3,
      );
      expect(bytes, isA<Uint8List>());
      expect(bytes.lengthInBytes, greaterThan(1000));
    });
  });
}
