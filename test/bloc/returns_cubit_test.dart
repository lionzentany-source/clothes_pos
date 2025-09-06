import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/presentation/returns/bloc/returns_cubit.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/repositories/returns_repository.dart';
import 'package:clothes_pos/data/datasources/sales_dao.dart';
import 'package:clothes_pos/data/datasources/returns_dao.dart';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/models/sale.dart';

class _FakeSalesDao extends SalesDao {
  _FakeSalesDao() : super(DatabaseHelper.instance);

  List<Map<String, Object?>> list = [];
  late Sale sale;
  List<Map<String, Object?>> itemRows = [];

  @override
  Future<List<Map<String, Object?>>> listSales({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    return list;
  }

  @override
  Future<Sale> getSale(int saleId) async {
    return sale;
  }

  @override
  Future<List<Map<String, Object?>>> itemRowsForSale(int saleId) async {
    return itemRows;
  }
}

class _FakeReturnsRepo extends ReturnsRepository {
  _FakeReturnsRepo() : super(ReturnsDao(DatabaseHelper.instance));

  bool called = false;
  int? lastSaleId;
  int? lastUserId;
  String? lastReason;
  List<ReturnLineInput> lastItems = const [];

  @override
  Future<int> createReturn({
    required int saleId,
    required int userId,
    String? reason,
    required List<ReturnLineInput> items,
  }) async {
    called = true;
    lastSaleId = saleId;
    lastUserId = userId;
    lastReason = reason;
    lastItems = List.of(items);
    return 123;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReturnsCubit', () {
    test('fetchSales loads list and sets success', () async {
      final dao = _FakeSalesDao();
      dao.list = [
        {
          'id': 1,
          'user_id': 1,
          'customer_id': null,
          'total_amount': 10.0,
          'sale_date': DateTime.now().toIso8601String(),
        },
      ];
      final salesRepo = SalesRepository(dao);
      final returnsRepo = _FakeReturnsRepo();
      final cubit = ReturnsCubit(salesRepo, returnsRepo);

      await cubit.fetchSales();

      expect(cubit.state.status, ReturnsStatus.success);
      expect(cubit.state.sales.length, 1);
      expect(cubit.state.hasReachedMax, false);
    });

    test('fetchSales with empty result sets hasReachedMax', () async {
      final dao = _FakeSalesDao();
      dao.list = [];
      final salesRepo = SalesRepository(dao);
      final returnsRepo = _FakeReturnsRepo();
      final cubit = ReturnsCubit(salesRepo, returnsRepo);

      await cubit.fetchSales();

      expect(cubit.state.hasReachedMax, true);
      expect(cubit.state.status, isNot(ReturnsStatus.failure));
    });

    test(
      'selectSale loads sale and items and initializes quantities to 0',
      () async {
        final dao = _FakeSalesDao();
        dao.sale = Sale(
          id: 5,
          userId: 1,
          totalAmount: 30,
          saleDate: DateTime.now(),
        );
        dao.itemRows = [
          {'id': 10, 'variant_id': 7, 'price_per_unit': 15.0},
          {'id': 11, 'variant_id': 8, 'price_per_unit': 5.0},
        ];
        final salesRepo = SalesRepository(dao);
        final returnsRepo = _FakeReturnsRepo();
        final cubit = ReturnsCubit(salesRepo, returnsRepo);

        await cubit.selectSale(5);

        expect(cubit.state.selectedSale?.id, 5);
        expect(cubit.state.selectedSaleItems.length, 2);
        expect(cubit.state.returnQuantities[10], 0);
        expect(cubit.state.returnQuantities[11], 0);
        expect(cubit.state.status, ReturnsStatus.success);
      },
    );

    test('updateReturnQuantity updates state map', () async {
      final dao = _FakeSalesDao();
      dao.sale = Sale(
        id: 5,
        userId: 1,
        totalAmount: 0,
        saleDate: DateTime.fromMillisecondsSinceEpoch(0),
      );
      final salesRepo = SalesRepository(dao);
      final returnsRepo = _FakeReturnsRepo();
      final cubit = ReturnsCubit(salesRepo, returnsRepo);

      // Initially empty
      expect(cubit.state.returnQuantities.isEmpty, true);
      cubit.updateReturnQuantity(10, 2);
      expect(cubit.state.returnQuantities[10], 2);
      cubit.updateReturnQuantity(10, 3);
      expect(cubit.state.returnQuantities[10], 3);
    });

    test(
      'createReturn builds inputs and calls repository with correct data',
      () async {
        final dao = _FakeSalesDao();
        dao.sale = Sale(
          id: 5,
          userId: 1,
          totalAmount: 0,
          saleDate: DateTime.fromMillisecondsSinceEpoch(0),
        );
        dao.itemRows = [
          {'id': 10, 'variant_id': 7, 'price_per_unit': 15.0},
          {'id': 11, 'variant_id': 8, 'price_per_unit': 5.0},
        ];
        final salesRepo = SalesRepository(dao);
        final returnsRepo = _FakeReturnsRepo();
        final cubit = ReturnsCubit(salesRepo, returnsRepo);

        // Load selection first
        await cubit.selectSale(5);
        // Update quantities: return 1 of item 10 and 2 of item 11
        cubit.updateReturnQuantity(10, 1);
        cubit.updateReturnQuantity(11, 2);

        await cubit.createReturn(reason: 'Damaged', userId: 42);

        expect(returnsRepo.called, true);
        expect(returnsRepo.lastSaleId, 5);
        expect(returnsRepo.lastUserId, 42);
        expect(returnsRepo.lastReason, 'Damaged');
        expect(returnsRepo.lastItems.length, 2);

        // Validate constructed ReturnLineInput entries
        final byId = {
          for (final it in returnsRepo.lastItems) it.saleItemId: it,
        };
        expect(byId.containsKey(10), true);
        expect(byId.containsKey(11), true);
        expect(byId[10]!.variantId, 7);
        expect(byId[10]!.quantity, 1);
        expect(byId[10]!.refundAmount, 15.0);
        expect(byId[11]!.variantId, 8);
        expect(byId[11]!.quantity, 2);
        expect(byId[11]!.refundAmount, 10.0);
        expect(cubit.state.status, ReturnsStatus.success);
      },
    );

    test('createReturn does nothing when no selectedSale', () async {
      final dao = _FakeSalesDao();
      final salesRepo = SalesRepository(dao);
      final returnsRepo = _FakeReturnsRepo();
      final cubit = ReturnsCubit(salesRepo, returnsRepo);

      await cubit.createReturn(reason: 'No sale selected', userId: 1);

      expect(returnsRepo.called, false);
    });
  });
}
