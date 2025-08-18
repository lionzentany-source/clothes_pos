import 'package:flutter/cupertino.dart';

class AppTypography {
  AppTypography._();

  // Font sizes scale
  static const double fs10 = 10; // micro (legacy usages folded into scale)
  static const double fs11 = 11; // small caption (legacy interim)
  static const double fs12 = 12;
  static const double fs14 = 14;
  static const double fs16 = 16;
  static const double fs18 = 18;
  static const double fs22 = 22;

  // Ensure consistent inherit:true to prevent lerp assertion differences.
  static TextStyle get h1 => const TextStyle(
    inherit: false,
    fontSize: fs22,
    fontWeight: FontWeight.w600,
    color: Color(0xFF000000),
  );
  static TextStyle get h2 => const TextStyle(
    inherit: false,
    fontSize: fs18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF000000),
  );
  static TextStyle get h3 => const TextStyle(
    inherit: false,
    fontSize: fs16,
    fontWeight: FontWeight.w600,
    color: Color(0xFF000000),
  );
  static TextStyle get body =>
      const TextStyle(inherit: false, fontSize: fs14, color: Color(0xFF000000));
  static TextStyle get bodyStrong => const TextStyle(
    inherit: false,
    fontSize: fs14,
    fontWeight: FontWeight.w500,
    color: Color(0xFF000000),
  );
  static TextStyle get caption =>
      const TextStyle(inherit: false, fontSize: fs12, color: Color(0xFF000000));
  static TextStyle get small =>
      const TextStyle(inherit: false, fontSize: fs11, color: Color(0xFF000000));
  static TextStyle get micro =>
      const TextStyle(inherit: false, fontSize: fs10, color: Color(0xFF000000));
}
