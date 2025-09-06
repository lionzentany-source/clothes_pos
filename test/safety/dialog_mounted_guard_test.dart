import 'dart:io';

import 'package:test/test.dart';

/// This test enforces that every usage of `showCupertinoDialog(` in the codebase
/// is preceded (within a small window of lines) by a mounted/context guard to
/// reduce risk of calling it after a widget tree disposal.
///
/// Heuristic: For each line containing `showCupertinoDialog(` we look at the
/// previous 6 non-empty, non-comment lines for any occurrence of `.mounted` or
/// `if (!mounted)` / `if (!ctx.mounted)` etc. If none is found, the usage is
/// flagged. You can suppress a specific instance by adding the inline comment
/// `// dialog-safety: ignore` on the same line.
///
/// This is a heuristic (not a perfect parser) but keeps us from missing
/// obviously unsafe patterns. Refine if needed.
void main() {
  test('All showCupertinoDialog calls have a mounted/context guard nearby', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib directory not found');

    final violations = <String>[];
    final files = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        // Skip generated or irrelevant files if any pattern emerges later.
        .toList();

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!line.contains('showCupertinoDialog(')) continue;
        if (line.contains('dialog-safety: ignore')) continue;

        // Look backwards up to 6 lines (configurable) for a mounted guard.
        final start = (i - 6).clamp(0, lines.length - 1);
        final window = lines.sublist(start, i); // exclusive of current line
        final hasGuard = window.any(
          (l) =>
              l.contains('.mounted') ||
              l.contains('if (!mounted') ||
              l.contains('if (!context.mounted') ||
              l.contains('if (!ctx.mounted') ||
              l.contains('if (!c.mounted') ||
              l.contains('if (!sc.mounted'),
        );
        if (!hasGuard) {
          violations.add(
            '${file.path}:${i + 1}: Missing mounted guard before showCupertinoDialog',
          );
        }
      }
    }

    if (violations.isNotEmpty) {
      fail(
        'Found ${violations.length} potential unsafe showCupertinoDialog usages:\n${violations.join('\n')}',
      );
    }
  });
}
