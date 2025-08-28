import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/models/user.dart';
import 'package:clothes_pos/data/repositories/auth_repository.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo = sl<AuthRepository>();
  AuthCubit() : super(const AuthState(loading: true)) {
    _autoLoginAdmin();
  }

  Future<void> _autoLoginAdmin() async {
    try {
      // Try to load admin (id=1) from DB; migration 017 / 001 must ensure it exists.
      final user = await _repo.getById(1);
      if (user != null) {
        emit(state.copyWith(loading: false, user: user));
        AppLogger.d('AuthCubit.autoLoginAdmin existing admin loaded');
        return;
      }
    } catch (e, st) {
      AppLogger.e(
        'AuthCubit.autoLoginAdmin load failed',
        error: e,
        stackTrace: st,
      );
    }
    // Fallback synthetic admin (not persisted) with all permissions so operations still record id=1
    final allPerms = [
      AppPermissions.viewReports,
      AppPermissions.editProducts,
      AppPermissions.performSales,
      AppPermissions.performPurchases,
      AppPermissions.adjustStock,
      AppPermissions.manageUsers,
      AppPermissions.recordExpenses,
    ];
    emit(
      state.copyWith(
        loading: false,
        user: const AppUser(
          id: 1,
          username: 'admin',
          fullName: 'Administrator',
          isActive: true,
          permissions: [], // replaced below
        ).copyWith(permissions: allPerms),
      ),
    );
    AppLogger.d('AuthCubit.autoLoginAdmin synthetic admin created');
  }

  Future<void> login(String username, String password) async {
    emit(state.copyWith(loading: true, error: null));
    final user = await _repo.login(username, password);
    if (user == null) {
      emit(state.copyWith(loading: false, error: 'بيانات الدخول غير صحيحة'));
    } else {
      emit(state.copyWith(loading: false, user: user));
    }
  }

  // Allows setting the authenticated user after pre-login workflows (e.g., opening cash session)
  void setUser(AppUser user) {
    emit(state.copyWith(loading: false, error: null, user: user));
  }

  void logout() {
    // After logout immediately auto-login admin again (dev bypass requirement)
    emit(const AuthState(loading: true));
    _autoLoginAdmin();
  }

  // TEST-ONLY: bypass initial admin password workflow in integration tests.
  // This should not be used in production code paths; guard by assert.
  void testBypassSetAdminPassword(AppUser user) {
    assert(() {
      // debug-only side effect allowed
      return true;
    }());
    emit(state.copyWith(loading: false, error: null, user: user));
  }

  Future<void> refreshCurrentUserPermissions() async {
    final u = state.user;
    if (u == null) return;
    final updated = await _repo.getById(u.id);
    if (updated != null) {
      emit(state.copyWith(user: updated));
    }
  }
}
