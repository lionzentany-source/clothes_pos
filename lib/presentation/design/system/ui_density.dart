import 'package:flutter/widgets.dart';

enum UIDensity { compact, regular, comfortable }

class DensityConfig extends InheritedWidget {
  final UIDensity density;
  const DensityConfig({super.key, required this.density, required super.child});

  static UIDensity of(BuildContext context) {
    final inh = context.dependOnInheritedWidgetOfExactType<DensityConfig>();
    return inh?.density ?? UIDensity.regular;
  }

  // Derived sizing helpers
  static double tilePadding(UIDensity d) => switch (d) {
    UIDensity.compact => 6,
    UIDensity.regular => 8,
    UIDensity.comfortable => 12,
  };
  static double productThumb(UIDensity d) => switch (d) {
    UIDensity.compact => 40,
    UIDensity.regular => 48,
    UIDensity.comfortable => 56,
  };
  static double buttonHeight(UIDensity d) => switch (d) {
    UIDensity.compact => 40,
    UIDensity.regular => 44,
    UIDensity.comfortable => 48,
  };
  static double fontScale(UIDensity d) => switch (d) {
    UIDensity.compact => .95,
    UIDensity.regular => 1,
    UIDensity.comfortable => 1.05,
  };

  @override
  bool updateShouldNotify(covariant DensityConfig oldWidget) =>
      oldWidget.density != density;
}
