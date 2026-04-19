// =============================================================================
// FILE        : alert_row_styles.dart
// MODULE      : Dashboard / Alert Row
// LAYER       : Theme / Styles
// =============================================================================

import 'package:flutter/material.dart';
import 'alert_row_colors.dart';
import '../../../models/dashboard/alert_card_model.dart';

class AlertRowStyles {

  // ── DIMENSIONS ────────────────────────────────────────────────────────────
  static const double cardBorderRadius  = 16.0;
  static const double iconCircleSize    = 42.0;
  static const double iconSize          = 19.0;
  static const double arrowBtnSize      = 30.0;
  static const double orbSize           = 7.0;
  static const double severityBarHeight = 3.0;
  static const EdgeInsets contentPad    = EdgeInsets.fromLTRB(15, 14, 15, 14);

  // ── CARD DECORATION — background hamesha dark, sirf border accent se ──────
  static BoxDecoration cardDecoration({
    required Color borderColor,
    required bool isCritical,
    required Color accentColor,
    required double glowOpacity,
  }) {
    return BoxDecoration(
      // ✅ Background hamesha same dark gradient — BillCard jaisa
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AlertRowColors.cardBgStart, AlertRowColors.cardBgEnd],
      ),
      borderRadius: BorderRadius.circular(cardBorderRadius),
      // Border mein thoda accent color — CRITICAL pe zyada visible
      border: Border.all(
        color: borderColor,
        width: isCritical ? 1.5 : 1.0,
      ),
      boxShadow: [
        const BoxShadow(
          color: Colors.black45,
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
        // Subtle accent glow neeche — card ko lift feel deta hai
        BoxShadow(
          color: accentColor.withOpacity(glowOpacity),
          blurRadius: 20,
          spreadRadius: -4,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  // ── ICON CIRCLE ───────────────────────────────────────────────────────────
  static BoxDecoration iconCircle(AlertStatus s) => BoxDecoration(
    shape: BoxShape.circle,
    color: AlertRowColors.accentDimFor(s),
    border: Border.all(
      color: AlertRowColors.accentFor(s).withOpacity(0.3),
    ),
  );

  // ── ARROW BUTTON ─────────────────────────────────────────────────────────
  static BoxDecoration arrowBtn(AlertStatus s) => BoxDecoration(
    shape: BoxShape.circle,
    color: AlertRowColors.accentDimFor(s),
    border: Border.all(
      color: AlertRowColors.accentFor(s).withOpacity(0.4),
    ),
    boxShadow: [
      BoxShadow(
        color: AlertRowColors.accentFor(s).withOpacity(0.18),
        blurRadius: 8,
      ),
    ],
  );

  // ── BADGE (pill) ──────────────────────────────────────────────────────────
  static BoxDecoration badge(AlertStatus s) => BoxDecoration(
    color: AlertRowColors.badgeBgFor(s),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: AlertRowColors.accentFor(s).withOpacity(0.3),
    ),
  );

  // ── TEXT STYLES ───────────────────────────────────────────────────────────
  static const TextStyle titleStyle = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: Color(0x72FFFFFF),
    letterSpacing: 1.3,
  );

  static const TextStyle badgeStyle = TextStyle(
    fontSize: 8.0,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
  );

  // Main value — white text with subtle accent shadow (text color nahi badlega)
  static TextStyle mainValueStyle(AlertStatus s) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AlertRowColors.textWhite,
    letterSpacing: -0.2,
    shadows: [
      Shadow(
        color: AlertRowColors.accentFor(s).withOpacity(0.3),
        blurRadius: 6,
      ),
    ],
  );

  static const TextStyle subTextStyle = TextStyle(
    fontSize: 11.0,
    color: Color(0x61FFFFFF),
    height: 1.35,
  );

  static const TextStyle severityLabelStyle = TextStyle(
    fontSize: 8.5,
    color: Color(0x40FFFFFF),
    letterSpacing: 0.6,
  );
}