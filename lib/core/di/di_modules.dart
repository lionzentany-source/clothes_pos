import 'package:clothes_pos/core/di/locator.dart';
import 'dart:io' show Platform, File;
import 'package:clothes_pos/core/hardware/uhf/uhf_reader.dart';
import 'package:clothes_pos/core/hardware/uhf/uhf_reader_bridge.dart';
import 'package:clothes_pos/data/datasources/product_dao.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/data/datasources/purchase_dao.dart';
import 'package:clothes_pos/data/repositories/purchase_repository.dart';
import 'package:clothes_pos/data/datasources/sales_dao.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/datasources/returns_dao.dart';
import 'package:clothes_pos/data/repositories/returns_repository.dart';
import 'package:clothes_pos/data/datasources/reports_dao.dart';
import 'package:clothes_pos/data/repositories/reports_repository.dart';
import 'package:clothes_pos/data/datasources/supplier_dao.dart';
import 'package:clothes_pos/data/repositories/supplier_repository.dart';
import 'package:clothes_pos/data/datasources/auth_dao.dart';
import 'package:clothes_pos/data/repositories/auth_repository.dart';
import 'package:clothes_pos/data/datasources/cash_dao.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:clothes_pos/data/datasources/settings_dao.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:clothes_pos/data/datasources/category_dao.dart';
import 'package:clothes_pos/data/repositories/category_repository.dart';
import 'package:clothes_pos/data/datasources/brand_dao.dart';
import 'package:clothes_pos/data/repositories/brand_repository.dart';
import 'package:clothes_pos/data/datasources/users_dao.dart';
import 'package:clothes_pos/data/repositories/users_repository.dart';
import 'package:clothes_pos/data/datasources/expense_dao.dart';
import 'package:clothes_pos/data/repositories/expense_repository.dart';
import 'package:clothes_pos/data/datasources/audit_dao.dart';
import 'package:clothes_pos/data/repositories/audit_repository.dart';

void registerDataModules() {
  // Product DAO & Repository
  sl.registerLazySingleton<ProductDao>(() => ProductDao(sl()));
  sl.registerLazySingleton<ProductRepository>(() => ProductRepository(sl()));

  // Purchase DAO & Repository
  sl.registerLazySingleton<PurchaseDao>(() => PurchaseDao(sl()));
  sl.registerLazySingleton<PurchaseRepository>(() => PurchaseRepository(sl()));

  // Sales DAO & Repository
  sl.registerLazySingleton<SalesDao>(() => SalesDao(sl()));
  sl.registerLazySingleton<SalesRepository>(() => SalesRepository(sl()));

  // Returns DAO & Repository
  sl.registerLazySingleton<ReturnsDao>(() => ReturnsDao(sl()));
  sl.registerLazySingleton<ReturnsRepository>(() => ReturnsRepository(sl()));

  // Reports DAO & Repository
  sl.registerLazySingleton<ReportsDao>(() => ReportsDao(sl()));
  sl.registerLazySingleton<ReportsRepository>(() => ReportsRepository(sl()));

  // Suppliers DAO & Repository
  sl.registerLazySingleton<SupplierDao>(() => SupplierDao(sl()));
  sl.registerLazySingleton<SupplierRepository>(() => SupplierRepository(sl()));

  // Categories DAO & Repository
  sl.registerLazySingleton<CategoryDao>(() => CategoryDao(sl()));
  sl.registerLazySingleton<CategoryRepository>(() => CategoryRepository(sl()));

  // Brands DAO & Repository
  sl.registerLazySingleton<BrandDao>(() => BrandDao(sl()));
  sl.registerLazySingleton<BrandRepository>(() => BrandRepository(sl()));

  // Auth DAO & Repository
  sl.registerLazySingleton<AuthDao>(() => AuthDao(sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository(sl()));

  // Cash DAO & Repository
  sl.registerLazySingleton<CashDao>(() => CashDao(sl()));
  sl.registerLazySingleton<CashRepository>(() => CashRepository(sl()));

  // Settings DAO & Repository
  sl.registerLazySingleton<SettingsDao>(() => SettingsDao(sl()));
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepository(sl()));

  // Users DAO & Repository
  sl.registerLazySingleton<UsersDao>(() => UsersDao(sl()));
  sl.registerLazySingleton<UsersRepository>(() => UsersRepository(sl()));

  // Expenses DAO & Repository
  sl.registerLazySingleton<ExpenseDao>(() => ExpenseDao(sl()));
  sl.registerLazySingleton<ExpenseRepository>(() => ExpenseRepository(sl()));

  // Audit DAO & Repository
  sl.registerLazySingleton<AuditDao>(() => AuditDao(sl()));
  sl.registerLazySingleton<AuditRepository>(() => AuditRepository(sl()));

  // UHF Reader (Windows)
  if (Platform.isWindows) {
    // محاولة اكتشاف مسار bridge32_helper.exe تلقائياً.
    // ترتيب البحث:
    // 1. متغير بيئة UHF_BRIDGE_EXE
    // 2. داخل مجلد bridge32_helper/bin/Release/net6.0/bridge32_helper.exe
    // 3. داخل مجلد bridge32_helper/bin/Debug/net6.0/bridge32_helper.exe (للتطوير)
    // 4. بجوار التطبيق الحالي (current working dir)
    String? resolved;
    final env = const String.fromEnvironment('UHF_BRIDGE_EXE');
    final envProc = Platform.environment['UHF_BRIDGE_EXE'];
    final candidates = <String>{
      if (env.isNotEmpty) env,
      if (envProc != null && envProc.trim().isNotEmpty) envProc.trim(),
      'bridge32_helper.exe',
      'bridge32_helper/bridge32_helper.exe',
      'bridge32_helper/bin/Release/net6.0/bridge32_helper.exe',
      'bridge32_helper/bin/Debug/net6.0/bridge32_helper.exe',
    };
    for (final c in candidates) {
      try {
        final f = File(c);
        if (f.existsSync()) {
          resolved = f.path;
          break;
        }
      } catch (_) {
        // ignore
      }
    }
    if (resolved == null) {
      // سجّل تحذيراً: سيؤدي استخدام المسار النسبي الغير موجود إلى خطأ عند التشغيل.
      // ignore: avoid_print
      print(
        '[UHF] لم يتم العثور على bridge32_helper.exe — حدد المسار عبر متغير البيئة UHF_BRIDGE_EXE',
      );
      resolved = 'bridge32_helper.exe';
    }
    sl.registerLazySingleton<UHFReader>(
      () => UHFReaderBridgeProcess(executablePath: resolved!),
    );
  }
}
