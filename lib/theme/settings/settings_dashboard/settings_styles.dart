// =============================================================================
// FILE : lib/theme/settings/settings_dashboard/settings_styles.dart
// THEME: Dark Premium
// =============================================================================

import 'package:flutter/material.dart';
import 'settings_colors.dart';

class SettingsStyles {
  // ── Layout ──
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: 32, vertical: 28);
  static const EdgeInsets cardPadding = EdgeInsets.all(22);
  static const double cardRadius = 16.0;

  // ── Header Typography ──
  static const TextStyle headerTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: SettingsColors.textHeading,
    letterSpacing: -0.3,
  );

  static const TextStyle headerSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: SettingsColors.textMuted,
    letterSpacing: 0.2,
  );

  // ── Category Label ──
  static const TextStyle categoryLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
  );

  // ── Card Typography ──
  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: SettingsColors.textTitle,
    letterSpacing: -0.1,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: SettingsColors.textSubtitle,
    height: 1.5,
  );

  // ── Card Decoration (normal) ──
  static BoxDecoration get cardDecoration => BoxDecoration(
        gradient: SettingsColors.cardGradient,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: SettingsColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      );

  // ── Icon Box ──
  static BoxDecoration iconBox(Color accentColor) => BoxDecoration(
        color: accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
      );

  // ── Header Icon Box ──
  static BoxDecoration get headerIconBox => BoxDecoration(
        color: SettingsColors.accentGoldLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SettingsColors.accentGold.withOpacity(0.3),
          width: 1,
        ),
      );

  // ── Options pill ──
  static BoxDecoration get optionsPill => BoxDecoration(
        color: SettingsColors.accentGoldLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SettingsColors.accentGold.withOpacity(0.35),
          width: 1,
        ),
      );
}
