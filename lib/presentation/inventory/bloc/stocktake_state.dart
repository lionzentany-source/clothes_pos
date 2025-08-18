part of 'stocktake_cubit.dart';

class StocktakeState extends Equatable {
  final bool loading;
  final String query;
  final List<InventoryItemRow> items;
  final int totalUnits; // sum of all variant.quantity across full inventory
  final Map<int, int> countedUnitsByVariant; // variantId -> units counted
  final int countedUnits; // derived
  final int uncountedUnits; // derived
  final double totalCostCounted; // derived
  final double totalProfitCounted; // derived
  final int barcodeUnitsPerScan; // UI option for barcode scans

  const StocktakeState({
    this.loading = false,
    this.query = '',
    this.items = const [],
    this.totalUnits = 0,
    this.countedUnitsByVariant = const {},
    this.countedUnits = 0,
    this.uncountedUnits = 0,
    this.totalCostCounted = 0,
    this.totalProfitCounted = 0,
    this.barcodeUnitsPerScan = 1,
  });

  StocktakeState copyWith({
    bool? loading,
    String? query,
    List<InventoryItemRow>? items,
    int? totalUnits,
    Map<int, int>? countedUnitsByVariant,
    int? countedUnits,
    int? uncountedUnits,
    double? totalCostCounted,
    double? totalProfitCounted,
    int? barcodeUnitsPerScan,
  }) => StocktakeState(
    loading: loading ?? this.loading,
    query: query ?? this.query,
    items: items ?? this.items,
    totalUnits: totalUnits ?? this.totalUnits,
    countedUnitsByVariant: countedUnitsByVariant ?? this.countedUnitsByVariant,
    countedUnits: countedUnits ?? this.countedUnits,
    uncountedUnits: uncountedUnits ?? this.uncountedUnits,
    totalCostCounted: totalCostCounted ?? this.totalCostCounted,
    totalProfitCounted: totalProfitCounted ?? this.totalProfitCounted,
    barcodeUnitsPerScan: barcodeUnitsPerScan ?? this.barcodeUnitsPerScan,
  );

  @override
  List<Object?> get props => [
    loading,
    query,
    items,
    totalUnits,
    countedUnitsByVariant,
    countedUnits,
    uncountedUnits,
    totalCostCounted,
    totalProfitCounted,
    barcodeUnitsPerScan,
  ];
}
