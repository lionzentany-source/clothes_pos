import 'package:equatable/equatable.dart';

class Sale extends Equatable {
  final int? id;
  final int userId;
  final int? customerId;
  final double totalAmount;
  final DateTime saleDate;
  final String? reference;

  const Sale({
    this.id,
    required this.userId,
    this.customerId,
    required this.totalAmount,
    required this.saleDate,
    this.reference,
  });

  factory Sale.fromMap(Map<String, Object?> map) => Sale(
        id: map['id'] as int?,
        userId: map['user_id'] as int,
        customerId: map['customer_id'] as int?,
        totalAmount: (map['total_amount'] as num).toDouble(),
        saleDate: DateTime.parse(map['sale_date'] as String),
        reference: map['reference'] as String?,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        if (customerId != null) 'customer_id': customerId,
        'total_amount': totalAmount,
        'sale_date': saleDate.toIso8601String(),
        if (reference != null) 'reference': reference,
      };

  @override
  List<Object?> get props => [id, userId, customerId, totalAmount, saleDate, reference];
}

