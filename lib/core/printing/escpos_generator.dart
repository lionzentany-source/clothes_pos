import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

/// Helper to build basic ESC/POS receipt bytes for 80mm printers.
class EscposGenerator80 {
  final Generator _gen;

  EscposGenerator80._(this._gen);

  static Future<EscposGenerator80> create() async {
    final profile = await CapabilityProfile.load();
    final gen = Generator(PaperSize.mm80, profile);
    return EscposGenerator80._(gen);
  }

  /// Creates a very small test ticket.
  Uint8List buildTestTicket({
    String title = 'Test Receipt',
    String footer = 'Thank you!',
  }) {
    List<int> bytes = [];
    bytes += _gen.text(
      title,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += _gen.hr(ch: '-');
    bytes += _gen.text('Item A x1    10.00');
    bytes += _gen.text('Item B x2    20.00');
    bytes += _gen.hr(ch: '-');
    bytes += _gen.text(
      'TOTAL:       30.00',
      styles: const PosStyles(align: PosAlign.right, bold: true),
    );
    bytes += _gen.feed(2);
    bytes += _gen.text(footer, styles: const PosStyles(align: PosAlign.center));
    bytes += _gen.cut();
    return Uint8List.fromList(bytes);
  }

  /// Build a simple thermal receipt from raw item rows.
  /// Each row is expected to contain keys used in `SalesDao.itemRowsForSale`:
  /// 'quantity', 'price_per_unit' (or 'pricePerUnit'), 'parent_name', 'sku',
  /// 'size', 'color', 'brand_name', 'variant_id'. Optionally a key 'attributes'
  /// may contain a List of attribute values (strings or maps with 'value').
  Uint8List buildReceiptFromRows({
    required String title,
    required List<Map<String, Object?>> itemRows,
    String currency = 'USD',
  }) {
    List<int> bytes = [];

    bytes += _gen.text(
      title,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += _gen.hr(ch: '-');

    for (final it in itemRows) {
      final qty =
          (it['quantity'] as num?)?.toInt() ??
          (it['qty'] as num?)?.toInt() ??
          1;
      final price =
          (it['price_per_unit'] as num?)?.toDouble() ??
          (it['pricePerUnit'] as num?)?.toDouble() ??
          0.0;
      final lineTotal = price * qty;
      final parentName = (it['parent_name'] as String?)?.trim();
      final sku = (it['sku'] as String?)?.trim();
      final size = (it['size'] as String?)?.trim();
      final color = (it['color'] as String?)?.trim();
      final brand = (it['brand_name'] as String?)?.trim();

      final base = (parentName != null && parentName.isNotEmpty)
          ? parentName
          : (sku != null && sku.isNotEmpty ? sku : 'SKU ${it['variant_id']}');
      final variantText = [
        size,
        color,
      ].where((e) => (e ?? '').isNotEmpty).join(' ');
      final displayName = [
        if (brand != null && brand.isNotEmpty) '[$brand] ',
        base,
        if (variantText.isNotEmpty) ' $variantText',
      ].join().trim();

      // Primary line: name + qty
      bytes += _gen.text('$displayName x$qty');

      // Price aligned right
      bytes += _gen.text(
        lineTotal.toStringAsFixed(2),
        styles: const PosStyles(align: PosAlign.right),
      );

      // Attributes line (if present)
      final rawAttrs = (it['attributes'] as List?) ?? [];
      final attrValues = rawAttrs
          .map((a) {
            if (a == null) return '';
            if (a is String) return a;
            if (a is Map) return (a['value'] ?? '').toString();
            try {
              final dyn = a as dynamic;
              return (dyn.value ?? '').toString();
            } catch (_) {
              return a.toString();
            }
          })
          .where((s) => s.isNotEmpty)
          .toList();

      if (attrValues.isNotEmpty) {
        bytes += _gen.text(
          attrValues.join(' • '),
          styles: const PosStyles(
            align: PosAlign.left,
            width: PosTextSize.size1,
            height: PosTextSize.size1,
          ),
        );
      }

      bytes += _gen.feed(1);
    }

    bytes += _gen.hr(ch: '-');
    bytes += _gen.feed(2);
    bytes += _gen.cut();
    return Uint8List.fromList(bytes);
  }
}
