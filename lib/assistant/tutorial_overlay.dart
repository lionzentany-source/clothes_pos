import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Colors; // for semi-transparent overlay color

class TutorialStep {
  final String title;
  final String description;
  const TutorialStep({required this.title, required this.description});
}

class _TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  const _TutorialOverlay({required this.steps});

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay> {
  int _index = 0;

  void _next() {
    if (_index < widget.steps.length - 1) {
      setState(() => _index++);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _next,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(step.description),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إغلاق'),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: _next,
                      child: Text(
                        _index < widget.steps.length - 1 ? 'التالي' : 'إنهاء',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showTutorial(
  BuildContext context,
  List<TutorialStep> steps,
) async {
  if (!context.mounted) return; // safety
  await showCupertinoDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _TutorialOverlay(steps: steps),
  );
}
