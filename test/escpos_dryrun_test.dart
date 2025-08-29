import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/core/printing/escpos_generator.dart';

void main() {
  // Ensure Flutter bindings are initialized so asset loading works.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('escpos dry-run: generate and print bytes', () async {
    final generator = await EscposGenerator80.create();

    final itemRows = <Map<String, Object?>>[
      {
        'quantity': 2,
        'price_per_unit': 12.5,
        'parent_name': 'T-Shirt',
        'sku': 'TSH-001',
        'brand_name': 'BrandX',
        'variant_id': 101,
        'attributes': [
          'Red',
          {'value': 'Large'},
        ],
      },
      {
        'quantity': 1,
        'price_per_unit': 45.0,
        'parent_name': 'Jacket',
        'sku': 'JCK-002',
        'brand_name': 'BrandY',
        'variant_id': 102,
        'attributes': [],
      },
    ];

    final bytes = generator.buildReceiptFromRows(
      title: 'DryRun Receipt',
      itemRows: itemRows,
      currency: 'USD',
    );

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    print('\n=== ESC/POS DRY-RUN (${bytes.length} bytes) ===');
    print(hex);
    print('=== END DRY-RUN ===\n');

    expect(bytes, isNotEmpty);
  });
}
