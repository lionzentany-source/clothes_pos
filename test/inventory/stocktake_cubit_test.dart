import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:clothes_pos/presentation/inventory/bloc/stocktake_cubit.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await setupLocator();
  });

  test('markCountedByVariant accumulates and recomputes counters', () {
    final c = StocktakeCubit();
    // Seed state with totalUnits and one item with quantity to compute uncounted
    final st = c.state.copyWith(totalUnits: 10);
    c.emit(st);
    c.markCountedByVariant(42, units: 3);
    expect(c.state.countedUnitsByVariant[42], 3);
    expect(c.state.countedUnits, 3);
    expect(c.state.uncountedUnits, 7);
    c.markCountedByVariant(42, units: 2);
    expect(c.state.countedUnitsByVariant[42], 5);
    expect(c.state.countedUnits, 5);
    expect(c.state.uncountedUnits, 5);
  });
}
