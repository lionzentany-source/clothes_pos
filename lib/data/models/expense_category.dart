class ExpenseCategory {
  final int? id;
  final String name;
  final bool isActive;

  ExpenseCategory({this.id, required this.name, this.isActive = true});

  factory ExpenseCategory.fromMap(Map<String, Object?> m) => ExpenseCategory(
    id: m['id'] as int?,
    name: m['name'] as String,
    isActive: (m['is_active'] as int? ?? 1) == 1,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'is_active': isActive ? 1 : 0,
  };
}
