import 'package:equatable/equatable.dart';

class ParentProduct extends Equatable {
  final int? id;
  final String name;
  final String? description;
  final int categoryId;
  final int? supplierId;
  final int? brandId;
  final String? imagePath;

  const ParentProduct({
    this.id,
    required this.name,
    this.description,
    required this.categoryId,
    this.supplierId,
    this.brandId,
    this.imagePath,
  });

  ParentProduct copyWith({
    int? id,
    String? name,
    String? description,
    int? categoryId,
    int? supplierId,
    int? brandId,
    String? imagePath,
  }) => ParentProduct(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    categoryId: categoryId ?? this.categoryId,
    supplierId: supplierId ?? this.supplierId,
    brandId: brandId ?? this.brandId,
    imagePath: imagePath ?? this.imagePath,
  );

  factory ParentProduct.fromMap(Map<String, Object?> map) => ParentProduct(
    id: map['id'] as int?,
    name: map['name'] as String,
    description: map['description'] as String?,
    categoryId: map['category_id'] as int,
    supplierId: map['supplier_id'] as int?,
    brandId: map['brand_id'] as int?,
    imagePath: map['image_path'] as String?,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    if (description != null) 'description': description,
    'category_id': categoryId,
    if (supplierId != null) 'supplier_id': supplierId,
    if (brandId != null) 'brand_id': brandId,
    if (imagePath != null) 'image_path': imagePath,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    categoryId,
    supplierId,
    brandId,
    imagePath,
  ];
}
