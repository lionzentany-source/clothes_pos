import 'package:clothes_pos/data/models/product_variant.dart';

class InventoryItemRow {
  final ProductVariant variant;
  final String parentName;
  final String? brandName;
  InventoryItemRow({
    required this.variant,
    required this.parentName,
    this.brandName,
  });

  bool get isLowStock =>
      variant.reorderPoint > 0 && variant.quantity <= variant.reorderPoint;
}
