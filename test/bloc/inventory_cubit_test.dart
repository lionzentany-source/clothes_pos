import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/presentation/inventory/bloc/inventory_cubit.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/data/models/inventory_item_row.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/data/datasources/product_dao.dart';
import 'package:clothes_pos/core/di/locator.dart';

class _FakeRepo extends ProductRepository {
  _FakeRepo() : super(FakeDao());
  List<InventoryItemRow> rows = const [];
  @override
  Future<List<InventoryItemRow>> searchInventoryRows({
    String? name,
    String? sku,
    String? barcode,
    String? rfidTag,
    int? brandId,
    int? categoryId,
    int limit = 50,
    int offset = 0,
  }) async {
    return rows;
  }
}

class FakeDao implements ProductDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

InventoryItemRow _row({required int id, required int qty, double cost = 5, double price = 10}) {
  return InventoryItemRow(
    parentName: 'Parent',
    brandName: 'Brand',
    variant: ProductVariant(
      id: id,
      parentProductId: 1,
      sku: 'SKU$id',
      costPrice: cost,
      salePrice: price,
      quantity: qty,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InventoryCubit', () {
    test('load() fills items and clears loading', () async {
      final fake = _FakeRepo();
      fake.rows = [
        _row(id: 1, qty: 3),
        _row(id: 2, qty: 2),
      ];
      // Override DI
      if (sl.isRegistered<ProductRepository>()) {
        sl.unregister<ProductRepository>();
      }
      sl.registerSingleton<ProductRepository>(fake);

      final cubit = InventoryCubit();
      expect(cubit.state.loading, false);
      await cubit.load(query: '');
      expect(cubit.state.loading, false);
      expect(cubit.state.items.length, 2);
    });
  });
}

