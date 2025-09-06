import 'package:flutter/cupertino.dart';

/// Standard banner to show a "view-only" (permission missing) notice.
/// Provides consistent styling (soft yellow background, rounded corners, RTL text by default).
class ViewOnlyBanner extends StatelessWidget {
  final String message;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;
  final TextDirection? textDirection;
  const ViewOnlyBanner({
    super.key,
    required this.message,
    this.margin,
    this.padding,
    this.icon,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    final dir = textDirection ?? TextDirection.rtl;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: CupertinoColors.systemYellow),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemYellow,
            ),
            textDirection: dir,
          ),
        ),
      ],
    );
    return Container(
      margin: margin ?? EdgeInsets.zero,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoColors.systemYellow.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Directionality(textDirection: dir, child: content),
    );
  }
}
