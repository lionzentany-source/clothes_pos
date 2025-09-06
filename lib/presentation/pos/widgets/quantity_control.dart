import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/adaptive_layout.dart';

class QuantityControl extends StatefulWidget {
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final double? height;

  const QuantityControl({
    super.key,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    this.height,
  });

  @override
  State<QuantityControl> createState() => _QuantityControlState();
}

class _QuantityControlState extends State<QuantityControl> {
  bool _decrementHovered = false;
  bool _incrementHovered = false;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final effectiveHeight = widget.height ?? (isTablet ? 44.0 : 32.0);
    final buttonSize = effectiveHeight - 8;
    final iconSize = isTablet ? 18.0 : 16.0;
    final fontSize = isTablet ? 16.0 : 14.0;

    return Container(
      height: effectiveHeight,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? AppSpacing.sm : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(effectiveHeight / 2),
        border: isTablet
            ? Border.all(color: CupertinoColors.systemGrey4, width: 0.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MouseRegion(
            onEnter: (_) => setState(() => _decrementHovered = true),
            onExit: (_) => setState(() => _decrementHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: _decrementHovered
                    ? CupertinoColors.systemGrey5
                    : CupertinoColors.transparent,
                borderRadius: BorderRadius.circular(buttonSize / 2),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.square(buttonSize),
                onPressed: widget.onDecrement,
                child: Icon(
                  CupertinoIcons.minus,
                  size: iconSize,
                  color: widget.value > 1
                      ? CupertinoColors.label
                      : CupertinoColors.quaternaryLabel,
                ),
              ),
            ),
          ),
          SizedBox(width: isTablet ? AppSpacing.sm : AppSpacing.xs),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Text(
              '${widget.value}',
              key: ValueKey(widget.value),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label,
              ),
            ),
          ),
          SizedBox(width: isTablet ? AppSpacing.sm : AppSpacing.xs),
          MouseRegion(
            onEnter: (_) => setState(() => _incrementHovered = true),
            onExit: (_) => setState(() => _incrementHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: _incrementHovered
                    ? CupertinoColors.systemGrey5
                    : CupertinoColors.transparent,
                borderRadius: BorderRadius.circular(buttonSize / 2),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.square(buttonSize),
                onPressed: widget.onIncrement,
                child: Icon(
                  CupertinoIcons.add,
                  size: iconSize,
                  color: CupertinoColors.label,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
