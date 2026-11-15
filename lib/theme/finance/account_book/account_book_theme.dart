import 'package:flutter/material.dart';

/// Readable finance workspace tokens shared by the monthly Account Book views.
class AccountBookTheme {
  AccountBookTheme._();

  static const ink = Color(0xFF0B1220);
  static const secondaryInk = Color(0xFF243044);
  static const gold = Color(0xFFB6810B);
  static const border = Color(0xFFD6BE87);
  static const surface = Colors.white;
  static const softSurface = Color(0xFFF8F5EC);
  static const selected = Color(0xFFF8E6B6);
  static const income = Color(0xFF087C5F);
  static const expense = Color(0xFFAD342A);
  static const stock = Color(0xFF315EAE);
  static const girvi = Color(0xFF765092);

  static const heading =
      TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink);
  static const label =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink);
  static const detail =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: secondaryInk);
  static const amount =
      TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink);
}
