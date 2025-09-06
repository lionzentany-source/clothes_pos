import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

/// Lightweight shimmer effect without external dependencies.
class Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  const Shimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (ctx, _) {
        final t = _c.value;
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _ShimmerPainter(t, widget.borderRadius),
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double t;
  final BorderRadius? radius;
  _ShimmerPainter(this.t, this.radius);
  @override
  void paint(Canvas canvas, Size size) {
    final base = CupertinoColors.systemGrey5;
    final highlight = CupertinoColors.systemGrey4;
    final rect = Offset.zero & size;
    final dx = (t * (size.width * 2)) - size.width; // sweep
    final gradRect = Rect.fromLTWH(
      dx - size.width,
      0,
      size.width * 2,
      size.height,
    );
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [base, highlight, base],
        stops: const [0, .5, 1],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        transform: GradientRotation(-10 * math.pi / 180),
      ).createShader(gradRect);
    final rrect = (radius ?? BorderRadius.circular(8)).toRRect(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.t != t;
}
