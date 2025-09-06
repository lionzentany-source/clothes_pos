import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/design/system/adaptive_layout.dart';

/// Enhanced CupertinoButton with hover effects and iPad-optimized sizing
class AdaptiveCupertinoButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double? minSize;
  final bool filled;
  final BorderRadius? borderRadius;
  final bool enableHover;

  const AdaptiveCupertinoButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color,
    this.padding,
    this.minSize,
    this.filled = false,
    this.borderRadius,
    this.enableHover = true,
  });

  const AdaptiveCupertinoButton.filled({
    super.key,
    required this.child,
    this.onPressed,
    this.color,
    this.padding,
    this.minSize,
    this.borderRadius,
    this.enableHover = true,
  }) : filled = true;

  @override
  State<AdaptiveCupertinoButton> createState() =>
      _AdaptiveCupertinoButtonState();
}

class _AdaptiveCupertinoButtonState extends State<AdaptiveCupertinoButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final effectiveMinSize = widget.minSize ?? (isTablet ? 48.0 : 44.0);
    final effectivePadding =
        widget.padding ??
        EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 12 : 8,
        );
    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(isTablet ? 12.0 : 8.0);

    Widget button = widget.filled
        ? CupertinoButton.filled(
            onPressed: widget.onPressed,
            padding: effectivePadding,
            minimumSize: Size.square(effectiveMinSize),
            borderRadius: effectiveBorderRadius,
            child: widget.child,
          )
        : CupertinoButton(
            onPressed: widget.onPressed,
            padding: effectivePadding,
            minimumSize: Size.square(effectiveMinSize),
            color: widget.color,
            borderRadius: effectiveBorderRadius,
            child: widget.child,
          );

    if (!widget.enableHover || !isTablet) {
      return button;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          boxShadow: _isHovered && widget.onPressed != null
              ? [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Transform.scale(
          scale: _isHovered && widget.onPressed != null ? 1.02 : 1.0,
          child: button,
        ),
      ),
    );
  }
}

/// Enhanced text field with adaptive sizing
class AdaptiveCupertinoTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final int? maxLines;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const AdaptiveCupertinoTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.onChanged,
    this.keyboardType,
    this.maxLines,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final effectivePadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 12 : 8,
        );

    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: maxLines,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius:
            borderRadius ?? BorderRadius.circular(isTablet ? 12.0 : 8.0),
        border: isTablet
            ? Border.all(color: CupertinoColors.systemGrey4, width: 0.5)
            : null,
      ),
      style: TextStyle(fontSize: isTablet ? 16 : 14),
    );
  }
}

/// Adaptive search text field
class AdaptiveCupertinoSearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  const AdaptiveCupertinoSearchTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;

    return CupertinoSearchTextField(
      controller: controller,
      placeholder: placeholder,
      onChanged: onChanged,
      onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(isTablet ? 12.0 : 8.0),
        border: isTablet
            ? Border.all(color: CupertinoColors.systemGrey4, width: 0.5)
            : null,
      ),
      style: TextStyle(fontSize: isTablet ? 16 : 14),
    );
  }
}

/// Adaptive list tile with improved touch targets for iPad
class AdaptiveCupertinoListTile extends StatefulWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const AdaptiveCupertinoListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding,
  });

  @override
  State<AdaptiveCupertinoListTile> createState() =>
      _AdaptiveCupertinoListTileState();
}

class _AdaptiveCupertinoListTileState extends State<AdaptiveCupertinoListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final effectivePadding =
        widget.padding ??
        EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 16 : 12,
        );

    final tile = CupertinoListTile(
      title: widget.title,
      subtitle: widget.subtitle,
      leading: widget.leading,
      trailing: widget.trailing,
      onTap: widget.onTap,
      padding: effectivePadding,
    );

    if (!isTablet || widget.onTap == null) {
      return tile;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered
              ? CupertinoColors.systemGrey6.withValues(alpha: 0.5)
              : CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: tile,
      ),
    );
  }
}
