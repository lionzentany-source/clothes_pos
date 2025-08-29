// جميع الاستيرادات في الأعلى
import 'package:clothes_pos/data/models/parent_product.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/data/models/attribute.dart';
import 'package:clothes_pos/data/models/brand.dart';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/datasources/audit_dao.dart';
import 'package:clothes_pos/data/datasources/auth_dao.dart';
import 'package:clothes_pos/data/datasources/brand_dao.dart';
import 'package:clothes_pos/data/datasources/cash_dao.dart';
import 'package:clothes_pos/data/datasources/category_dao.dart';
import 'package:clothes_pos/data/datasources/expense_dao.dart';
import 'package:clothes_pos/data/datasources/product_dao.dart';
import 'package:clothes_pos/data/models/inventory_item_row.dart';
import 'package:clothes_pos/data/models/category.dart';
import 'package:clothes_pos/data/models/supplier.dart';
import 'package:clothes_pos/data/datasources/purchase_dao.dart';
import 'package:clothes_pos/data/datasources/reports_dao.dart';
import 'package:clothes_pos/data/datasources/returns_dao.dart';
import 'package:clothes_pos/data/datasources/sales_dao.dart';
import 'package:clothes_pos/data/datasources/settings_dao.dart';
import 'package:clothes_pos/data/datasources/supplier_dao.dart';
import 'package:clothes_pos/data/datasources/users_dao.dart';
import 'package:clothes_pos/data/repositories/audit_repository.dart';
import 'package:clothes_pos/data/repositories/auth_repository.dart';
import 'package:clothes_pos/data/repositories/brand_repository.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:clothes_pos/data/repositories/category_repository.dart';
import 'package:clothes_pos/data/repositories/expense_repository.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/data/repositories/purchase_repository.dart';
import 'package:clothes_pos/data/repositories/reports_repository.dart';
import 'package:clothes_pos/data/repositories/returns_repository.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:clothes_pos/data/repositories/supplier_repository.dart';
import 'package:clothes_pos/data/repositories/users_repository.dart';
import 'package:clothes_pos/data/models/user.dart';
import 'package:clothes_pos/data/repositories/customer_repository.dart';
import 'package:clothes_pos/data/models/customer.dart';
import 'package:clothes_pos/data/models/purchase_invoice.dart';
import 'package:clothes_pos/data/models/purchase_invoice_item.dart';
import 'package:clothes_pos/data/models/sale_item.dart';
import 'package:clothes_pos/data/models/payment.dart';
import 'package:clothes_pos/data/models/sale.dart';

