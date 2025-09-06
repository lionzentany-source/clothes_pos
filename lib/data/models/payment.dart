import 'package:equatable/equatable.dart';

enum PaymentMethod { cash, card, mobile, refund }

class Payment extends Equatable {
  final int? id;
  final int? saleId;
  final double amount;
  final PaymentMethod method;
  final int? cashSessionId;
  final DateTime createdAt;

  const Payment({
    this.id,
    this.saleId,
    required this.amount,
    required this.method,
    this.cashSessionId,
    required this.createdAt,
  });

  factory Payment.fromMap(Map<String, Object?> map) => Payment(
        id: map['id'] as int?,
        saleId: map['sale_id'] as int?,
        amount: (map['amount'] as num).toDouble(),
        method: _parseMethod(map['method'] as String),
        cashSessionId: map['cash_session_id'] as int?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        if (saleId != null) 'sale_id': saleId,
        'amount': amount,
        'method': _methodToString(method),
        if (cashSessionId != null) 'cash_session_id': cashSessionId,
        'created_at': createdAt.toIso8601String(),
      };

  static PaymentMethod _parseMethod(String s) {
    switch (s.toUpperCase()) {
      case 'CASH':
        return PaymentMethod.cash;
      case 'CARD':
        return PaymentMethod.card;
      case 'MOBILE':
        return PaymentMethod.mobile;
      case 'REFUND':
        return PaymentMethod.refund;
      default:
        return PaymentMethod.cash;
    }
  }

  static String _methodToString(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return 'CASH';
      case PaymentMethod.card:
        return 'CARD';
      case PaymentMethod.mobile:
        return 'MOBILE';
      case PaymentMethod.refund:
        return 'REFUND';
    }
  }

  @override
  List<Object?> get props => [id, saleId, amount, method, cashSessionId, createdAt];
}

