import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/models/user.dart';
import 'package:clothes_pos/data/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo = sl<AuthRepository>();
  AuthCubit() : super(const AuthState(loading: false));

  Future<void> _autoLoginAdmin() async {
    // تم تعطيل تسجيل الدخول التلقائي للمستخدم الإداري
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
