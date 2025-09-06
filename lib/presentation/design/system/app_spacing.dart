class AppSpacing {
  AppSpacing._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double section = 40;

  // iPad-optimized spacing
  static const double xxsTablet = 6;
  static const double xsTablet = 12;
  static const double smTablet = 16;
  static const double mdTablet = 20;
  static const double lgTablet = 32;
  static const double xlTablet = 48;
  static const double sectionTablet = 56;

  // Adaptive spacing based on screen width
  static double adaptive(
    double phoneValue,
    double tabletValue,
    double screenWidth,
  ) {
    return screenWidth > 768 ? tabletValue : phoneValue;
  }

  static double xxsAdaptive(double screenWidth) =>
      adaptive(xxs, xxsTablet, screenWidth);
  static double xsAdaptive(double screenWidth) =>
      adaptive(xs, xsTablet, screenWidth);
  static double smAdaptive(double screenWidth) =>
      adaptive(sm, smTablet, screenWidth);
  static double mdAdaptive(double screenWidth) =>
      adaptive(md, mdTablet, screenWidth);
  static double lgAdaptive(double screenWidth) =>
      adaptive(lg, lgTablet, screenWidth);
  static double xlAdaptive(double screenWidth) =>
      adaptive(xl, xlTablet, screenWidth);
  static double sectionAdaptive(double screenWidth) =>
      adaptive(section, sectionTablet, screenWidth);
}
