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
  ];
}
