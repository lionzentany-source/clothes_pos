import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/presentation/pos/bloc/pos_cubit.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/models/payment.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/core/config/feature_flags.dart';
import '../helpers/test_helpers.dart';

import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';

class _CapturingSalesRepo extends SalesRepository {
  _CapturingSalesRepo() : super(FakeSalesDao());
  bool called = false;
  Sale? lastSale;
  List<SaleItem> lastItems = const [];
  List<Payment> lastPayments = const [];

  @override
  Future<int> createSale({
    required Sale sale,
    required List<SaleItem> items,
    required List<Payment> payments,
  }) async {
    called = true;
    lastSale = sale;
    lastItems = List.of(items);
    lastPayments = List.of(payments);
    return 42;
  }
}

void main() {
  setUpAll(() async {
    // Register all fake dependencies for predictable, fast tests
    await setupTestDependencies();
  });
  setUp(() {
    // Ensure feature flag is enabled for these tests
    FeatureFlags.setForTests(true);
  });

  group('PosCubit cart math', () {
    test('total sums price*qty minus discount plus tax', () async {
      final cubit = PosCubit();
      await cubit.addToCart(1, 10);
      await cubit.changeQty(1, 3); // 30
      // simulate discount/tax via API
      cubit.updateLineDetails(1, discountAmount: 2, taxAmount: 5);
      expect(cubit.total, 33); // 30 - 2 + 5
    });
  });

  group('PosCubit checkout', () {
    test('throws on empty cart and keeps checkingOut false', () async {
      final cubit = PosCubit();
      expect(
        () async => cubit.checkoutWithPayments(payments: const []),
        throwsException,
      );
      expect(cubit.state.checkingOut, false);
    });

    test(
      'checkoutWithPayments calls SalesRepository with built sale/items/payments and clears cart',
      () async {
        // Override SalesRepository with capturing fake
        if (sl.isRegistered<SalesRepository>()) {
          sl.unregister<SalesRepository>();
        }
        final repo = _CapturingSalesRepo();
        sl.registerSingleton<SalesRepository>(repo);

        final cubit = PosCubit();
        // Add one item with variant id 1 (FakeProductDao returns quantity 10 for id=1)
        await cubit.addToCart(1, 20);
        expect(cubit.state.cart.length, 1);

        final payments = [
          Payment(
            amount: 10,
            method: PaymentMethod.cash,
            createdAt: DateTime.now(),
            cashSessionId: 1,
          ),
          Payment(
            amount: 10,
            method: PaymentMethod.card,
            createdAt: DateTime.now(),
          ),
        ];

        final saleId = await cubit.checkoutWithPayments(
          payments: payments,
          userId: 7,
          customerId: 33,
        );

        expect(saleId, 42);
        expect(repo.called, true);
        expect(repo.lastSale, isNotNull);
        expect(repo.lastSale!.userId, 7);
        expect(repo.lastSale!.customerId, 33);
        expect(repo.lastItems.length, 1);
        final it = repo.lastItems.first;
        expect(it.variantId, 1);
        expect(it.quantity, 1);
        expect(it.pricePerUnit, 20);
        // costAtSale will be 0.0 because FakeProductDao returns costPrice key, not cost_price
        expect(it.costAtSale, 0);
        expect(repo.lastPayments.length, 2);
        expect(repo.lastPayments[0].method, PaymentMethod.cash);
        expect(repo.lastPayments[1].method, PaymentMethod.card);

        // Cart cleared and checkingOut reset
        expect(cubit.state.cart.isEmpty, true);
        expect(cubit.state.checkingOut, false);
      },
    );

    test(
      'checkout (single payment) creates one Payment with total and resets state',
      () async {
        // Override SalesRepository with capturing fake
        if (sl.isRegistered<SalesRepository>()) {
          sl.unregister<SalesRepository>();
        }
        final repo = _CapturingSalesRepo();
        sl.registerSingleton<SalesRepository>(repo);

        final cubit = PosCubit();
        await cubit.addToCart(1, 20);
        await cubit.changeQty(1, 3); // 60
        // Apply discount and tax: total -> 60 - 5 + 2 = 57
        cubit.updateLineDetails(1, discountAmount: 5, taxAmount: 2);

        final id = await cubit.checkout(
          method: PaymentMethod.cash,
          userId: 9,
          cashSessionId: 123,
        );

        expect(id, 42);
        expect(repo.called, true);
        expect(repo.lastPayments.length, 1);
        expect(repo.lastPayments.first.method, PaymentMethod.cash);
        expect(repo.lastPayments.first.cashSessionId, 123);
        expect(repo.lastPayments.first.amount, 57);
        expect(repo.lastSale!.userId, 9);
        // Reset state
        expect(cubit.state.cart.isEmpty, true);
        expect(cubit.state.checkingOut, false);
      },
    );
  });
}
