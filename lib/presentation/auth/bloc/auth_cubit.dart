import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/models/user.dart';
import 'package:clothes_pos/data/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo = sl<AuthRepository>();
  AuthCubit() : super(const AuthState());

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
    emit(const AuthState());
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
