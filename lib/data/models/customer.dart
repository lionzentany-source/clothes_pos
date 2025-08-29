import 'package:equatable/equatable.dart';

/// Customer model representing a customer in the system
class Customer extends Equatable {
  final int? id;
  final String name;
  final String? phoneNumber;

  const Customer({
    this.id,
    required this.name,
    this.phoneNumber,
  });

  /// Create Customer from database map
  factory Customer.fromMap(Map<String, Object?> map) => Customer(
        id: map['id'] as int?,
        name: map['name'] as String,
        phoneNumber: map['phone_number'] as String?,
      );

  /// Convert Customer to database map
  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      };

  /// Create a copy of this Customer with updated fields
  Customer copyWith({
    int? id,
    String? name,
    String? phoneNumber,
  }) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        phoneNumber: phoneNumber ?? this.phoneNumber,
      );

  @override
  List<Object?> get props => [id, name, phoneNumber];

  @override
  String toString() => 'Customer(id: $id, name: $name, phoneNumber: $phoneNumber)';
}
