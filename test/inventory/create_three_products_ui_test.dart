import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/inventory/screens/product_editor_screen.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/core/config/feature_flags.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart'
    as prod_repo;
import 'package:clothes_pos/data/repositories/category_repository.dart'
    as cat_repo;
import 'package:clothes_pos/data/repositories/supplier_repository.dart'
    as sup_repo;
import 'package:clothes_pos/data/repositories/brand_repository.dart'
    as brand_repo;
import 'package:clothes_pos/data/datasources/category_dao.dart';
import 'package:clothes_pos/data/datasources/supplier_dao.dart';
import 'package:clothes_pos/data/datasources/brand_dao.dart';
import 'package:clothes_pos/data/models/category.dart';
import 'package:clothes_pos/data/models/supplier.dart';
import 'package:clothes_pos/data/models/brand.dart';
import '../helpers/test_helpers.dart'
    show FakeDatabaseHelper; // reuse DB helper fake
import 'package:clothes_pos/core/db/database_helper.dart';
import '../../integration_test/test_helpers/in_memory_repos.dart';

class _FakeCategoryRepository implements cat_repo.CategoryRepository {
  @override
  CategoryDao get dao => throw UnimplementedError();
  @override
  Future<List<Category>> listAll({int limit = 500, int offset = 0}) async => [
    const Category(id: 1, name: 'فئة تجريبية'),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSupplierRepository implements sup_repo.SupplierRepository {
  @override
  SupplierDao get dao => throw UnimplementedError();
  @override
  Future<List<Supplier>> listAll({int limit = 500, int offset = 0}) async => [
    const Supplier(id: 1, name: 'مورد تجريبي'),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBrandRepository implements brand_repo.BrandRepository {
  @override
  BrandDao get dao => throw UnimplementedError();
  @override
  Future<List<Brand>> listAll({int limit = 500}) async => [
    const Brand(id: 1, name: 'براند تجريبي'),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _setupUiTestDi(InMemoryProductRepository inMemoryRepo) async {
  await sl.reset();
  sl.registerLazySingleton<DatabaseHelper>(() => FakeDatabaseHelper());
  sl.registerLazySingleton<prod_repo.ProductRepository>(() => inMemoryRepo);
  sl.registerLazySingleton<cat_repo.CategoryRepository>(
    () => _FakeCategoryRepository(),
  );
  sl.registerLazySingleton<sup_repo.SupplierRepository>(
    () => _FakeSupplierRepository(),
  );
  sl.registerLazySingleton<brand_repo.BrandRepository>(
    () => _FakeBrandRepository(),
  );
}

Future<void> _createOneProduct(WidgetTester tester, String name) async {
  // Open editor
  await tester.tap(find.byKey(const Key('open-editor')));
  await tester.pumpAndSettle();

  // Enter name
  await tester.enterText(find.byKey(const Key('product-name-field')), name);
  await tester.pump();

  // Pick Category using a stable key
  final catTile = find.byKey(const Key('pick-category'));
  expect(catTile, findsOneWidget);
  await tester.ensureVisible(catTile);
  await tester.pump();
  await tester.tap(catTile);
  await tester.pumpAndSettle();
  final catChoice = find.widgetWithText(CupertinoButton, 'فئة تجريبية');
  expect(catChoice, findsOneWidget);
  await tester.tap(catChoice);
  await tester.pumpAndSettle();

  // Pick Supplier (optional)
  final supTile = find.byKey(const Key('pick-supplier'));
  expect(supTile, findsOneWidget);
  await tester.ensureVisible(supTile);
  await tester.pump();
  await tester.tap(supTile);
  await tester.pumpAndSettle();
  final supChoice = find.widgetWithText(CupertinoButton, 'مورد تجريبي');
  expect(supChoice, findsOneWidget);
  await tester.tap(supChoice);
  await tester.pumpAndSettle();

  // Pick Brand (optional)
  final brandTile = find.byKey(const Key('pick-brand'));
  expect(brandTile, findsOneWidget);
  await tester.ensureVisible(brandTile);
  await tester.pump();
  await tester.tap(brandTile);
  await tester.pumpAndSettle();
  final brandChoice = find.widgetWithText(CupertinoButton, 'براند تجريبي');
  expect(brandChoice, findsOneWidget);
  await tester.tap(brandChoice);
  await tester.pumpAndSettle();

  // Pick parent attributes
  final pickParentBtn = find.byKey(const Key('pick-parent-attributes-button'));
  expect(pickParentBtn, findsOneWidget);
  await tester.tap(pickParentBtn);
  await tester.pumpAndSettle();

  // Select one attribute (Color)
  expect(find.text('Color'), findsOneWidget);
  await tester.tap(find.text('Color'));
  await tester.pumpAndSettle();

  // Open variant attribute values picker
  final pickValuesBtn = find.text('إعداد قيم الخصائص');
  expect(pickValuesBtn, findsOneWidget);
  await tester.ensureVisible(pickValuesBtn);
  await tester.pump();
  await tester.tap(pickValuesBtn);
  await tester.pumpAndSettle();

  // Choose a couple values then Done
  final redFinder = find.text('Red');
  if (redFinder.evaluate().isEmpty) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -200));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(redFinder);
  await tester.pump();
  await tester.tap(redFinder);
  await tester.pump();
  await tester.tap(find.text('تم'));
  await tester.pumpAndSettle();

  // Save
  await tester.tap(find.byKey(const Key('save-product-button')));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Create 3 products end-to-end (UI)', (tester) async {
    FeatureFlags.setForTests(true);
    final repo = InMemoryProductRepository();
    await _setupUiTestDi(repo);

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(middle: Text('Host')),
            child: Center(
              child: CupertinoButton(
                key: const Key('open-editor'),
                child: const Text('Open Editor'),
                onPressed: () async {
                  await Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const ProductEditorScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Create three products
    await _createOneProduct(tester, 'P1');
    await _createOneProduct(tester, 'P2');
    await _createOneProduct(tester, 'P3');

    // Verify via repository search
    final p1 = await repo.searchParentsByName('P1');
    final p2 = await repo.searchParentsByName('P2');
    final p3 = await repo.searchParentsByName('P3');
    expect(p1.map((e) => e.name), contains('P1'));
    expect(p2.map((e) => e.name), contains('P2'));
    expect(p3.map((e) => e.name), contains('P3'));
  });
}
