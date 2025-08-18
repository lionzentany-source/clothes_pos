import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/inventory/screens/inventory_list_screen.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/data/datasources/product_dao.dart';
import 'package:clothes_pos/data/repositories/brand_repository.dart';
import 'package:clothes_pos/data/datasources/brand_dao.dart';
import 'package:clothes_pos/data/models/brand.dart';
import 'package:clothes_pos/data/models/inventory_item_row.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/data/repositories/auth_repository.dart';
import 'package:clothes_pos/data/datasources/auth_dao.dart';

import 'package:clothes_pos/presentation/settings/bloc/settings_cubit.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:clothes_pos/data/datasources/settings_dao.dart';

import 'package:clothes_pos/l10n_clean/app_localizations.dart';

import 'package:clothes_pos/presentation/inventory/bloc/inventory_cubit.dart';
import 'package:clothes_pos/data/models/user.dart';

class _FakeRepo extends ProductRepository {
  _FakeRepo() : super(_FakeDao());
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

class _FakeDao implements ProductDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

InventoryItemRow _row({
  required int id,
  required int qty,
  double cost = 5,
  double price = 10,
}) {
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

class _FakeBrandRepo extends BrandRepository {
  _FakeBrandRepo() : super(_FakeBrandDao());
  List<Brand> brands = const [];
  @override
  Future<List<Brand>> listAll({int limit = 200, int offset = 0}) async =>
      brands;
}

class _FakeAuthRepo extends AuthRepository {
  _FakeAuthRepo() : super(_FakeAuthDao());
  @override
  Future<AppUser?> login(String username, String password) async =>
      const AppUser(
        id: 1,
        username: 't',
        isActive: true,
        fullName: 'T',
        permissions: ['adjust_stock'],
      );
  @override
  Future<AppUser?> getById(int id) async => const AppUser(
    id: 1,
    username: 't',
    isActive: true,
    fullName: 'T',
    permissions: ['adjust_stock'],
  );
  @override
  Future<List<AppUser>> listActiveUsers() async => const [];
}

class _FakeAuthDao implements AuthDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSettingsRepo extends SettingsRepository {
  _FakeSettingsRepo() : super(_FakeSettingsDao());
  @override
  Future<String?> get(String key) async => 'LYD';
  @override
  Future<void> set(String key, String? value) async {}
}

class _FakeSettingsDao implements SettingsDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBrandDao implements BrandDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('InventoryList renders list of items', (tester) async {
    final fake = _FakeRepo();
    fake.rows = [_row(id: 1, qty: 3), _row(id: 2, qty: 2)];

    if (sl.isRegistered<ProductRepository>()) {
      sl.unregister<ProductRepository>();
    }
    // Register AuthRepository dependency used by AuthCubit
    if (sl.isRegistered<AuthRepository>()) sl.unregister<AuthRepository>();
    sl.registerSingleton<AuthRepository>(_FakeAuthRepo());

    sl.registerSingleton<ProductRepository>(fake);

    // register brands to satisfy screen init
    if (sl.isRegistered<BrandRepository>()) {
      sl.unregister<BrandRepository>();
    }
    sl.registerSingleton<BrandRepository>(
      _FakeBrandRepo()..brands = const [Brand(id: 1, name: 'Nike')],
    );

    // Provide SettingsCubit for money() formatter
    final withSettings = BlocProvider<SettingsCubit>(
      create: (_) => SettingsCubit(_FakeSettingsRepo()),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: CupertinoApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: const InventoryListScreen(),
        ),
      ),
    );

    final inventoryCubit = InventoryCubit();
    final authCubit = AuthCubit()
      ..setUser(
        const AppUser(
          id: 1,
          username: 't',
          fullName: 'T',
          isActive: true,
          permissions: ['adjust_stock', 'perform_purchases'],
        ),
      );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => authCubit),
          BlocProvider(create: (_) => inventoryCubit),
        ],
        child: withSettings,
      ),
    );

    // Allow initial build and async load
    await tester.pumpAndSettle();
    // إضافة انتظار يدوي للتأكد من انتهاء جميع المؤقتات
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(CustomScrollView), findsOneWidget);
    // Presence of any list tile implies rows rendered
    expect(find.byType(CupertinoListTile), findsWidgets);

    // تنظيف الكيوبتات بعد انتهاء الاختبار
    addTearDown(() {
      inventoryCubit.close();
      authCubit.close();
    });
  });
}
