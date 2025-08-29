import 'dart:typed_data';
import 'package:clothes_pos/core/printing/escpos_generator.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';

Future<void> main() async {
  final gen = await EscposGenerator80.create();

  // Fabricated sample sale rows
  final rows = <Map<String, Object?>>[
    {
      'variant_id': 101,
      'parent_name': 'Classic T-Shirt',
      'sku': 'TS-CL-001',
      'size': 'M',
      'color': 'Navy',
      'brand_name': 'Acme',
      'quantity': 2,
      'price_per_unit': 12.5,
      'attributes': [
        {'value': 'Soft Cotton'},
        {'value': 'Limited Edition'},
      ],
    },
    {
      'variant_id': 102,
      'parent_name': 'Denim Jeans',
      'sku': 'JN-DN-042',
      'size': '32',
      'color': 'Blue',
      'brand_name': 'DenimCo',
      'quantity': 1,
      'price_per_unit': 39.99,
      'attributes': [
        'Slim Fit',
        {'value': 'Stretch'},
      ],
    },
    {
      'variant_id': 103,
      'parent_name': null,
      'sku': 'AC-0001',
      'size': null,
      'color': null,
      'brand_name': null,
      'quantity': 3,
      'price_per_unit': 4.0,
      // no attributes
    },
  ];

  final bytes = gen.buildReceiptFromRows(
    title: 'Sale #12345',
    itemRows: rows,
    currency: 'USD',
  );

  // Log a human-friendly breakdown
  AppLogger.d('--- ESC/POS bytes (${bytes.length} bytes) ---');
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  AppLogger.d(hex);

  // Try to extract printable ASCII/UTF-8 substrings
  final s = _extractText(bytes);
  AppLogger.d('\n--- Extracted text lines ---');
  for (final line in s.split(RegExp(r'\r?\n'))) {
    if (line.trim().isNotEmpty) {
      AppLogger.d(line);
    }
  }
}

String _extractText(Uint8List bytes) {
  // Naive approach: keep bytes in the printable Unicode range and replace others with \n when feed/cut found
  final buf = StringBuffer();
  for (var i = 0; i < bytes.length; i++) {
    final b = bytes[i];
    if (b == 0x0a || b == 0x0d) {
      buf.write('\n');
      continue;
    }
    if (b >= 0x20 && b <= 0x7e) {
      buf.write(String.fromCharCode(b));
    } else if (b >= 0x20 && b <= 0xff) {
      // try decode as latin1 fallback
      buf.write(String.fromCharCode(b));
    } else {
      // Non-printable: insert marker when we encounter ESC (0x1b) or GS (0x1d)
      if (b == 0x1b) {
        buf.write('\n<ESC>');
      } else if (b == 0x1d) {
        buf.write('\n<GS>');
      }
    }
  }
  return buf.toString();
}
