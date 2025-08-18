import 'package:equatable/equatable.dart';

class PurchaseInvoice extends Equatable {
  final int? id;
  final int supplierId;
  final String? reference;
  final DateTime receivedDate;
  final double totalCost;
  final int? createdBy;

  const PurchaseInvoice({
    this.id,
    required this.supplierId,
    this.reference,
    required this.receivedDate,
    this.totalCost = 0,
    this.createdBy,
  });

  factory PurchaseInvoice.fromMap(Map<String, Object?> map) => PurchaseInvoice(
        id: map['id'] as int?,
        supplierId: map['supplier_id'] as int,
        reference: map['reference'] as String?,
        receivedDate: DateTime.parse(map['received_date'] as String),
        totalCost: (map['total_cost'] as num).toDouble(),
        createdBy: map['created_by'] as int?,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'supplier_id': supplierId,
        if (reference != null) 'reference': reference,
        'received_date': receivedDate.toIso8601String(),
        'total_cost': totalCost,
        if (createdBy != null) 'created_by': createdBy,
      };

  @override
  List<Object?> get props => [id, supplierId, reference, receivedDate, totalCost, createdBy];
}

