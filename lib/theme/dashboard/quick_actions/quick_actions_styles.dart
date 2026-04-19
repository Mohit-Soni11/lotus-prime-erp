// =============================================================================
// FILE        : quick_actions_styles.dart
// MODULE      : Dashboard / Quick Actions
// LAYER       : Theme / Styles
// DESCRIPTION : Decorations, paddings, text styles for Quick Actions card.
// =============================================================================

import 'package:flutter/material.dart';
import 'quick_actions_colors.dart';

class QuickActionsStyles {
  // ==========================================
  // DIMENSIONS
  // ==========================================
  static const double borderRadius = 20.0;
  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);
  static const double buttonHeight = 56.0;
  static const double buttonBorderRadius = 14.0;
  static const double iconCircleSize = 34.0;
  static const double iconSize = 18.0;
  static const double buttonSpacing = 12.0;
  static const double rowSpacing = 12.0;

  // ==========================================
  // CARD DECORATION (same gradient as BillCard/ShopCard)
  // ==========================================
  static BoxDecoration get cardDecoration => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            QuickActionsColors.cardBgStart,
            QuickActionsColors.cardBgEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      );

  // ==========================================
  // BUTTON DECORATION — Normal State
  // ==========================================
  static BoxDecoration btnNormal(Color accentColor) => BoxDecoration(
        color: QuickActionsColors.btnBg,
        borderRadius: BorderRadius.circular(buttonBorderRadius),
        border: Border.all(
          color: accentColor.withOpacity(0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: QuickActionsColors.btnShadow,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      );

  // BUTTON DECORATION — Pressed State
  static BoxDecoration btnPressed(Color accentColor) => BoxDecoration(
        color: QuickActionsColors.btnBgPressed,
        borderRadius: BorderRadius.circular(buttonBorderRadius),
        border: Border.all(
          color: accentColor.withOpacity(0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // BUTTON DECORATION — Hover State
  static BoxDecoration btnHover(Color accentColor) => BoxDecoration(
        color: QuickActionsColors.btnBgHover,
        borderRadius: BorderRadius.circular(buttonBorderRadius),
        border: Border.all(
          color: accentColor.withOpacity(0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // Icon circle bg decoration
  static BoxDecoration iconCircle(Color accentColor) => BoxDecoration(
        color: accentColor.withOpacity(0.12),
        shape: BoxShape.circle,
      );

  // ==========================================
  // TEXT STYLES
  // ==========================================
  static const TextStyle headerStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w700,
    color: QuickActionsColors.headerText,
    letterSpacing: 1.5,
    fontFamily: 'Roboto',
  );

  static const TextStyle btnLabelStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w700,
    color: QuickActionsColors.btnText,
    letterSpacing: 0.2,
  );

  static const TextStyle btnLabelPressedStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w800,
    color: QuickActionsColors.btnText,
    letterSpacing: 0.2,
  );
}