import 'package:flutter/cupertino.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'radii.dart';

enum AppButtonKind { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonKind kind;
  final IconData? icon;
  final bool dense;
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = AppButtonKind.primary,
    this.icon,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final (bg, fg, border) = switch (kind) {
      AppButtonKind.primary => (AppColors.primary, CupertinoColors.white, null),
      AppButtonKind.secondary => (
        AppColors.surfaceAlt,
        AppColors.textPrimary,
        AppColors.border,
      ),
      AppButtonKind.ghost => (
        AppColors.surface,
        AppColors.primary,
        AppColors.primary.withValues(alpha: 0.15),
      ),
      AppButtonKind.danger => (AppColors.danger, CupertinoColors.white, null),
    };
    final padV = dense ? AppSpacing.xs : AppSpacing.sm;
    final padH = dense ? AppSpacing.sm : AppSpacing.lg;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            style: AppTypography.bodyStrong.copyWith(color: fg),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    return Container(
      decoration: BoxDecoration(
        color: enabled ? bg : bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: border == null ? null : Border.all(color: border),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(vertical: padV, horizontal: padH),
        onPressed: onPressed,
        minimumSize: Size.zero,
        child: child,
      ),
    );
  }
}
