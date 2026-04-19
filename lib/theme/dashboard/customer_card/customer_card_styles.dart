import 'package:flutter/material.dart';
import 'dart:ui';
import 'customer_card_colors.dart';

class NewCustomerStyles {
  // ✅ FIXED: Increased to 150.0 (Matching BillCard)
  static const double cardHeight = 150.0; 
  static const double borderRadius = 20.0;
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0);

  // --- Icon Box ---
  static const double iconBoxSize = 40.0;
  static const double iconSize = 20.0;
  static const double iconBoxRadius = 12.0;

  // --- Text Styles (Matching BillCard) ---
  static const TextStyle labelStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: NewCustomerColors.textTitle, // Muted Grey
    letterSpacing: 0.8,
    fontFamily: 'Roboto',
  );

  static const TextStyle valueStyle = TextStyle(
    fontSize: 40.0, // ✅ Big Size 40 (Same as Invoice)
    fontWeight: FontWeight.w800,
    color: NewCustomerColors.textCount,
    height: 1.0,
    letterSpacing: -1.0,
    fontFeatures: [FontFeature.tabularFigures()], 
  );

  static const TextStyle subtextStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w600,
  );

  // --- PREMIUM DECORATION (Identical to BillCard) ---
  static BoxDecoration get premiumCardDecoration => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [NewCustomerColors.cardBgStart, NewCustomerColors.cardBgEnd],
      stops: [0.0, 1.0],
    ),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
    boxShadow: const [
      BoxShadow(color: Colors.black45, blurRadius: 25, offset: Offset(0, 15), spreadRadius: -5),
    ],
  );

  // --- Glass Icon Box Decoration ---
  static BoxDecoration iconBoxDecoration = BoxDecoration(
    color: NewCustomerColors.iconBoxBg.withOpacity(0.5),
    borderRadius: BorderRadius.circular(iconBoxRadius),
    border: Border.all(color: NewCustomerColors.iconBoxBorder),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
    ]
  );
}