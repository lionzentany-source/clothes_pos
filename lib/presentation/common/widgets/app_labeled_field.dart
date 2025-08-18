import 'package:flutter/cupertino.dart';

/// Reusable labeled Cupertino text field with optional suffix (trailing) widget.
class AppLabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final TextInputType? keyboardType;
  final Widget? trailing;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppLabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.keyboardType,
    this.trailing,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, textDirection: TextDirection.rtl),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.translucent,
            child: AbsorbPointer(
              absorbing: readOnly && onTap != null,
              child: CupertinoTextField(
                controller: controller,
                placeholder: placeholder,
                keyboardType: keyboardType,
                textDirection: TextDirection.rtl,
                readOnly: readOnly,
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  border: Border.all(
                    color: CupertinoColors.separator,
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                suffix: trailing == null
                    ? null
                    : Padding(
                        padding: const EdgeInsetsDirectional.only(end: 4),
                        child: trailing,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small square icon button used inside fields.
class AppInlineIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const AppInlineIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = CupertinoColors.activeBlue,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          // 0.12 visual alpha; use withValues to avoid precision loss (withOpacity deprecated)
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 0.6),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
