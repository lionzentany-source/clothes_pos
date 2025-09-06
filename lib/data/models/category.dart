import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final int? id;
  final String name;

  const Category({this.id, required this.name});

  Category copyWith({int? id, String? name}) => Category(
        id: id ?? this.id,
        name: name ?? this.name,
      );

  factory Category.fromMap(Map<String, Object?> map) => Category(
        id: map['id'] as int?,
        name: map['name'] as String,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
      };

  @override
  List<Object?> get props => [id, name];
}

