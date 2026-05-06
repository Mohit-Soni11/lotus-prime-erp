// =============================================================================
// FILE        : smart_input_styles.dart
// MODULE      : Shared → Smart Input
// LAYER       : Theme → Styles
// =============================================================================

import 'package:flutter/material.dart';
import 'smart_field_type.dart';
import 'smart_input_colors.dart';

class SmartInputStyles {
  SmartInputStyles._();

  // ── Spell correction tile decoration ─────────────────────────────────────
  static BoxDecoration spellTileDecoration = BoxDecoration(
    color: SmartInputColors.spellTileBg,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: SmartInputColors.spellTileBorder, width: 1),
    boxShadow: const [
      BoxShadow(
        color: Color(0x08000000),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  );

  // ── Chip decoration ───────────────────────────────────────────────────────
  static BoxDecoration chipDecoration = BoxDecoration(
    color: SmartInputColors.chipBg,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: SmartInputColors.chipBorder, width: 1),
  );

  // ── Shimmer pill decoration ───────────────────────────────────────────────
  static BoxDecoration shimmerPill({bool isRound = true}) => BoxDecoration(
        color: SmartInputColors.shimmerBase,
        borderRadius: BorderRadius.circular(isRound ? 20 : 8),
      );

  // ── Text Styles ───────────────────────────────────────────────────────────
  static const TextStyle spellTextStyle = TextStyle(
    fontSize: 13,
    color: SmartInputColors.spellText,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle spellHighlightStyle = TextStyle(
    fontSize: 13,
    color: SmartInputColors.spellHighlight,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle chipLabelStyle = TextStyle(
    fontSize: 11,
    color: SmartInputColors.chipLabelText,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static TextStyle chipTextStyle(SmartFieldType type) => TextStyle(
        fontSize: 13,
        color: SmartInputColors.chipText,
        fontWeight: FontWeight.w500,
        // Devanagari ke liye NotoSansDevanagari font
        fontFamily: type == SmartFieldType.name ? 'NotoSansDevanagari' : null,
      );

  // ── Animation durations ───────────────────────────────────────────────────
  static const Duration animDuration = Duration(milliseconds: 220);
  static const Curve animCurve = Curves.easeOutCubic;
}
