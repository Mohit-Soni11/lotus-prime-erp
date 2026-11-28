import 'package:flutter/material.dart';

abstract final class LuxuryAuthPalette {
  static const navy = Color(0xFF07152D);
  static const ink = Color(0xFF09172E);
  static const mutedInk = Color(0xFF41516C);
  static const ivory = Color(0xFFFFFCF8);
  static const gold = Color(0xFFD9A631);
  static const paleGold = Color(0xFFFFE6A6);
  static const darkGold = Color(0xFFAD7614);
  static const outline = Color(0xFFB9C2CD);

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE1A925), Color(0xFFF9D778), Color(0xFFC48A18)],
    stops: [0, 0.52, 1],
  );
}
