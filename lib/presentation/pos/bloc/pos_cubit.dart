import 'package:clothes_pos/data/models/payment.dart';
import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/repositories/category_repository.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

part 'pos_state.dart';

class PosCubit extends Cubit<PosState> {
  final ProductRepository _products = sl<ProductRepository>();
  final SalesRepository _sales = sl<SalesRepository>();
  final Map<int, String> _variantNameCache = {};
  Timer? _debounce;

  PosCubit() : super(const PosState());

  Future<void> loadQuickItems() async {
    // Deprecated: quick items replaced by category browse; keep empty for now.
    emit(state.copyWith(quickItems: const []));
  }

  Future<void> loadCategories() async {
    final cats = await sl<CategoryRepository>().listAll(limit: 200);
    emit(state.copyWith(categories: cats));
  }

  Map<String, String> _parseGrammar(String q) {
    final filters = <String, String>{};
    final parts = q.split(RegExp(r'\s+'));
    for (final p in parts) {
      final i = p.indexOf(':');
      if (i > 0) {
        final key = p.substring(0, i).toLowerCase();
        final val = p.substring(i + 1);
        if (val.isEmpty) continue;
        if (key == 'brand' || key == 'العلامة' || key == 'براند') {
          filters['brand'] = val;
        }
        if (key == 'color' || key == 'اللون') {
          filters['color'] = val;
        }
        if (key == 'size' || key == 'المقاس') {
          filters['size'] = val;
        }
      }
    }
    return filters;
  }

  Future<void> search(String q, {int? brandId, int? categoryId}) async {
    // immediate search (externally can be debounced wrapper)
    emit(state.copyWith(searching: true, query: q));
    final filters = _parseGrammar(q);
    final name = q
        .split(RegExp(r'\s+'))
        .where((w) => !w.contains(':'))
        .join(' ')
        .trim();
    final rows = await _products.searchVariantRowMaps(
      name: name.isEmpty ? null : name,
      brandId: brandId,
      categoryId: categoryId,
      limit: 20,
    );
    // client-side refine by color/size/brand-name substrings if provided
    final refined = rows.where((m) {
      bool ok = true;
      if (filters.containsKey('brand')) {
        ok &= ((m['brand_name'] as String?) ?? '').toLowerCase().contains(
          filters['brand']!.toLowerCase(),
        );
      }
      if (filters.containsKey('color')) {
        ok &= ((m['color'] as String?) ?? '').toLowerCase().contains(
          filters['color']!.toLowerCase(),
        );
      }
      if (filters.containsKey('size')) {
        ok &= ((m['size'] as String?) ?? '').toLowerCase().contains(
          filters['size']!.toLowerCase(),
        );
      }
      return ok;
    }).toList();
    emit(state.copyWith(searching: false, searchResults: refined));
  }

  void debouncedSearch(String q, {int? categoryId}) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      search(q, categoryId: categoryId);
    });
  }

  void updateLineDetails(
    int variantId, {
    double? discountAmount,
    double? taxAmount,
    String? note,
  }) {
    final updated = state.cart
        .map(
          (l) => l.variantId == variantId
              ? l.copyWith(
                  discountAmount: discountAmount ?? l.discountAmount,
                  taxAmount: taxAmount ?? l.taxAmount,
                  note: note ?? l.note,
                )
              : l,
        )
        .toList();
    emit(state.copyWith(cart: updated));
  }

  Future<void> selectCategory(int? categoryId) async {
    emit(state.copyWith(selectedCategoryId: categoryId));
    await search(state.query, categoryId: categoryId);
  }

  void addToCart(int variantId, double price) {
    final updated = List<CartLine>.from(state.cart);
    final idx = updated.indexWhere((l) => l.variantId == variantId);
    if (idx >= 0) {
      updated[idx] = updated[idx].copyWith(quantity: updated[idx].quantity + 1);
    } else {
      updated.add(CartLine(variantId: variantId, quantity: 1, price: price));
      // Prefetch variant name asynchronously (non-blocking)
      resolveVariantName(variantId);
    }
    emit(state.copyWith(cart: updated));
  }

  Future<String?> resolveVariantName(int variantId) async {
    if (_variantNameCache.containsKey(variantId))
      return _variantNameCache[variantId];
    final name = await _products.getVariantDisplayName(variantId);
    if (name != null) _variantNameCache[variantId] = name;
    return name;
  }

  void changeQty(int variantId, int qty) {
    final updated = state.cart
        .map(
          (l) => l.variantId == variantId
              ? l.copyWith(quantity: qty < 1 ? 1 : qty)
              : l,
        )
        .toList();
    emit(state.copyWith(cart: updated));
  }

  void removeLine(int variantId) {
    emit(
      state.copyWith(
        cart: state.cart.where((l) => l.variantId != variantId).toList(),
      ),
    );
  }

  double get total => state.cart.fold(
    0.0,
    (s, l) => s + (l.price * l.quantity) - l.discountAmount + l.taxAmount,
  );

  Future<int> checkout({
    PaymentMethod method = PaymentMethod.cash,
    int userId = 1,
    int? cashSessionId,
  }) async {
    // Backward-compatible single-payment checkout
    final p = Payment(
      amount: total,
      method: method,
      createdAt: DateTime.now(),
      cashSessionId: cashSessionId,
    );
    return checkoutWithPayments(payments: [p], userId: userId);
  }

  Future<int> checkoutWithPayments({
    required List<Payment> payments,
    int userId = 1,
  }) async {
    if (state.cart.isEmpty) {
      // Using English key fallback; actual localization should be handled at UI layer.
      throw Exception('cart_empty');
    }
    emit(state.copyWith(checkingOut: true));

    final sale = Sale(userId: userId, totalAmount: 0, saleDate: DateTime.now());
    final items = state.cart
        .map(
          (l) => SaleItem(
            saleId: 0,
            variantId: l.variantId,
            quantity: l.quantity,
            pricePerUnit: l.price,
            costAtSale: 0,
            discountAmount: l.discountAmount,
            taxAmount: l.taxAmount,
            note: l.note,
          ),
        )
        .toList();

    try {
      final saleId = await _sales.createSale(
        sale: sale,
        items: items,
        payments: payments,
      );
      emit(state.copyWith(cart: const [], checkingOut: false));
      return saleId;
    } finally {
      emit(state.copyWith(checkingOut: false));
    }
  }

  Future<bool> addByBarcode(String barcode) async {
    final variants = await _products.searchVariants(barcode: barcode, limit: 5);
    if (variants.isEmpty) return false;
    final v = variants.first;
    addToCart(v.id!, v.salePrice);
    return true;
  }

  Future<bool> addByRfid(String epc) async {
    final variants = await _products.searchVariants(rfidTag: epc, limit: 1);
    if (variants.isEmpty) return false;
    final v = variants.first;
    addToCart(v.id!, v.salePrice);
    return true;
  }
}
