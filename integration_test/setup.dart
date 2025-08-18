import 'package:get_it/get_it.dart';
import 'package:clothes_pos/data/repositories/auth_repository.dart';
import 'package:clothes_pos/data/models/user.dart';
import 'package:clothes_pos/data/datasources/auth_dao.dart';
import 'package:clothes_pos/core/db/database_helper.dart';

class _FakeAuthRepo extends AuthRepository {
  _FakeAuthRepo() : super(AuthDao(DatabaseHelper.instance));
  AppUser get admin => const AppUser(
        id: 1,
        username: 'admin',
        fullName: 'Administrator',
        isActive: true,
        permissions: [
          'view_reports',
          'edit_products',
          'perform_sales',
          'perform_purchases',
          'adjust_stock',
          'manage_users',
        ],
      );
  @override
  Future<AppUser?> login(String username, String password) async => admin;
  @override
  Future<AppUser?> getById(int id) async => admin;
  @override
  Future<List<AppUser>> listActiveUsers() async => [admin];
}

Future<void> injectFakesForE2E() async {
  final gi = GetIt.instance;
  if (gi.isRegistered<AuthRepository>()) {
    gi.unregister<AuthRepository>();
  }
  gi.registerSingleton<AuthRepository>(_FakeAuthRepo());
}

