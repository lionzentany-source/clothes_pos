import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clothes_pos/data/models/inventory_item_row.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/core/di/locator.dart';

part 'stocktake_state.dart';

class StocktakeCubit extends Cubit<StocktakeState> {
  final ProductRepository _repo = sl<ProductRepository>();
  StocktakeCubit() : super(const StocktakeState());

  Future<void> load({String query = ''}) async {
    emit(state.copyWith(loading: true, query: query));
    final rows = await _repo.searchInventoryRows(
      name: query.isEmpty ? null : query,
      limit: 500,
    );
    // إجمالي الوحدات لمخزون كامل
    final totalUnits = rows.fold<int>(0, (sum, r) => sum + r.variant.quantity);
    emit(state.copyWith(loading: false, items: rows, totalUnits: totalUnits));
    _recomputeCounters();
  }

  void markCountedByVariant(int variantId, {int units = 1}) {
    final current = Map<int, int>.from(state.countedUnitsByVariant);
    current.update(variantId, (v) => v + units, ifAbsent: () => units);
    emit(state.copyWith(countedUnitsByVariant: current));
    _recomputeCounters();
  }

  void unmarkVariant(int variantId) {
    final current = Map<int, int>.from(state.countedUnitsByVariant);
    current.remove(variantId);
    emit(state.copyWith(countedUnitsByVariant: current));
    _recomputeCounters();
  }

  void _recomputeCounters() {
    final byVariant = state.countedUnitsByVariant;
    final cost = state.items.fold<double>(0, (sum, row) {
      final counted = byVariant[row.variant.id ?? -1] ?? 0;
      return sum + row.variant.costPrice * counted;
    });
    final profit = state.items.fold<double>(0, (sum, row) {
      final counted = byVariant[row.variant.id ?? -1] ?? 0;
      return sum + (row.variant.salePrice - row.variant.costPrice) * counted;
    });
    final countedUnits = byVariant.values.fold<int>(0, (s, v) => s + v);
    final uncountedUnits = (state.totalUnits - countedUnits)
        .clamp(0, 1 << 30)
        .toInt();
    emit(
      state.copyWith(
        countedUnits: countedUnits,
        uncountedUnits: uncountedUnits,
        totalCostCounted: cost,
        totalProfitCounted: profit,
      ),
    );
  }

  void setBarcodeUnitsPerScan(int units) {
    if (units <= 0) return;
    emit(state.copyWith(barcodeUnitsPerScan: units));
  }
}
