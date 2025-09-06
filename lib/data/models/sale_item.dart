import 'dart:convert';
import 'package:equatable/equatable.dart';

class SaleItem extends Equatable {
  final int? id;
  final int saleId;
  final int variantId;
  final int quantity;
  final double pricePerUnit;
  final double costAtSale;
  final double discountAmount;
  final double taxAmount;
  final String? note;
  final Map<String, String>? attributes; // attribute name -> value

  const SaleItem({
    this.id,
    required this.saleId,
    required this.variantId,
    required this.quantity,
    required this.pricePerUnit,
    required this.costAtSale,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.note,
    this.attributes,
  });

  factory SaleItem.fromMap(Map<String, Object?> map) => SaleItem(
    id: map['id'] as int?,
    saleId: map['sale_id'] as int,
    variantId: map['variant_id'] as int,
    quantity: map['quantity'] as int,
    pricePerUnit: (map['price_per_unit'] as num).toDouble(),
    costAtSale: (map['cost_at_sale'] as num).toDouble(),
    discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0,
    taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
    note: map['note'] as String?,
    // Attributes are stored in the DB as a JSON TEXT column. We support two
    // shapes for backward compatibility:
    //  - legacy: a JSON object/map { "Size": "M", "Color": "Blue" }
    //  - new: an array of objects [{"id": 3, "name": "Size", "value": "M"}, ...]
    attributes: () {
      final raw = map['attributes'];
      if (raw == null) return null;
      try {
        if (raw is String) {
          final decoded = json.decode(raw);
          if (decoded is Map) {
            return Map<String, String>.from(
              decoded.map((k, v) => MapEntry(k.toString(), v?.toString())),
            );
          }
          if (decoded is List) {
            final out = <String, String>{};
            for (final e in decoded) {
              if (e is Map) {
                final name = e['name']?.toString();
                final value = e['value']?.toString();
                if (name != null && value != null) out[name] = value;
              } else if (e is String) {
                // tolerate plain string entries by using the string as a value
                out[e] = e;
              }
            }
            return out.isEmpty ? null : out;
          }
        }
        if (raw is Map) {
          return Map<String, String>.from(
            raw.map((k, v) => MapEntry(k.toString(), v?.toString())),
          );
        }
      } catch (_) {
        // fallthrough to null on error
      }
      return null;
    }(),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'sale_id': saleId,
    'variant_id': variantId,
    'quantity': quantity,
    'price_per_unit': pricePerUnit,
    'cost_at_sale': costAtSale,
    'discount_amount': discountAmount,
    'tax_amount': taxAmount,
    'note': note,
    // Persist attributes as an array of objects [{id, name, value}] to be
    // unambiguous for server-side processing. We keep in-memory representation
    // as Map<String,String>? (name->value) for compatibility with UI code.
    'attributes': attributes == null
        ? null
        : json.encode(
            attributes!.entries
                .map((e) => {'id': null, 'name': e.key, 'value': e.value})
                .toList(),
          ),
  };

  @override
  List<Object?> get props => [
    id,
    saleId,
    variantId,
    quantity,
    pricePerUnit,
    costAtSale,
    discountAmount,
    taxAmount,
    note,
    attributes,
  ];
}
