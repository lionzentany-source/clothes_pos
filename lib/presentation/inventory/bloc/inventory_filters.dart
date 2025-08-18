class InventoryFilters {
  final int? brandId;
  const InventoryFilters({this.brandId});

  InventoryFilters copyWith({int? brandId}) => InventoryFilters(
        brandId: brandId ?? this.brandId,
      );
}

