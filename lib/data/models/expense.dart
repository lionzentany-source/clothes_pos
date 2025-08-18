class Expense {
  final int? id;
  final int categoryId;
  final double amount;
  final String paidVia; // cash | bank | other
  final int? cashSessionId;
  final DateTime date;
  final String? description;
  final DateTime? createdAt;
  final String? categoryName; // join helper

  Expense({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.paidVia,
    this.cashSessionId,
    required this.date,
    this.description,
    this.createdAt,
    this.categoryName,
  });

  factory Expense.fromMap(Map<String, Object?> m) => Expense(
    id: m['id'] as int?,
    categoryId: m['category_id'] as int,
    amount: (m['amount'] as num).toDouble(),
    paidVia: m['paid_via'] as String,
    cashSessionId: m['cash_session_id'] as int?,
    date: DateTime.parse(m['date'] as String),
    description: m['description'] as String?,
    createdAt: m['created_at'] != null
        ? DateTime.tryParse(m['created_at'] as String)
        : null,
    categoryName: m['category_name'] as String?,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'category_id': categoryId,
    'amount': amount,
    'paid_via': paidVia,
    'cash_session_id': cashSessionId,
    'date': date.toIso8601String(),
    'description': description,
  };
}
