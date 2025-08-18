import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';

/// Simple overlay toast manager (success / error / info).
class AppToast {
  static final _entries = <OverlayEntry>[];

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    final colors = context.colors;
    final bg = switch (type) {
      ToastType.success => colors.success,
      ToastType.error => colors.danger,
      ToastType.info => colors.primary,
    };
    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 16,
        right: 16,
        bottom: 32 + (_entries.length * 60),
        child: _ToastBubble(background: bg, message: message),
      ),
    );
    _entries.add(entry);
    overlay.insert(entry);
    Timer(duration, () => dismiss(entry));
  }

  static void dismiss(OverlayEntry entry) {
    if (_entries.remove(entry)) {
      entry.remove();
    }
  }
}

enum ToastType { success, error, info }

class _ToastBubble extends StatelessWidget {
  final Color background;
  final String message;
  const _ToastBubble({required this.background, required this.message});
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 180),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors.overlayStrong.withValues(
                alpha: 0.25, // new API expects 0-1 double
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
