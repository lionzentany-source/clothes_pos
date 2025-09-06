import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'app_colors.dart';
import 'app_typography.dart';

// Layout constants used across the presentation layer.
const double kPosNarrowBreakpoint =
    900.0; // viewport width <= this is considered "narrow"

class AppTheme {
  static CupertinoThemeData light() {
    final base = CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      barBackgroundColor: AppColors.surface,
    );
    return base.copyWith(
      textTheme: CupertinoTextThemeData(
        textStyle: AppTypography.body,
        navTitleTextStyle: AppTypography.h2,
        navLargeTitleTextStyle: AppTypography.h1,
        pickerTextStyle: AppTypography.body,
        actionTextStyle: AppTypography.bodyStrong,
        tabLabelTextStyle: AppTypography.small,
        dateTimePickerTextStyle: AppTypography.body,
      ),
    );
  }

  // Dark placeholder (can refine later)
  static CupertinoThemeData dark() {
    final base = CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.blue400,
    );
    return base.copyWith(
      textTheme: CupertinoTextThemeData(
        textStyle: AppTypography.body,
        navTitleTextStyle: AppTypography.h2,
        navLargeTitleTextStyle: AppTypography.h1,
        pickerTextStyle: AppTypography.body,
        actionTextStyle: AppTypography.bodyStrong,
        tabLabelTextStyle: AppTypography.small,
        dateTimePickerTextStyle: AppTypography.body,
      ),
    );
  }
}

extension CupertinoThemeSemanticExt on BuildContext {
  SemanticColorRoles get colors {
    final brightness = CupertinoTheme.of(this).brightness;
    return brightness == Brightness.dark
        ? SemanticColorRoles.dark
        : SemanticColorRoles.light;
  }
}

// Dev-only contrast helper (not a widget). Use in debug builds or unit tests.
class ContrastChecker {
  ContrastChecker._();

  // Relative luminance per WCAG
  static double luminance(Color c) {
    double toLinear(double v) =>
        v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) as double;
    final r = toLinear(c.r);
    final g = toLinear(c.g);
    final b = toLinear(c.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double contrastRatio(Color a, Color b) {
    final l1 = luminance(a);
    final l2 = luminance(b);
    final bright = l1 > l2 ? l1 : l2;
    final dark = l1 > l2 ? l2 : l1;
    return (bright + 0.05) / (dark + 0.05);
  }

  // Quick assertion helper: returns null if pass else message
  static String? assertContrast({
    required Color fg,
    required Color bg,
    double minRatio = 4.5, // AA normal text
  }) {
    final ratio = contrastRatio(fg, bg);
    if (ratio < minRatio) {
      return 'Contrast $ratio is below required $minRatio for fg=${fg.toARGB32().toRadixString(16)} bg=${bg.toARGB32().toRadixString(16)}';
    }
    return null;
  }
}

/// Dev-only widget to list failing contrast pairs against WCAG AA.
/// Wrap any screen with it in debug to print/report failures.
class ContrastAudit extends StatelessWidget {
  final Widget child;
  final double minRatio;
  const ContrastAudit({super.key, required this.child, this.minRatio = 4.5});

  @override
  Widget build(BuildContext context) {
    assert(() {
      final roles = context.colors;
      final pairs = <Map<String, dynamic>>[
        {
          'fg': roles.textPrimary,
          'bg': roles.surface,
          'label': 'textPrimary/surface',
        },
        {
          'fg': roles.textSecondary,
          'bg': roles.surface,
          'label': 'textSecondary/surface',
        },
        {
          'fg': roles.textPrimary,
          'bg': roles.surfaceAlt,
          'label': 'textPrimary/surfaceAlt',
        },
        {
          'fg': roles.textSecondary,
          'bg': roles.surfaceAlt,
          'label': 'textSecondary/surfaceAlt',
        },
        {
          'fg': roles.textPrimary,
          'bg': roles.background,
          'label': 'textPrimary/background',
        },
        {
          'fg': roles.textSecondary,
          'bg': roles.background,
          'label': 'textSecondary/background',
        },
        {'fg': roles.primary, 'bg': roles.surface, 'label': 'primary/surface'},
        {
          'fg': roles.success,
          'bg': roles.surfaceAlt,
          'label': 'success/surfaceAlt',
        },
        {
          'fg': roles.danger,
          'bg': roles.surfaceAlt,
          'label': 'danger/surfaceAlt',
        },
      ];
      for (final p in pairs) {
        final ratio = ContrastChecker.contrastRatio(p['fg'], p['bg']);
        if (ratio < minRatio) {
          // ignore: avoid_print
          print(
            '[Contrast FAIL] ${p['label']} ratio=${ratio.toStringAsFixed(2)} (<$minRatio)',
          );
        }
      }
      return true;
    }());
    return child;
  }
}

// Minimal math shim to avoid importing dart:math at top-level in patch context.
// (Dart analyzer will inline this.)
// (Removed custom Math shim; using dart:math instead.)
