import 'package:flutter/cupertino.dart';

class AppColors {
  AppColors._();
  // Base palette swatches
  static const Color blue600 = Color(0xFF0063B1);
  static const Color blue700 = Color(0xFF004A84);
  static const Color blue400 = Color(0xFF3380C4);
  static const Color grey50 = Color(0xFFF5F7FA);
  static const Color grey100 = CupertinoColors.systemGrey6; // alt surface
  static const Color grey200 = Color(0xFFE1E5EA);
  static const Color grey300 = Color(0xFFB5BEC7);
  static const Color green600 = Color(0xFF138A36);
  static const Color yellow500 = Color(0xFFF5A302);
  static const Color red500 = Color(0xFFD92D20);
  static const Color blue500 = Color(0xFF2E90FA); // info
  static const Color amber500 = Color(0xFFFFB200); // accent
  // Status container tints (light)
  static const Color green100 = Color(0xFFE3F6EA);
  static const Color red100 = Color(0xFFFDE8E8);
  static const Color yellow100 = Color(0xFFFFF4E0);
  static const Color blue100 = Color(0xFFE3F1FD);
  // Accessible secondary text colors (WCAG AA ≥4.5 contrast)
  static const Color textSecondaryAccessibleLight = Color(
    0xFF3E4045,
  ); // darker than system secondary
  static const Color textSecondaryAccessibleDark = Color(
    0xFFA0A0A5,
  ); // lighter on dark surface

  // Semantic roles (light theme)
  static const Color primary = blue600;
  static const Color primaryVariant = blue700;
  static const Color primaryHover = blue400;
  static const Color surface = CupertinoColors.white;
  static const Color surfaceAlt = grey100;
  static const Color background = grey50;
  static const Color border = grey200;
  static const Color borderStrong = grey300;
  // Use solid black for primary text in light mode (user request: avoid light/white text)
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = CupertinoColors
      .secondaryLabel; // legacy reference (not used in roles directly after audit)
  static const Color danger = red500;
  static const Color success = green600;
  static const Color warning = yellow500;
  static const Color info = blue500;
  static const Color accent = amber500;
  static const Color focusRing = Color(0xFF5AA9FF);
  static const Color overlaySoft = Color(0x14000000);
  static const Color overlayStrong = Color(0x33000000);
  static const Color successContainer = green100;
  static const Color dangerContainer = red100;
  static const Color warningContainer = yellow100;
  static const Color infoContainer = blue100;
}

/// A theme role bundle to simplify swapping between light/dark or brand themes.
class SemanticColorRoles {
  final Color primary;
  final Color primaryVariant;
  final Color primaryHover;
  final Color surface;
  final Color surfaceAlt;
  final Color background;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color accent;
  final Color focusRing;
  final Color overlaySoft;
  final Color overlayStrong;
  final Color successContainer;
  final Color dangerContainer;
  final Color warningContainer;
  final Color infoContainer;

  const SemanticColorRoles({
    required this.primary,
    required this.primaryVariant,
    required this.primaryHover,
    required this.surface,
    required this.surfaceAlt,
    required this.background,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.accent,
    required this.focusRing,
    required this.overlaySoft,
    required this.overlayStrong,
    required this.successContainer,
    required this.dangerContainer,
    required this.warningContainer,
    required this.infoContainer,
  });

  static const light = SemanticColorRoles(
    primary: AppColors.primary,
    primaryVariant: AppColors.primaryVariant,
    primaryHover: AppColors.primaryHover,
    surface: AppColors.surface,
    surfaceAlt: AppColors.surfaceAlt,
    background: AppColors.background,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondaryAccessibleLight,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
    accent: AppColors.accent,
    focusRing: AppColors.focusRing,
    overlaySoft: AppColors.overlaySoft,
    overlayStrong: AppColors.overlayStrong,
    successContainer: AppColors.successContainer,
    dangerContainer: AppColors.dangerContainer,
    warningContainer: AppColors.warningContainer,
    infoContainer: AppColors.infoContainer,
  );

  // Dark roles (tuned for contrast on dark surfaces)
  // Surfaces use near-iOS dark system colors; borders slightly lighter for separation.
  static const dark = SemanticColorRoles(
    primary: AppColors.primary, // keep brand color
    primaryVariant: AppColors.primaryVariant,
    primaryHover: AppColors.primaryHover,
    surface: Color(0xFF1C1C1E), // primary surface
    surfaceAlt: Color(0xFF2C2C2E), // elevated / alt surface
    background: Color(0xFF000000),
    border: Color(0xFF3A3A3C),
    borderStrong: Color(0xFF48484A),
    textPrimary: CupertinoColors.white,
    textSecondary: AppColors.textSecondaryAccessibleDark,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
    accent: AppColors.accent,
    focusRing: Color(0xFF357ABD),
    overlaySoft: Color(0x33FFFFFF),
    overlayStrong: Color(0x66FFFFFF),
    successContainer: Color(0xFF143F23),
    dangerContainer: Color(0xFF4A1E20),
    warningContainer: Color(0xFF4A3A14),
    infoContainer: Color(0xFF123952),
  );

  SemanticColorRoles copyWith({
    Color? primary,
    Color? primaryVariant,
    Color? primaryHover,
    Color? surface,
    Color? surfaceAlt,
    Color? background,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? accent,
    Color? focusRing,
    Color? overlaySoft,
    Color? overlayStrong,
    Color? successContainer,
    Color? dangerContainer,
    Color? warningContainer,
    Color? infoContainer,
  }) => SemanticColorRoles(
    primary: primary ?? this.primary,
    primaryVariant: primaryVariant ?? this.primaryVariant,
    primaryHover: primaryHover ?? this.primaryHover,
    surface: surface ?? this.surface,
    surfaceAlt: surfaceAlt ?? this.surfaceAlt,
    background: background ?? this.background,
    border: border ?? this.border,
    borderStrong: borderStrong ?? this.borderStrong,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    info: info ?? this.info,
    accent: accent ?? this.accent,
    focusRing: focusRing ?? this.focusRing,
    overlaySoft: overlaySoft ?? this.overlaySoft,
    overlayStrong: overlayStrong ?? this.overlayStrong,
    successContainer: successContainer ?? this.successContainer,
    dangerContainer: dangerContainer ?? this.dangerContainer,
    warningContainer: warningContainer ?? this.warningContainer,
    infoContainer: infoContainer ?? this.infoContainer,
  );
}
