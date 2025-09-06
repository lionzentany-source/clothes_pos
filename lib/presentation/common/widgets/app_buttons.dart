import 'package:flutter/cupertino.dart';

/// Primary filled button with minimum tap target height (44pt)
class AppPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double minHeight;
  const AppPrimaryButton({
    this.onPressed,
    required this.child,
    this.minHeight = 44,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: CupertinoButton.filled(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        onPressed: onPressed,
        child: DefaultTextStyle.merge(
          style: const TextStyle(fontSize: 16),
          child: child,
        ),
      ),
    );
  }
}

/// Icon button that ensures a minimum 44x44 tap target
class AppIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final double size;
  const AppIconButton({
    this.onPressed,
    required this.icon,
    this.size = 44,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Center(child: icon),
      ),
    );
  }
}

/// Text/ghost button that keeps transparent background but enforces minimum tap target.
class AppTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double minHeight;
  const AppTextButton({
    this.onPressed,
    required this.child,
    this.minHeight = 44,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onPressed: onPressed,
        color: CupertinoColors.transparent,
        child: child,
      ),
    );
  }
}
