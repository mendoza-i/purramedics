import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static List<BoxShadow> colored(Color color, {double opacity = 0.25}) => [
    BoxShadow(
      color: color.withOpacity(opacity),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];
}
