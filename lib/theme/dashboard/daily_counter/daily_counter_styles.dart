// =============================================================================
// FILE        : daily_counter_styles.dart
// MODULE      : Dashboard / Daily Counter Activity
// LAYER       : Theme / Styles
// =============================================================================

import 'package:flutter/material.dart';
import 'daily_counter_colors.dart';

class DailyCounterStyles {

  // ── DIMENSIONS ────────────────────────────────────────────────────────────
  static const double cardBorderRadius  = 20.0;
  static const double groupBorderRadius = 16.0;
  static const double innerBoxRadius    = 12.0;
  static const double iconBoxSize       = 36.0;
  static const double iconSize          = 18.0;
  static const double bigIconSize       = 30.0;

  static const EdgeInsets cardPadding  = EdgeInsets.all(20.0);
  static const EdgeInsets groupPadding = EdgeInsets.all(16.0);
  static const EdgeInsets boxPadding   = EdgeInsets.all(14.0);

  // ── OUTER CARD DECORATION ─────────────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [DailyCounterColors.cardBgStart, DailyCounterColors.cardBgEnd],
    ),
    borderRadius: BorderRadius.circular(cardBorderRadius),
    border: Border.all(color: Colors.white.withOpacity(0.08)),
    boxShadow: const [
      BoxShadow(
        color: Colors.black45,
        blurRadius: 25,
        offset: Offset(0, 15),
        spreadRadius: -5,
      ),
    ],
  );

  // ── GROUP CONTAINER ───────────────────────────────────────────────────────
  static BoxDecoration get groupDecoration => BoxDecoration(
    color: DailyCounterColors.groupBg,
    borderRadius: BorderRadius.circular(groupBorderRadius),
    border: Border.all(color: DailyCounterColors.groupBorder),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ── INNER BOX DECORATION ──────────────────────────────────────────────────
  static BoxDecoration innerBox(Color accent) => BoxDecoration(
    color: accent.withOpacity(0.07),
    borderRadius: BorderRadius.circular(innerBoxRadius),
    border: Border.all(color: accent.withOpacity(0.2)),
  );

  // ── ICON BOX ──────────────────────────────────────────────────────────────
  static BoxDecoration iconBox(Color iconBg, Color accent) => BoxDecoration(
    color: iconBg,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: accent.withOpacity(0.3)),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
    ],
  );

  // ── AMOUNT PILL ───────────────────────────────────────────────────────────
  static BoxDecoration amountPill(Color accent) => BoxDecoration(
    color: DailyCounterColors.amountBoxBg,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: accent.withOpacity(0.25)),
  );

  // ── TEXT STYLES ───────────────────────────────────────────────────────────
  static const TextStyle headerStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w700,
    color: DailyCounterColors.accentGold,
    letterSpacing: 1.5,
  );

  static const TextStyle groupTitleStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: DailyCounterColors.textMuted,
    letterSpacing: 1.0,
  );

  static const TextStyle boxTitleStyle = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w700,
    color: DailyCounterColors.textWhite,
    letterSpacing: 0.3,
  );

  static const TextStyle metalLabelStyle = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w600,
    color: DailyCounterColors.metalLabel,
    letterSpacing: 0.5,
  );

  static const TextStyle metalValueStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w700,
    color: DailyCounterColors.metalValue,
  );

  static const TextStyle metalPiecesStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: DailyCounterColors.textMuted,
  );

  static const TextStyle bigCountStyle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    color: DailyCounterColors.textWhite,
  );

  static const TextStyle subLabelStyle = TextStyle(
    fontSize: 10.5,
    color: DailyCounterColors.textMuted,
  );

  static TextStyle amountStyle(Color accent) => TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w800,
    color: accent,
    letterSpacing: -0.3,
  );

  static const TextStyle dateStyle = TextStyle(
    fontSize: 11.0,
    color: DailyCounterColors.textMuted,
    letterSpacing: 0.3,
  );
}