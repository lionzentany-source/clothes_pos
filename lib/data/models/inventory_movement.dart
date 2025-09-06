import 'package:equatable/equatable.dart';

enum MovementType { in_, out, adjust, return_ }

class InventoryMovement extends Equatable {
  final int? id;
  final int variantId;
  final int qtyChange; // +IN, -OUT
  final MovementType movementType;
  final String? referenceType; // SALE, PURCHASE, RETURN, ADJUSTMENT
  final int? referenceId;
  final String? reason;
  final int? userId;
  final DateTime? createdAt;

  const InventoryMovement({
    this.id,
    required this.variantId,
    required this.qtyChange,
    required this.movementType,
    this.referenceType,
    this.referenceId,
    this.reason,
    this.userId,
    this.createdAt,
  });

  factory InventoryMovement.fromMap(Map<String, Object?> map) => InventoryMovement(
        id: map['id'] as int?,
        variantId: map['variant_id'] as int,
        qtyChange: map['qty_change'] as int,
        movementType: _parseType(map['movement_type'] as String),
        referenceType: map['reference_type'] as String?,
        referenceId: map['reference_id'] as int?,
        reason: map['reason'] as String?,
        userId: map['user_id'] as int?,
        createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'variant_id': variantId,
        'qty_change': qtyChange,
        'movement_type': _typeToString(movementType),
        if (referenceType != null) 'reference_type': referenceType,
        if (referenceId != null) 'reference_id': referenceId,
        if (reason != null) 'reason': reason,
        if (userId != null) 'user_id': userId,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  static MovementType _parseType(String s) {
    switch (s.toUpperCase()) {
      case 'IN':
        return MovementType.in_;
      case 'OUT':
        return MovementType.out;
      case 'ADJUST':
        return MovementType.adjust;
      case 'RETURN':
        return MovementType.return_;
      default:
        return MovementType.adjust;
    }
  }

  static String _typeToString(MovementType t) {
    switch (t) {
      case MovementType.in_:
        return 'IN';
      case MovementType.out:
        return 'OUT';
      case MovementType.adjust:
        return 'ADJUST';
      case MovementType.return_:
        return 'RETURN';
    }
  }

  @override
  List<Object?> get props => [id, variantId, qtyChange, movementType, referenceType, referenceId, reason, userId, createdAt];
}

