import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final int id;
  final String username;
  final String? fullName;
  final bool isActive;
  final List<String> permissions;

  const AppUser({
    required this.id,
    required this.username,
    this.fullName,
    required this.isActive,
    this.permissions = const [],
  });

  AppUser copyWith({List<String>? permissions}) => AppUser(
        id: id,
        username: username,
        fullName: fullName,
        isActive: isActive,
        permissions: permissions ?? this.permissions,
      );

  @override
  List<Object?> get props => [id, username, fullName, isActive, permissions];
}

