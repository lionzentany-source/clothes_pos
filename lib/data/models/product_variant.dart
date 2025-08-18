import 'package:equatable/equatable.dart';

class ProductVariant extends Equatable {
  final int? id;
  final int parentProductId;
  final String? size;
  final String? color;
  final String sku;
  final String? barcode;
  final String? rfidTag;
  final double costPrice;
  final double salePrice;
  final int reorderPoint;
  final int quantity;

  const ProductVariant({
    this.id,
    required this.parentProductId,
    this.size,
    this.color,
    required this.sku,
    this.barcode,
    this.rfidTag,
    required this.costPrice,
    required this.salePrice,
    this.reorderPoint = 0,
    this.quantity = 0,
  });

  ProductVariant copyWith({
    int? id,
    int? parentProductId,
    String? size,
    String? color,
    String? sku,
    String? barcode,
    String? rfidTag,
    double? costPrice,
    double? salePrice,
    int? reorderPoint,
    int? quantity,
  }) =>
      ProductVariant(
        id: id ?? this.id,
        parentProductId: parentProductId ?? this.parentProductId,
        size: size ?? this.size,
        color: color ?? this.color,
        sku: sku ?? this.sku,
        barcode: barcode ?? this.barcode,
        rfidTag: rfidTag ?? this.rfidTag,
        costPrice: costPrice ?? this.costPrice,
        salePrice: salePrice ?? this.salePrice,
        reorderPoint: reorderPoint ?? this.reorderPoint,
        quantity: quantity ?? this.quantity,
      );

  factory ProductVariant.fromMap(Map<String, Object?> map) => ProductVariant(
        id: map['id'] as int?,
        parentProductId: map['parent_product_id'] as int,
        size: map['size'] as String?,
        color: map['color'] as String?,
        sku: map['sku'] as String,
        barcode: map['barcode'] as String?,
        rfidTag: map['rfid_tag'] as String?,
        costPrice: (map['cost_price'] as num).toDouble(),
        salePrice: (map['sale_price'] as num).toDouble(),
        reorderPoint: map['reorder_point'] as int,
        quantity: map['quantity'] as int,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'parent_product_id': parentProductId,
        if (size != null) 'size': size,
        if (color != null) 'color': color,
        'sku': sku,
        if (barcode != null) 'barcode': barcode,
        if (rfidTag != null) 'rfid_tag': rfidTag,
        'cost_price': costPrice,
        'sale_price': salePrice,
        'reorder_point': reorderPoint,
        'quantity': quantity,
      };

  @override
  List<Object?> get props => [
        id,
        parentProductId,
        size,
        color,
        sku,
        barcode,
        rfidTag,
        costPrice,
        salePrice,
        reorderPoint,
        quantity,
      ];
}

