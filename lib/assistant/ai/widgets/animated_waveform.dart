import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

/// A reusable widget that displays an animated waveform,
/// typically used to visualize voice input.
class AnimatedWaveform extends StatefulWidget {
  final double level;
  final bool isActive;

  const AnimatedWaveform({
    super.key,
    required this.level,
    required this.isActive,
  });

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 40),
          painter: _WaveformPainter(
            level: widget.level,
            isActive: widget.isActive,
            animationValue: _controller.value,
            activeColor: CupertinoTheme.of(context).primaryColor,
            inactiveColor: CupertinoColors.systemGrey3,
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double level;
  final bool isActive;
  final double animationValue;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformPainter({
    required this.level,
    required this.isActive,
    required this.animationValue,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isActive ? activeColor : inactiveColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerY = size.height / 2;
    // Ensure amplitude is visually pleasing even at low levels
    final amplitude = isActive ? math.max(level * 20, 2.0) : 1.0;

    path.moveTo(0, centerY);

    for (int i = 0; i <= size.width.toInt(); i++) {
      final x = i.toDouble();
      final normalizedX = x / size.width;
      // Combine multiple sine waves for a more organic look
      final wave1 = math.sin(normalizedX * 12 + animationValue * 2 * math.pi);
      final wave2 = math.sin(normalizedX * 5 + animationValue * 0.5 * math.pi);
      final y = centerY + (wave1 + wave2) * amplitude * (isActive ? 1.0 : 0.5);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
