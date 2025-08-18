part of 'pos_cubit.dart';

class CartLine extends Equatable {
  final int variantId;
  final int quantity;
  final double price;
  final double discountAmount;
  final double taxAmount;
  final String? note;
  const CartLine({
    required this.variantId,
    required this.quantity,
    required this.price,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.note,
  });
  CartLine copyWith({
    int? variantId,
    int? quantity,
    double? price,
    double? discountAmount,
    double? taxAmount,
    String? note,
  }) => CartLine(
    variantId: variantId ?? this.variantId,
    quantity: quantity ?? this.quantity,
    price: price ?? this.price,
    discountAmount: discountAmount ?? this.discountAmount,
    taxAmount: taxAmount ?? this.taxAmount,
    note: note ?? this.note,
  );
  @override
  List<Object?> get props => [
    variantId,
    quantity,
    price,
    discountAmount,
    taxAmount,
    note,
  ];
}

class PosState extends Equatable {
  final bool searching;
  final String query;
  final List<dynamic> searchResults; // variants
  final List<dynamic> quickItems; // quick grid variants
  final List<CartLine> cart;
  final bool checkingOut;
  final List<dynamic> categories; // categories for quick browse
  final int? selectedCategoryId;
  const PosState({
    this.searching = false,
    this.query = '',
    this.searchResults = const [],
    this.quickItems = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.cart = const [],
    this.checkingOut = false,
  });

  PosState copyWith({
    bool? searching,
    String? query,
    List<dynamic>? searchResults,
    List<dynamic>? quickItems,
    List<dynamic>? categories,
    int? selectedCategoryId,
    List<CartLine>? cart,
    bool? checkingOut,
  }) => PosState(
    searching: searching ?? this.searching,
    query: query ?? this.query,
    searchResults: searchResults ?? this.searchResults,
    quickItems: quickItems ?? this.quickItems,
    categories: categories ?? this.categories,
    selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    cart: cart ?? this.cart,
    checkingOut: checkingOut ?? this.checkingOut,
  );

  @override
  List<Object?> get props => [
    searching,
    query,
    searchResults,
    quickItems,
    categories,
    selectedCategoryId,
    cart,
    checkingOut,
  ];
}
