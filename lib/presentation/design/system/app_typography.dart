import 'package:flutter/cupertino.dart';

class AppTypography {
  AppTypography._();
  // Prefer Noto for Arabic if available, then Apple Arabic, then SF Pro.
  static const List<String> _fontFallback = <String>[
    'Noto Naskh Arabic',
    'خط ابل العربي',
    'SF Pro',
  ];

  // Font sizes scale
  static const double fs10 = 10; // micro (legacy usages folded into scale)
  static const double fs11 = 11; // small caption (legacy interim)
  static const double fs12 = 12;
  static const double fs13 = 13;
  static const double fs14 = 14;
  static const double fs15 = 15; // comfortable body on tablet
  static const double fs16 = 16; // legacy token used across codebase
  // Slightly increase default body for better legibility on tablets
  static const double fs17 = 17;
  static const double fs18 = 18; // keep duplicate for flexibility
  static const double fs20 = 20; // nav title on tablet
  static const double fs22 = 22; // legacy large title
  static const double fs28 = 28; // large screen/large title

  // Ensure consistent inherit:true to prevent lerp assertion differences.
  static TextStyle get h1 => const TextStyle(
    inherit: false,
    fontSize: fs28,
    fontWeight: FontWeight.w600,
    color: Color(0xFF000000),
    fontFamilyFallback: _fontFallback,
  );
  static TextStyle get h2 => const TextStyle(
    inherit: false,
    fontSize: fs20,
    fontWeight: FontWeight.w600,
    color: Color(0xFF000000),
    fontFamilyFallback: _fontFallback,
  );
  static TextStyle get h3 => const TextStyle(
    inherit: false,
    fontSize: fs18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF000000),
    fontFamilyFallback: _fontFallback,
  );
  static TextStyle get body => const TextStyle(
    inherit: false,
    fontSize: fs18,
    color: Color(0xFF000000),
    fontFamilyFallback: _fontFallback,
  );
  static TextStyle get bodyStrong => const TextStyle(
    inherit: false,
    fontSize: fs16,
    fontWeight: FontWeight.w600,
    color: Color(0xFF000000),
    fontFamilyFallback: _fontFallback,
  );
  static TextStyle get caption => const TextStyle(
    inherit: false,
    fontSize: fs13,
    color: Color(0xFF000000),
    fontFamilyFallback: _fontFallback,
  );
  static TextStyle get small => const TextStyle(
    inherit: false,
    fontSize: fs12,
    color: Color(0xFF000000),
    fontFamilyFallback: _fontFallback,
  );
  static TextStyle get micro => const TextStyle(
    inherit: false,
    fontSize: fs10,
    color: Color(0xFF000000),
    fontFamilyFallback: _fontFallback,
  );
}
