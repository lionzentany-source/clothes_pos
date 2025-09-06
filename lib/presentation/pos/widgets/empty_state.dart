import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/design/system/adaptive_layout.dart';

enum EmptyStateKind { empty, notFound, offline, error }

class EmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final EmptyStateKind kind;
  final VoidCallback? onRetry;
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = CupertinoIcons.cube_box,
    this.kind = EmptyStateKind.empty,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isTablet = context.isTablet;
    final iconSize = isTablet ? 64.0 : 48.0;
    final titleSize = isTablet ? 20.0 : 16.0;
    final messageSize = isTablet ? 16.0 : 13.0;
    final spacing = isTablet ? 16.0 : 12.0;
    final maxWidth = isTablet ? 400.0 : 280.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: c.textSecondary.withValues(alpha: 0.6),
          ),
          SizedBox(height: spacing),
          Text(
            title,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            SizedBox(height: spacing / 2),
            SizedBox(
              width: maxWidth,
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: messageSize,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (onRetry != null) ...[
            SizedBox(height: spacing),
            CupertinoButton(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 20,
                vertical: isTablet ? 12 : 8,
              ),
              onPressed: onRetry,
              child: Text(
                kind == EmptyStateKind.offline
                    ? 'إعادة المحاولة'
                    : 'محاولة مرة أخرى',
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
