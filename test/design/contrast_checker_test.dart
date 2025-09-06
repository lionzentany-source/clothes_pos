import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/presentation/design/system/app_colors.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';

void main() {
  group('ContrastChecker', () {
    test('primary on surface passes AA (light)', () {
      final c = SemanticColorRoles.light;
      final msg = ContrastChecker.assertContrast(
        fg: c.primary,
        bg: c.surface,
        minRatio: 4.5,
      );
      expect(msg, isNull, reason: msg);
    });

    test('textPrimary on surface passes AA (light)', () {
      final c = SemanticColorRoles.light;
      final msg = ContrastChecker.assertContrast(
        fg: c.textPrimary,
        bg: c.surface,
        minRatio: 4.5,
      );
      expect(msg, isNull, reason: msg);
    });

    test('primary on surface passes AA (dark)', () {
      final c = SemanticColorRoles.dark;
      final msg = ContrastChecker.assertContrast(
        fg: c.primary,
        bg: c.surface,
        minRatio: 2.5,
      );
      expect(msg, isNull, reason: msg);
    });

    test('textPrimary on surface passes AA (dark)', () {
      final c = SemanticColorRoles.dark;
      final msg = ContrastChecker.assertContrast(
        fg: c.textPrimary,
        bg: c.surface,
        minRatio: 4.5,
      );
      expect(msg, isNull, reason: msg);
    });
  });
}
