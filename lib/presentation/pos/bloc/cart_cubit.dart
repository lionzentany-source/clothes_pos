import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Lightweight cart item model used by CartCubit.
class CartItem extends Equatable {
  final int variantId;
  final int quantity;
  final double price;

  /// Optional free-form attributes selected at add-to-cart time.
  final Map<String, String>? attributes;

  /// If the item was resolved to a specific variant after attribute selection
  /// this holds the resolved variant id.
  final int? resolvedVariantId;

  /// Optional price override provided when adding the line.
  final double? priceOverride;
  final double discountAmount;
  final double taxAmount;
  final String? note;

  const CartItem({
    required this.variantId,
    required this.quantity,
    required this.price,
    this.attributes,
    this.resolvedVariantId,
    this.priceOverride,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    this.note,
  });

  CartItem copyWith({
    int? variantId,
    int? quantity,
    double? price,
    Map<String, String>? attributes,
    int? resolvedVariantId,
    double? priceOverride,
    double? discountAmount,
    double? taxAmount,
    String? note,
  }) {
    return CartItem(
      variantId: variantId ?? this.variantId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      attributes: attributes ?? this.attributes,
      resolvedVariantId: resolvedVariantId ?? this.resolvedVariantId,
      priceOverride: priceOverride ?? this.priceOverride,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
    variantId,
    quantity,
    price,
    attributes,
    resolvedVariantId,
    priceOverride,
    discountAmount,
    taxAmount,
    note,
  ];
}

class CartState extends Equatable {
  final List<CartItem> cart;
  final bool checkingOut;
  final String? errorMessage;

  const CartState({
    this.cart = const [],
    this.checkingOut = false,
    this.errorMessage,
  });

  CartState copyWith({
    List<CartItem>? cart,
    bool? checkingOut,
    String? errorMessage,
  }) {
    return CartState(
      cart: cart ?? this.cart,
      checkingOut: checkingOut ?? this.checkingOut,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [cart, checkingOut, errorMessage];
}

/// Cubit managing a simple POS cart. This is intentionally lightweight and
/// focused on add/update/remove and computing totals. It can be expanded to
/// integrate with repositories, offline queue, and checkout logic later.
class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  /// Create a CartCubit seeded from an existing POS cart representation.
  /// Accepts a list of objects that have `variantId`, `quantity` and `price` fields.
  factory CartCubit.fromPosCart(List<dynamic> lines) {
    final items = lines
        .map(
          (l) => CartItem(
            variantId: (l['variantId'] ?? l['id'] ?? l['variant_id']) as int,
            quantity: (l['quantity'] ?? l['qty'] ?? 1) as int,
            price: (l['price'] ?? l['salePrice'] ?? l['sale_price'] ?? 0) is num
                ? ((l['price'] ?? l['salePrice'] ?? l['sale_price'] ?? 0)
                          as num)
                      .toDouble()
                : 0.0,
            attributes: (l['attributes'] as Map?)?.cast<String, String>(),
            resolvedVariantId:
                (l['resolved_variant_id'] ?? l['resolvedVariantId']) as int?,
            priceOverride: (l['price_override'] ?? l['priceOverride']) is num
                ? ((l['price_override'] ?? l['priceOverride']) as num)
                      .toDouble()
                : null,
          ),
        )
        .toList();
    final c = CartCubit();
    c.emit(c.state.copyWith(cart: items));
    return c;
  }

  void addItem(
    int variantId,
    double price, {
    Map<String, String>? attributes,
    int? resolvedVariantId,
    double? priceOverride,
  }) {
    final updated = List<CartItem>.from(state.cart);
    // Try to find existing line by resolvedVariantId first if present, else variantId
    final idx = updated.indexWhere(
      (c) =>
          (resolvedVariantId != null &&
              c.resolvedVariantId == resolvedVariantId) ||
          (resolvedVariantId == null && c.variantId == variantId),
    );
    if (idx >= 0) {
      updated[idx] = updated[idx].copyWith(quantity: updated[idx].quantity + 1);
    } else {
      updated.add(
        CartItem(
          variantId: variantId,
          quantity: 1,
          price: price,
          attributes: attributes,
          resolvedVariantId: resolvedVariantId,
          priceOverride: priceOverride,
        ),
      );
    }
    emit(state.copyWith(cart: updated, errorMessage: null));
  }

  /// Add a quantity of a variant in a single operation. This avoids calling
  /// addItem repeatedly when adding multiple units at once.
  void addQuantity(
    int variantId,
    int qty,
    double price, {
    Map<String, String>? attributes,
    int? resolvedVariantId,
    double? priceOverride,
  }) {
    if (qty < 1) return;
    final updated = List<CartItem>.from(state.cart);
    final idx = updated.indexWhere(
      (c) =>
          (resolvedVariantId != null &&
              c.resolvedVariantId == resolvedVariantId) ||
          (resolvedVariantId == null && c.variantId == variantId),
    );
    if (idx >= 0) {
      updated[idx] = updated[idx].copyWith(
        quantity: updated[idx].quantity + qty,
      );
    } else {
      updated.add(
        CartItem(
          variantId: variantId,
          quantity: qty,
          price: price,
          attributes: attributes,
          resolvedVariantId: resolvedVariantId,
          priceOverride: priceOverride,
        ),
      );
    }
    emit(state.copyWith(cart: updated, errorMessage: null));
  }

  void updateQty(int variantId, int qty) {
    if (qty < 1) qty = 1;
    final updated = state.cart
        .map((c) => c.variantId == variantId ? c.copyWith(quantity: qty) : c)
        .toList();
    emit(state.copyWith(cart: updated, errorMessage: null));
  }

  void removeItem(int variantId) {
    final updated = state.cart.where((c) => c.variantId != variantId).toList();
    emit(state.copyWith(cart: updated, errorMessage: null));
  }

  void applyDiscount(int variantId, double discountAmount) {
    final updated = state.cart
        .map(
          (c) => c.variantId == variantId
              ? c.copyWith(discountAmount: discountAmount)
              : c,
        )
        .toList();
    emit(state.copyWith(cart: updated));
  }

  /// Update line details such as discount, tax, note and attributes.
  void updateLineDetails(
    int variantId, {
    double? discountAmount,
    double? taxAmount,
    String? note,
    Map<String, String>? attributes,
  }) {
    final updated = state.cart.map((c) {
      if (c.variantId != variantId) return c;
      return c.copyWith(
        discountAmount: discountAmount ?? c.discountAmount,
        taxAmount: taxAmount ?? c.taxAmount,
        note: note ?? c.note,
        attributes: attributes ?? c.attributes,
      );
    }).toList();
    emit(state.copyWith(cart: updated));
  }

  double get total => state.cart.fold(
    0.0,
    (s, c) => s + (c.price * c.quantity) - c.discountAmount + c.taxAmount,
  );

  void clear() {
    emit(state.copyWith(cart: const [], errorMessage: null));
  }

  /// Seed the cart from an already-prepared list of items. This replaces the
  /// current cart state in one operation and is intended for bulk restores.
  void seedCart(List<CartItem> items) {
    emit(state.copyWith(cart: items, errorMessage: null));
  }
}

String? note;
