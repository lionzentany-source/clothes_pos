import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/presentation/pos/bloc/cart_cubit.dart';

void main() {
  group('CartCubit', () {
    test('addItem increments quantity or adds new line', () {
      final c = CartCubit();
      c.addItem(1, 10.0);
      expect(c.state.cart.length, 1);
      expect(c.state.cart.first.quantity, 1);

      c.addItem(1, 10.0);
      expect(c.state.cart.length, 1);
      expect(c.state.cart.first.quantity, 2);
    });

    test('updateQty changes quantity and enforces minimum 1', () {
      final c = CartCubit();
      c.addItem(2, 5.0);
      expect(c.state.cart.first.quantity, 1);
      c.updateQty(2, 3);
      expect(c.state.cart.first.quantity, 3);
      c.updateQty(2, 0);
      expect(c.state.cart.first.quantity, 1);
    });

    test('removeItem removes the line', () {
      final c = CartCubit();
      c.addItem(3, 7.5);
      expect(c.state.cart.length, 1);
      c.removeItem(3);
      expect(c.state.cart.isEmpty, true);
    });

    test('total computes correctly', () {
      final c = CartCubit();
      c.addItem(4, 2.5); // qty 1
      c.addItem(5, 3.0); // qty 1
      c.addItem(4, 2.5); // qty 2 for variant 4
      // total = (2 * 2.5) + (1 * 3.0) = 8.0
      expect(c.total, 8.0);
    });
  });
}
