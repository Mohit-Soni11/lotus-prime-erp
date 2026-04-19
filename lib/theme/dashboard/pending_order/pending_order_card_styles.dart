import 'package:flutter/material.dart';
import 'dart:ui';
import 'pending_order_card_colors.dart';

class PendingOrderStyles {
  // ✅ Height 150.0 (Matching Others)
  static const double cardHeight = 150.0; 
  static const double borderRadius = 20.0;
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0);

  static const double iconBoxSize = 40.0;
  static const double iconSize = 20.0;
  static const double iconBoxRadius = 12.0;

  // --- Text Styles ---
  static const TextStyle labelStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: PendingOrderColors.textTitle,
    letterSpacing: 0.8,
    fontFamily: 'Roboto',
  );

  static const TextStyle valueStyle = TextStyle(
    fontSize: 40.0,
    fontWeight: FontWeight.w800,
    color: PendingOrderColors.textCount,
    height: 1.0,
    letterSpacing: -1.0,
    fontFeatures: [FontFeature.tabularFigures()], 
  );

  static const TextStyle subtextStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w600,
    color: Colors.white70,
  );

  // --- PREMIUM GLASS DECORATION ---
  static BoxDecoration get premiumCardDecoration => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [PendingOrderColors.cardBgStart, PendingOrderColors.cardBgEnd],
    ),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
    boxShadow: const [
      BoxShadow(color: Colors.black45, blurRadius: 25, offset: Offset(0, 15), spreadRadius: -5),
    ],
  );

  static BoxDecoration iconBoxDecoration = BoxDecoration(
    color: PendingOrderColors.iconBoxBg.withOpacity(0.5),
    borderRadius: BorderRadius.circular(iconBoxRadius),
    border: Border.all(color: PendingOrderColors.iconBoxBorder),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
    ]
  );
}