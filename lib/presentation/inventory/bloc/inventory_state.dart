part of 'inventory_cubit.dart';

class InventoryState extends Equatable {
  final bool loading;
  final String query;
  final List<InventoryItemRow> items;
  final int? brandId;
  const InventoryState({
    this.loading = false,
    this.query = '',
    this.items = const [],
    this.brandId,
  });

  InventoryState copyWith({
    bool? loading,
    String? query,
    List<InventoryItemRow>? items,
    int? brandId,
  }) => InventoryState(
    loading: loading ?? this.loading,
    query: query ?? this.query,
    items: items ?? this.items,
    brandId: brandId ?? this.brandId,
  );

  @override
  List<Object?> get props => [loading, query, items, brandId];
}
