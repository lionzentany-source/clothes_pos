import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  final int? id;
  final String name;
  final String? contactInfo;

  const Supplier({this.id, required this.name, this.contactInfo});

  Supplier copyWith({int? id, String? name, String? contactInfo}) => Supplier(
        id: id ?? this.id,
        name: name ?? this.name,
        contactInfo: contactInfo ?? this.contactInfo,
      );

  factory Supplier.fromMap(Map<String, Object?> map) => Supplier(
        id: map['id'] as int?,
        name: map['name'] as String,
        contactInfo: map['contact_info'] as String?,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        if (contactInfo != null) 'contact_info': contactInfo,
      };

  @override
  List<Object?> get props => [id, name, contactInfo];
}

