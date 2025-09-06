import 'package:flutter/cupertino.dart';

/// Helper class for adaptive layouts based on screen size
class AdaptiveLayout {
  AdaptiveLayout._();

  /// Breakpoints for different screen sizes
  static const double phoneBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// Check if current screen is tablet or larger
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= phoneBreakpoint;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get appropriate padding for current screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    final width = screenWidth(context);
    if (width >= desktopBreakpoint) {
      return const EdgeInsets.all(24);
    } else if (width >= phoneBreakpoint) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(12);
    }
  }

  /// Get appropriate minimum touch target size
  static double getTouchTargetSize(BuildContext context) {
    return isTablet(context) ? 48.0 : 44.0;
  }

  /// Get appropriate icon size
  static double getIconSize(BuildContext context) {
    return isTablet(context) ? 24.0 : 20.0;
  }

  /// Get appropriate border radius
  static double getBorderRadius(BuildContext context) {
    return isTablet(context) ? 12.0 : 8.0;
  }
}

/// Widget that provides adaptive layout capabilities
class AdaptiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isTablet, bool isDesktop)
  builder;

  const AdaptiveLayoutBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final isTablet = AdaptiveLayout.isTablet(context);
    final isDesktop = AdaptiveLayout.isDesktop(context);

    return builder(context, isTablet, isDesktop);
  }
}

/// Extension to easily get adaptive values from BuildContext
extension AdaptiveLayoutExtension on BuildContext {
  bool get isTablet => AdaptiveLayout.isTablet(this);
  bool get isDesktop => AdaptiveLayout.isDesktop(this);
  double get screenWidth => AdaptiveLayout.screenWidth(this);
  double get screenHeight => AdaptiveLayout.screenHeight(this);
  EdgeInsets get screenPadding => AdaptiveLayout.getScreenPadding(this);
  double get touchTargetSize => AdaptiveLayout.getTouchTargetSize(this);
  double get iconSize => AdaptiveLayout.getIconSize(this);
  double get borderRadius => AdaptiveLayout.getBorderRadius(this);
}
