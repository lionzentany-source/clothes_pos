import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/datasources/audit_dao.dart';
import 'package:clothes_pos/data/datasources/auth_dao.dart';
import 'package:clothes_pos/data/datasources/brand_dao.dart';
import 'package:clothes_pos/data/datasources/cash_dao.dart';
import 'package:clothes_pos/data/datasources/category_dao.dart';
import 'package:clothes_pos/data/datasources/expense_dao.dart';
import 'package:clothes_pos/data/datasources/product_dao.dart';
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

// Fake classes that implement the real interfaces
class FakeDatabaseHelper implements DatabaseHelper { @override Future<void> resetForTests() async {} @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeProductDao implements ProductDao { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeProductRepository implements ProductRepository { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakePurchaseDao implements PurchaseDao { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakePurchaseRepository implements PurchaseRepository { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeSalesDao implements SalesDao { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeSalesRepository implements SalesRepository { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeReturnsDao implements ReturnsDao { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeReturnsRepository implements ReturnsRepository { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeReportsDao implements ReportsDao { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeReportsRepository implements ReportsRepository { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeSupplierDao implements SupplierDao { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeSupplierRepository implements SupplierRepository { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeCategoryDao implements CategoryDao { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeCategoryRepository implements CategoryRepository { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeBrandDao implements BrandDao { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeBrandRepository implements BrandRepository { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeAuthDao implements AuthDao { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeAuthRepository implements AuthRepository { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeCashDao implements CashDao { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeCashRepository implements CashRepository { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeSettingsDao implements SettingsDao { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeSettingsRepository implements SettingsRepository { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeUsersDao implements UsersDao { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeUsersRepository implements UsersRepository { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeExpenseDao implements ExpenseDao { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeExpenseRepository implements ExpenseRepository { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeAuditDao implements AuditDao { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}
class FakeAuditRepository implements AuditRepository { @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);}

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
}
