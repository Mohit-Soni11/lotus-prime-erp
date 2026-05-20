import 'package:flutter/material.dart';
import 'date_card_colors.dart';

class DateCardStyles {
  // âœ… FIXED: Strict Match with Bill Card
  static const double cardHeight = 150.0;
  static const double borderRadius = 20.0;
  static const EdgeInsets cardPadding =
      EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0);

  static const double iconBoxSize = 40.0;
  static const double iconSize = 20.0;
  static const double iconBoxRadius = 12.0;

  // --- TEXT STYLES ---
  static const TextStyle dayText = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    color: DateCardColors.textDay,
    letterSpacing: 1.2,
    fontFamily: 'Roboto',
  );

  static const TextStyle timeText = TextStyle(
    fontSize: 34.0,
    fontWeight: FontWeight.w800,
    color: DateCardColors.textTime,
    height: 1.0,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle dateText = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: DateCardColors.textDate,
    height: 1.5,
  );

  static BoxDecoration get premiumCardDecoration => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DateCardColors.cardBgStart, DateCardColors.cardBgEnd],
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        boxShadow: const [
          BoxShadow(
              color: Colors.black45,
              blurRadius: 25,
              offset: Offset(0, 15),
              spreadRadius: -5),
          BoxShadow(
              color: DateCardColors.glowColor1,
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, 0)),
        ],
      );

  static BoxDecoration iconBoxDecoration = BoxDecoration(
      color: DateCardColors.iconBoxBg.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(iconBoxRadius),
      border: Border.all(color: DateCardColors.iconBoxBorder),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4))
      ]);
}