// Fake classes that implement the real interfaces
class FakeDatabaseHelper implements DatabaseHelper {
  @override
  Future<void> resetForTests() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeProductDao implements ProductDao {
  @override
  Future<int> insertParentProduct(ParentProduct p) async => 0;
  @override
  Future<int> updateParentProduct(ParentProduct p) async => 0;
  @override
  Future<int> deleteParentProduct(int id) async => 0;
  @override
  Future<ParentProduct?> getParentById(int id) async => null;
  @override
  Future<List<ParentProduct>> searchParentsByName(
    String q, {
    int limit = 20,
    int offset = 0,
  }) async => [];
  @override
  Future<int> insertVariant(ProductVariant v) async => 0;
  @override
  Future<int> updateVariant(ProductVariant v) async => 0;
  @override
  Future<void> updateSalePrice({
    required int variantId,
    required double salePrice,
  }) async {}
  @override
  Future<int> deleteVariant(int id) async => 0;
  @override
  Future<List<ProductVariant>> getVariantsByParent(int parentId) async => [];
  @override
  Future<List<ProductVariant>> searchVariants({
    String? name,
    String? sku,
    String? barcode,
    String? rfidTag,
    int? brandId,
    int? categoryId,
    int limit = 20,
    int offset = 0,
  }) async => [];
  @override
  Future<List<Map<String, Object?>>> searchVariantRows({
    String? name,
    String? sku,
    String? barcode,
    String? rfidTag,
    int? brandId,
    int? categoryId,
    int limit = 20,
    int offset = 0,
  }) async => [];
  @override
  Future<Map<String, Object?>?> getVariantRowById(int id) async {
    if (id == 1) {
      return {
        'id': 1,
        'parentProductId': 1,
        'size': 'M',
        'color': 'أحمر',
        'sku': 'SKU1',
        'barcode': '123456',
        'costPrice': 10,
        'salePrice': 20,
        'reorderPoint': 1,
        'quantity': 10,
        'parentName': 'منتج تجريبي',
        'brandName': 'براند تجريبي',
      };
    }
    return {};
  }

  @override
  Future<ProductVariant?> getVariantWithAttributesById(int id) async {
    // Simple fake implementation for tests: return a ProductVariant for id==1
    if (id == 1) {
      return ProductVariant(
        id: 1,
        parentProductId: 1,
        size: 'M',
        color: 'أحمر',
        sku: 'SKU1',
        barcode: '123456',
        costPrice: 10,
        salePrice: 20,
        reorderPoint: 1,
        quantity: 10,
        imagePath: null,
      );
    }
    return null;
  }

  @override
  Future<List<Map<String, Object?>>> getVariantRowsByIds(List<int> ids) async {
    final out = <Map<String, Object?>>[];
    for (final id in ids) {
      try {
        final row = await getVariantRowById(id);
        if (row != null && row.isNotEmpty) out.add(row);
      } catch (_) {
        // ignore
      }
    }
    return out;
  }

  @override
  Future<List<ProductVariant>> getVariantsByIds(List<int> ids) async {
    final out = <ProductVariant>[];
    for (final id in ids) {
      try {
        final v = await getVariantWithAttributesById(id);
        if (v != null) out.add(v);
      } catch (_) {
        // ignore
      }
    }
    return out;
  }

  @override
  Future<Map<String, Object?>> getParentWithAttributes(int id) async {
    if (id == 1) {
      return {
        'parent': {
          'id': 1,
          'name': 'منتج تجريبي',
          'description': 'منتج للاختبار',
          'category_id': 1,
          'supplier_id': 1,
          'brand_id': 1,
          'image_path': null,
        },
        'attributes': [
          {'id': 1, 'name': 'Color'},
          {'id': 2, 'name': 'Size'},
        ],
      };
    }
    return {};
  }

  @override
  Future<List<ProductVariant>> getLowStockVariants({
    int limit = 50,
    int offset = 0,
  }) async => [];
  @override
  Future<void> addRfidTag({
    required int variantId,
    required String epc,
  }) async {}
  @override
  Future<void> removeRfidTag({required String epc}) async {}
  @override
  Future<List<String>> listRfidTags(int variantId) async => [];
  @override
  Future<int> createProductWithVariants(
    ParentProduct p,
    List<ProductVariant> vs, [
    List<Attribute>? parentAttributes,
  ]) async => 0;
  @override
  Future<void> updateProductAndVariants(
    ParentProduct p,
    List<ProductVariant> vs, [
    List<Attribute>? parentAttributes,
  ]) async {}
  @override
  Future<List<String>> distinctSizes({int limit = 100}) async => [];
  @override
  Future<List<String>> distinctColors({int limit = 100}) async => [];
  @override
  Future<List<String>> distinctBrands({int limit = 100}) async => [];
  // نهاية FakeProductDao
  // تم حذف التكرار: الدالة getVariantRowById معرفة مسبقاً
}

class FakeProductRepository implements ProductRepository {
  // إضافة getter وهمي للـ dao لمنع الخطأ في PosCubit
  @override
  ProductDao get dao => FakeProductDao();

  @override
  Future<List<String>> distinctSizes({int limit = 100}) async => ['M', 'L'];

  @override
  Future<List<String>> distinctColors({int limit = 100}) async => [
    'أحمر',
    'أزرق',
  ];

  @override
  Future<List<String>> distinctBrands({int limit = 100}) async => [
    'براند تجريبي',
  ];

  Future<List<ParentProduct>> listAll({int limit = 20, int offset = 0}) async =>
      [
        ParentProduct(
          id: 1,
          name: 'منتج تجريبي',
          description: 'منتج للاختبار',
          categoryId: 1,
          supplierId: 1,
          brandId: 1,
          imagePath: null,
        ),
      ];

