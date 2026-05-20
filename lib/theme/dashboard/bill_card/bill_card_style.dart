import 'package:flutter/material.dart';
import 'bill_card_colors.dart';

class BillCardStyles {
  // âœ… FIXED: Increased to 150.0 for comfortable fit
  static const double cardHeight = 150.0;
  static const double borderRadius = 20.0;

  // Padding same as DateCard
  static const EdgeInsets cardPadding =
      EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0);

  static const double iconBoxSize = 40.0;
  static const double iconSize = 20.0;
  static const double iconBoxRadius = 12.0;

  // --- TEXT STYLES ---
  static const TextStyle labelStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: BillCardColors.textTitle,
    letterSpacing: 0.8,
    fontFamily: 'Roboto',
  );

  static const TextStyle countStyle = TextStyle(
    fontSize: 40.0,
    fontWeight: FontWeight.w800,
    color: BillCardColors.textCount,
    height: 1.0,
    letterSpacing: -1.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle subStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w700,
    color: BillCardColors.textSub,
  );

  static const TextStyle subLabelStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w500,
    color: Colors.grey,
  );

  // --- PREMIUM DECORATION ---
  static BoxDecoration get premiumCardDecoration => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BillCardColors.cardBgStart, BillCardColors.cardBgEnd],
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
              color: BillCardColors.glowTopRight,
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, 0)),
        ],
      );

  static BoxDecoration iconBoxDecoration = BoxDecoration(
      color: BillCardColors.iconBoxBg.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(iconBoxRadius),
      border: Border.all(color: BillCardColors.iconBoxBorder),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4))
      ]);
}
