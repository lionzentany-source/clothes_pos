import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';

class QuantityControl extends StatelessWidget {
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final double height;
  const QuantityControl({
    super.key,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(28),
            onPressed: onDecrement,
            child: const Icon(CupertinoIcons.minus, size: 16),
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            '$value',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          SizedBox(width: AppSpacing.xs),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(28),
            onPressed: onIncrement,
            child: const Icon(CupertinoIcons.add, size: 16),
          ),
        ],
      ),
    );
  }
}
