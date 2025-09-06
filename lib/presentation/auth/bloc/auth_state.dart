part of 'auth_cubit.dart';

class AuthState extends Equatable {
  final bool loading;
  final AppUser? user;
  final String? error;
  const AuthState({this.loading = false, this.user, this.error});
  AuthState copyWith({bool? loading, AppUser? user, String? error}) =>
      AuthState(loading: loading ?? this.loading, user: user ?? this.user, error: error);
  @override
  List<Object?> get props => [loading, user, error];
}

