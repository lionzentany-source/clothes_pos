import 'package:flutter/cupertino.dart';

class NumericKeypad extends StatelessWidget {
  final void Function(String) onKey;
  final void Function()? onBackspace;
  final void Function()? onClear;
  const NumericKeypad({
    super.key,
    required this.onKey,
    this.onBackspace,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '<'],
    ];
    return Column(
      children: [
        for (final row in keys)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final key in row)
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: SizedBox(
                    width: 56,
                    height: 48,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () {
                        if (key == '<') {
                          if (onBackspace != null) onBackspace!();
                        } else if (key == '.') {
                          onKey('.');
                        } else {
                          onKey(key);
                        }
                      },
                      child: key == '<'
                          ? const Icon(CupertinoIcons.delete_left, size: 24)
                          : Text(key, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: SizedBox(
                width: 120,
                height: 40,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  color: CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: onClear,
                  child: const Text('مسح', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
