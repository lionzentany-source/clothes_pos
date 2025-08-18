import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';

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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: c.textSecondary.withOpacity(.6)),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: 280,
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              onPressed: onRetry,
              child: Text(
                kind == EmptyStateKind.offline
                    ? 'إعادة المحاولة'
                    : 'محاولة مرة أخرى',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
