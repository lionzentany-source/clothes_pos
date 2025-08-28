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

  /// Safe parsing that tolerates bad / legacy data and prevents crashes.
  factory Expense.fromMap(Map<String, Object?> m) {
    // id
    final dynamic rawId = m['id'];
    final int? id = rawId is int
        ? rawId
        : (rawId is String ? int.tryParse(rawId) : null);

    // category id (required)
    final dynamic catRaw = m['category_id'];
    final int categoryId = catRaw is int
        ? catRaw
        : (catRaw is String ? int.tryParse(catRaw) ?? 0 : 0);

    // amount
    final dynamic amtRaw = m['amount'];
    double amount;
    if (amtRaw is num) {
      amount = amtRaw.toDouble();
    } else if (amtRaw is String) {
      amount = double.tryParse(amtRaw) ?? 0;
    } else {
      amount = 0;
    }

    // paid via
    final pvRaw = m['paid_via'];
    final paidVia = (pvRaw is String && pvRaw.isNotEmpty) ? pvRaw : 'other';

    // cash session
    final csRaw = m['cash_session_id'];
    final int? cashSessionId = csRaw is int
        ? csRaw
        : (csRaw is String ? int.tryParse(csRaw) : null);

    // date
    final dateRaw = m['date'];
    DateTime date = DateTime.now();
    if (dateRaw is String) {
      date =
          DateTime.tryParse(dateRaw) ??
          DateTime.tryParse(dateRaw.replaceFirst(' ', 'T')) ??
          date;
    }

    // created at
    DateTime? createdAt;
    final createdRaw = m['created_at'];
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw);
    }

    final description = m['description'] as String?;
    final categoryName = m['category_name'] as String?;

    return Expense(
      id: id,
      categoryId: categoryId,
      amount: amount,
      paidVia: paidVia,
      cashSessionId: cashSessionId,
      date: date,
      description: description,
      createdAt: createdAt,
      categoryName: categoryName,
    );
  }

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
