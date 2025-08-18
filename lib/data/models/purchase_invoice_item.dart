import 'package:equatable/equatable.dart';

class PurchaseInvoiceItem extends Equatable {
  final int? id;
  final int purchaseInvoiceId;
  final int variantId;
  final int quantity;
  final double costPrice;

  const PurchaseInvoiceItem({
    this.id,
    required this.purchaseInvoiceId,
    required this.variantId,
    required this.quantity,
    required this.costPrice,
  });

  factory PurchaseInvoiceItem.fromMap(Map<String, Object?> map) => PurchaseInvoiceItem(
        id: map['id'] as int?,
        purchaseInvoiceId: map['purchase_invoice_id'] as int,
        variantId: map['variant_id'] as int,
        quantity: map['quantity'] as int,
        costPrice: (map['cost_price'] as num).toDouble(),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'purchase_invoice_id': purchaseInvoiceId,
        'variant_id': variantId,
        'quantity': quantity,
        'cost_price': costPrice,
      };

  @override
  List<Object?> get props => [id, purchaseInvoiceId, variantId, quantity, costPrice];
}

