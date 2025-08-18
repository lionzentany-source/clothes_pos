import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/presentation/pos/bloc/pos_cubit.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    // Ensure sqflite uses FFI on desktop tests and DI is ready
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await setupLocator();
  });

  group('PosCubit cart math', () {
    test('total sums price*qty minus discount plus tax', () {
      final cubit = PosCubit();
      cubit.addToCart(1, 10);
      cubit.changeQty(1, 3); // 30
      // simulate discount/tax via copying state (no direct API present)
      final l = cubit.state.cart.first.copyWith(
        discountAmount: 2,
        taxAmount: 5,
      );
      cubit.emit(cubit.state.copyWith(cart: [l]));
      expect(cubit.total, 33); // 30 - 2 + 5
    });
  });
}
