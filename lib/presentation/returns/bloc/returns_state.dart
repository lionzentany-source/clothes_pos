part of 'returns_cubit.dart';

enum ReturnsStatus { initial, loading, success, failure }

class ReturnsState extends Equatable {
  final ReturnsStatus status;
  final List<Map<String, Object?>> sales;
  final String searchQuery;
  final bool hasReachedMax;
  final Sale? selectedSale;
  final List<Map<String, Object?>> selectedSaleItems;
  final Map<int, int> returnQuantities; // sale_item_id -> quantity
  final String? errorMessage;

  const ReturnsState({
    this.status = ReturnsStatus.initial,
    this.sales = const <Map<String, Object?>>[],
    this.searchQuery = '',
    this.hasReachedMax = false,
    this.selectedSale,
    this.selectedSaleItems = const <Map<String, Object?>>[],
    this.returnQuantities = const <int, int>{},
    this.errorMessage,
  });

  ReturnsState copyWith({
    ReturnsStatus? status,
    List<Map<String, Object?>>? sales,
    String? searchQuery,
    bool? hasReachedMax,
    Sale? selectedSale,
    List<Map<String, Object?>>? selectedSaleItems,
    Map<int, int>? returnQuantities,
    String? errorMessage,
  }) {
    return ReturnsState(
      status: status ?? this.status,
      sales: sales ?? this.sales,
      searchQuery: searchQuery ?? this.searchQuery,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      selectedSale: selectedSale ?? this.selectedSale,
      selectedSaleItems: selectedSaleItems ?? this.selectedSaleItems,
      returnQuantities: returnQuantities ?? this.returnQuantities,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        sales,
        searchQuery,
        hasReachedMax,
        selectedSale,
        selectedSaleItems,
        returnQuantities,
        errorMessage,
      ];
}
