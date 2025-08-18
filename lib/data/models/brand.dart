import 'package:equatable/equatable.dart';

class Brand extends Equatable {
  final int? id;
  final String name;

  const Brand({this.id, required this.name});

  Brand copyWith({int? id, String? name}) => Brand(
        id: id ?? this.id,
        name: name ?? this.name,
      );

  factory Brand.fromMap(Map<String, Object?> map) => Brand(
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

