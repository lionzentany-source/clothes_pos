import 'package:flutter/cupertino.dart';

class AppShadows {
  AppShadows._();
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: const Color(0x11000000),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: const Color(0x22000000),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> get strong => [
    BoxShadow(
      color: const Color(0x33000000),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}
