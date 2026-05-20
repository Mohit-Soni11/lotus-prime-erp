// =============================================================================
// FILE        : cash_register_styles.dart
// MODULE      : Dashboard / Cash Register
// LAYER       : Theme / Styles
// =============================================================================

import 'package:flutter/material.dart';
import 'cash_register_colors.dart';

class CashRegisterStyles {
  // â”€â”€ DIMENSIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const double cardBorderRadius = 20.0;
  static const double blockBorderRadius = 12.0;
  static const double footerRadius = 16.0;
  static const double iconBtnSize = 36.0;

  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);
  static const EdgeInsets blockPadding = EdgeInsets.all(14.0);

  // â”€â”€ CARD DECORATION â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get cardDecoration => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CashRegisterColors.cardBgStart,
            CashRegisterColors.cardBgEnd
          ],
        ),
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 25,
            offset: Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      );

  // â”€â”€ OPENING BALANCE ROW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get openingDecoration => BoxDecoration(
        color: CashRegisterColors.openingBg,
        borderRadius: BorderRadius.circular(blockBorderRadius),
        border: Border.all(color: CashRegisterColors.openingBorder),
      );

  // â”€â”€ RECEIVED / PAID BLOCKS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration receivedDecoration = BoxDecoration(
    color: CashRegisterColors.receivedBg,
    borderRadius: BorderRadius.circular(blockBorderRadius),
    border: Border.all(color: CashRegisterColors.receivedBorder),
  );

  static BoxDecoration paidDecoration = BoxDecoration(
    color: CashRegisterColors.paidBg,
    borderRadius: BorderRadius.circular(blockBorderRadius),
    border: Border.all(color: CashRegisterColors.paidBorder),
  );

  // â”€â”€ REPORT BUTTON â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get reportBtnDecoration => BoxDecoration(
        color: CashRegisterColors.reportIconBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CashRegisterColors.reportIconBorder),
      );

  // â”€â”€ FOOTER (Net Cash) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get footerDecoration => BoxDecoration(
        color: CashRegisterColors.footerBg,
        borderRadius: BorderRadius.circular(footerRadius),
        boxShadow: const [
          BoxShadow(
            color: CashRegisterColors.footerShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      );

  // â”€â”€ TEXT STYLES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const TextStyle headerTitleStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w700,
    color: CashRegisterColors.accentGold,
    letterSpacing: 1.5,
  );

  static const TextStyle headerSubStyle = TextStyle(
    fontSize: 11.0,
    color: CashRegisterColors.textSecondary,
  );

  static const TextStyle openingLabelStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w600,
    color: CashRegisterColors.openingText,
  );

  static const TextStyle openingAmountStyle = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w800,
    color: CashRegisterColors.openingText,
  );

  static const TextStyle blockLabelStyle = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle blockAmountStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle footerLabelStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w700,
    color: CashRegisterColors.footerText,
  );

  static const TextStyle footerSubStyle = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    color: CashRegisterColors.footerText,
  );

  static const TextStyle footerAmountStyle = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w900,
    color: CashRegisterColors.footerText,
    letterSpacing: -0.5,
  );
}
