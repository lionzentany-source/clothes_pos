import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/datasources/sales_dao.dart';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';
import 'package:clothes_pos/data/models/payment.dart';

class _FakeDao extends SalesDao {
  _FakeDao() : super(DatabaseHelper.instance);
  bool called = false;
  @override
  Future<int> createSale({
    required Sale sale,
    required List<SaleItem> items,
    required List<Payment> payments,
  }) async {
    called = true;
    return 1;
  }
}

void main() {
  test('denies when permission guard fails', () async {
    final dao = _FakeDao();
    final repo = SalesRepository(
      dao,
      hasPermission: (_) => false,
      getOpenSession: () async => {'id': 1},
    );
    expect(
      () => repo.createSale(
        sale: Sale(id: 0, userId: 1, totalAmount: 0, saleDate: DateTime.now()),
        items: [
          SaleItem(
            id: 0,
            saleId: 0,
            variantId: 1,
            quantity: 1,
            pricePerUnit: 10,
            costAtSale: 8,
          ),
        ],
        payments: [],
      ),
      throwsA(isA<Exception>()),
    );
    expect(dao.called, false);
  });

  test('denies when no open session', () async {
    final dao = _FakeDao();
    final repo = SalesRepository(
      dao,
      hasPermission: (_) => true,
      getOpenSession: () async => null,
    );
    expect(
      () => repo.createSale(
        sale: Sale(id: 0, userId: 1, totalAmount: 0, saleDate: DateTime.now()),
        items: [
          SaleItem(
            id: 0,
            saleId: 0,
            variantId: 1,
            quantity: 1,
            pricePerUnit: 10,
            costAtSale: 8,
          ),
        ],
        payments: [],
      ),
      throwsA(isA<Exception>()),
    );
    expect(dao.called, false);
  });

  test('calls DAO when guards pass', () async {
    final dao = _FakeDao();
    final repo = SalesRepository(
      dao,
      hasPermission: (_) => true,
      getOpenSession: () async => {'id': 1},
    );
    final id = await repo.createSale(
      sale: Sale(id: 0, userId: 1, totalAmount: 0, saleDate: DateTime.now()),
      items: [
        SaleItem(
          id: 0,
          saleId: 0,
          variantId: 1,
          quantity: 2,
          pricePerUnit: 10,
          costAtSale: 8,
        ),
      ],
      payments: [
        Payment(
          id: 0,
          saleId: 0,
          method: PaymentMethod.cash,
          amount: 20,
          createdAt: DateTime.now(),
          cashSessionId: 1,
        ),
      ],
    );
    expect(id, 1);
    expect(dao.called, true);
  });
}