  @override
  Future<List<ProductVariant>> searchVariants({
    String? name,
    String? sku,
    String? barcode,
    String? rfidTag,
    int? brandId,
    int? categoryId,
    int limit = 20,
    int offset = 0,
  }) async => [
    ProductVariant(
      id: 1,
      parentProductId: 1,
      size: 'M',
      color: 'أحمر',
      sku: 'SKU1',
      barcode: '123456',
      costPrice: 10,
      salePrice: 20,
      reorderPoint: 1,
      quantity: 10,
      imagePath: null,
    ),
  ];

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
  }) async => [
    InventoryItemRow(
      parentName: 'منتج تجريبي',
      variant: ProductVariant(
        id: 1,
        parentProductId: 1,
        size: 'M',
        color: 'أحمر',
        sku: 'SKU1',
        barcode: '123456',
        costPrice: 10,
        salePrice: 20,
        reorderPoint: 1,
        quantity: 10,
        imagePath: null,
      ),
    ),
  ];

  @override
  Future<String?> getVariantDisplayName(int variantId) async =>
      'Variant $variantId';

  @override
  Future<List<Map<String, Object?>>> searchVariantRowMaps({
    String? name,
    String? sku,
    String? barcode,
    String? rfidTag,
    int? brandId,
    int? categoryId,
    int limit = 20,
    int offset = 0,
  }) async => [
    {
      'id': 1,
      'parent_product_id': 1,
      'size': 'M',
      'color': 'أحمر',
      'sku': 'SKU1',
      'barcode': '123456',
      'cost_price': 10.0,
      'sale_price': 20.0,
      'reorder_point': 1,
      'quantity': 10,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'image_path': null,
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePurchaseDao implements PurchaseDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePurchaseRepository implements PurchaseRepository {
  @override
  Future<int> createInvoice(
    PurchaseInvoice invoice,
    List<PurchaseInvoiceItem> items,
  ) async {
    // محاكاة إضافة الفاتورة بنجاح
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSalesDao implements SalesDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSalesRepository implements SalesRepository {
  @override
  Future<int> createSale({
    required Sale sale,
    required List<SaleItem> items,
    required List<Payment> payments,
  }) async {
    // محاكاة إضافة عملية البيع بنجاح
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeReturnsDao implements ReturnsDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeReturnsRepository implements ReturnsRepository {
  @override
  Future<int> createReturn({
    required int saleId,
    required int userId,
    String? reason,
    required List<ReturnLineInput> items,
  }) async {
    // محاكاة إضافة عملية المرتجع بنجاح
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeReportsDao implements ReportsDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeReportsRepository implements ReportsRepository {
  @override
  Future<double> salesTotalByDate({
    required String startIso,
    required String endIso,
    int? userId,
    int? categoryId,
  }) async {
    // Return 0.0 by default for tests.
    return 0.0;
  }

  @override
  Future<double> purchasesTotalByDate({
    required String startIso,
    required String endIso,
    int? userId,
  }) async {
    return 0.0;
  }

  @override
  Future<double> returnsTotalByDate({
    required String startIso,
    required String endIso,
    int? userId,
  }) async {
    return 0.0;
  }

  @override
  Future<double> profitByDate({
    required String startIso,
    required String endIso,
    int? userId,
  }) async {
    return 0.0;
  }

  @override
  Future<int> customerCount() async => 0;

  @override
  Future<int> inventoryCount() async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSupplierDao implements SupplierDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSupplierRepository implements SupplierRepository {
  @override
  Future<List<Supplier>> listAll({int limit = 500, int offset = 0}) async {
    return [Supplier(id: 1, name: 'مورد تجريبي')];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCategoryDao implements CategoryDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCategoryRepository implements CategoryRepository {
  @override
  Future<List<Category>> listAll({int limit = 500, int offset = 0}) async {
    return [Category(id: 1, name: 'فئة تجريبية')];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeBrandDao implements BrandDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeBrandRepository implements BrandRepository {
  @override
  Future<List<Brand>> listAll({int limit = 500}) async {
    return [Brand(id: 1, name: 'براند تجريبي')];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthDao implements AuthDao {
  @override
  Future<List<AppUser>> listActiveUsers() async {
    // FakeAuthDao.listActiveUsers called
    return [
      AppUser(
        id: 1,
        username: 'test',
        fullName: 'مستخدم تجريبي',
        isActive: true,
        permissions: ['perform_sales'],
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepository implements AuthRepository {
  @override
  final FakeAuthDao dao = FakeAuthDao();

  @override
  Future<List<AppUser>> listActiveUsers() async {
    return dao.listActiveUsers();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCashDao implements CashDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCashRepository implements CashRepository {
  @override
  Future<Map<String, Object?>?> getOpenSession() async {
    // جلسة كاش افتراضية للاختبار
    return {'id': 1, 'openedBy': 1, 'openingFloat': 100.0, 'cash': 100.0};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSettingsDao implements SettingsDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSettingsRepository implements SettingsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUsersDao implements UsersDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUsersRepository implements UsersRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeExpenseDao implements ExpenseDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeExpenseRepository implements ExpenseRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuditDao implements AuditDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuditRepository implements AuditRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCustomerRepository implements CustomerRepository {
  @override
  Future<List<Customer>> listAll({int limit = 500, int offset = 0}) async {
    return [Customer(id: 1, name: 'عميل تجريبي')];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> setupTestDependencies() async {
  await sl.reset();

  // Register fakes
  sl.registerLazySingleton<DatabaseHelper>(() => FakeDatabaseHelper());
  sl.registerLazySingleton<ProductDao>(() => FakeProductDao());
  sl.registerLazySingleton<ProductRepository>(() => FakeProductRepository());
  sl.registerLazySingleton<PurchaseDao>(() => FakePurchaseDao());
  sl.registerLazySingleton<PurchaseRepository>(() => FakePurchaseRepository());
  sl.registerLazySingleton<SalesDao>(() => FakeSalesDao());
  sl.registerLazySingleton<SalesRepository>(() => FakeSalesRepository());
  sl.registerLazySingleton<ReturnsDao>(() => FakeReturnsDao());
  sl.registerLazySingleton<ReturnsRepository>(() => FakeReturnsRepository());
  sl.registerLazySingleton<ReportsDao>(() => FakeReportsDao());
  sl.registerLazySingleton<ReportsRepository>(() => FakeReportsRepository());
  sl.registerLazySingleton<SupplierDao>(() => FakeSupplierDao());
  sl.registerLazySingleton<SupplierRepository>(() => FakeSupplierRepository());
  sl.registerLazySingleton<CategoryDao>(() => FakeCategoryDao());
  sl.registerLazySingleton<CategoryRepository>(() => FakeCategoryRepository());
  sl.registerLazySingleton<BrandDao>(() => FakeBrandDao());
  sl.registerLazySingleton<BrandRepository>(() => FakeBrandRepository());
  sl.registerLazySingleton<AuthDao>(() => FakeAuthDao());
  sl.registerLazySingleton<AuthRepository>(() => FakeAuthRepository());
  sl.registerLazySingleton<CashDao>(() => FakeCashDao());
  sl.registerLazySingleton<CashRepository>(() => FakeCashRepository());
  sl.registerLazySingleton<SettingsDao>(() => FakeSettingsDao());
  sl.registerLazySingleton<SettingsRepository>(() => FakeSettingsRepository());
  sl.registerLazySingleton<UsersDao>(() => FakeUsersDao());
  sl.registerLazySingleton<UsersRepository>(() => FakeUsersRepository());
  sl.registerLazySingleton<ExpenseDao>(() => FakeExpenseDao());
  sl.registerLazySingleton<ExpenseRepository>(() => FakeExpenseRepository());
  sl.registerLazySingleton<AuditDao>(() => FakeAuditDao());
  sl.registerLazySingleton<AuditRepository>(() => FakeAuditRepository());
  sl.registerLazySingleton<CustomerRepository>(() => FakeCustomerRepository());
}
