class Attribute {
  final int? id;
  final String name;

  Attribute({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory Attribute.fromMap(Map<String, dynamic> map) {
    return Attribute(id: map['id'], name: map['name']);
  }

  Attribute copyWith({int? id, String? name}) {
    return Attribute(id: id ?? this.id, name: name ?? this.name);
  }
}

class AttributeValue {
  final int? id;
  final int attributeId;
  final String value;

  AttributeValue({this.id, required this.attributeId, required this.value});

  Map<String, dynamic> toMap() {
    return {'id': id, 'attribute_id': attributeId, 'value': value};
  }

  factory AttributeValue.fromMap(Map<String, dynamic> map) {
    return AttributeValue(
      id: map['id'],
      attributeId: map['attribute_id'],
      value: map['value'],
    );
  }

  AttributeValue copyWith({int? id, int? attributeId, String? value}) {
    return AttributeValue(
      id: id ?? this.id,
      attributeId: attributeId ?? this.attributeId,
      value: value ?? this.value,
    );
  }
}
