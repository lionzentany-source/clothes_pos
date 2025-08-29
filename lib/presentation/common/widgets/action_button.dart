import 'package:flutter/cupertino.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final EdgeInsetsGeometry padding;
  final Widget? leading;

  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = CupertinoColors.activeBlue,
    this.padding = const EdgeInsets.symmetric(vertical: 10),
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: padding,
      color: color,
      onPressed: onPressed,
      minimumSize: const Size(0, 48), // Replaced minSize with minimumSize
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}