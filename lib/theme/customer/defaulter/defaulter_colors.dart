// ==========================================
// FILE: defaulter_colors.dart
// MODULE: Customer → Defaulter List
// DESCRIPTION: Master color palette for Defaulter List screen.
//              Inherits POS shell/body pattern for design consistency.
// ==========================================

import 'package:flutter/material.dart';

class DefaulterColors {
  DefaulterColors._();

  // --- SHELL (App Bar) — Same as POS dark shell ---
  static const Color shellBg = Color(0xFF111827);
  static const Color shellPanelBg = Color(0xFF1F2937);
  static const Color shellBorder = Color(0xFF374151);
  static const Color shellTextTitle = Color(0xFFF9FAFB);
  static const Color shellTextMuted = Color(0xFF9CA3AF);

  // --- ONLINE INDICATOR ---
  static const Color onlineGreen = Color(0xFF00E676);
  static const Color onlinePulse = Color(0x3300E676);

  // --- BODY (Content Area) — Same cream as POS body ---
  static const Color bodyBg = Color(0xFFF9F6F0);
  static const Color bodyPanelBg = Color(0xFFFFFFFF);
  static const Color bodyBorder = Color(0xFFE5E0D8);
  static const Color bodyBorderLight = Color(0xFFF0EDE6);
  static const Color bodyTextMain = Color(0xFF0F172A);
  static const Color bodyTextMuted = Color(0xFF111827);
  static const Color bodyTextHint = Color(0xFF1F2937);

  // --- BRAND (Gold Accents) ---
  static const Color brandGold = Color(0xFFD4AF37);
  static const Color goldGradientStart =
      Color(0xFFFFD700); // <-- Added Premium Gradient Start
  static const Color brandGoldLight = Color(0x1AD4AF37);
  static const Color brandGoldDark = Color(0xFFB8860B);

  // --- RISK LEVEL COLORS (Core purpose of this screen) ---

  // Critical (> 90 days) — Red
  static const Color riskCriticalBg = Color(0xFFFFEBEB);
  static const Color riskCriticalBorder = Color(0xFFFF5252);
  static const Color riskCriticalText = Color(0xFFD32F2F);
  static const Color riskCriticalDot = Color(0xFFFF5252);

  // High (60–90 days) — Orange
  static const Color riskHighBg = Color(0xFFFFF3E0);
  static const Color riskHighBorder = Color(0xFFFF9800);
  static const Color riskHighText = Color(0xFFE65100);
  static const Color riskHighDot = Color(0xFFFF9800);

  // Medium (30–60 days) — Amber/Yellow
  static const Color riskMediumBg = Color(0xFFFFFDE7);
  static const Color riskMediumBorder = Color(0xFFFFC107);
  static const Color riskMediumText = Color(0xFFF57F17);
  static const Color riskMediumDot = Color(0xFFFFC107);

  // Low (< 30 days) — Blue (Informational)
  static const Color riskLowBg = Color(0xFFE3F2FD);
  static const Color riskLowBorder = Color(0xFF42A5F5);
  static const Color riskLowText = Color(0xFF1565C0);
  static const Color riskLowDot = Color(0xFF42A5F5);

  // --- STAT CARDS ---
  static const Color statCardBg = Color(0xFFFFFFFF);
  static const Color statCardBorder = Color(0xFFE5E0D8);

  static const Color statTotalBg = Color(0xFFEEF2FF);
  static const Color statTotalIcon = Color(0xFF3F51B5);
  static const Color statTotalText = Color(0xFF1A237E);

  static const Color statAmountBg = Color(0xFFFFF8E1);
  static const Color statAmountIcon = Color(0xFFF57C00);
  static const Color statAmountText = Color(0xFFE65100);

  static const Color statCriticalBg = Color(0xFFFFEBEE);
  static const Color statCriticalIcon = Color(0xFFE53935);
  static const Color statCriticalText = Color(0xFFB71C1C);

  static const Color statPrincipalBg = Color(0xFFEFF6FF);
  static const Color statPrincipalIcon = Color(0xFF2563EB);
  static const Color statPrincipalText = Color(0xFF1D4ED8);

  static const Color statReceivedBg = Color(0xFFECFDF5);
  static const Color statReceivedIcon = Color(0xFF059669);
  static const Color statReceivedText = Color(0xFF047857);

  // --- ACTION BUTTONS ---
  static const Color callBtnBg = Color(0xFF1B5E20);
  static const Color callBtnText = Color(0xFFFFFFFF);

  static const Color notifyBtnBg = Color(0xFF0D47A1);
  static const Color notifyBtnText = Color(0xFFFFFFFF);

  // --- TABLE ---
  static const Color tableHeaderBg = Color(0xFFF1EDE4);
  static const Color tableRowAlt = Color(0xFFFAF8F4);
  static const Color tableHoverBg = Color(0xFFF6F1E8);
  static const Color tableDivider = Color(0xFFEDE9E0);

  // --- SEARCH BAR ---
  static const Color searchBg = Color(0xFFFFFFFF);
  static const Color searchBorder = Color(0xFFDDD8CF);
  static const Color searchFocusBorder = Color(0xFFD4AF37);

  // --- FILTER CHIPS ---
  static const Color filterChipBg = Color(0xFFEEEEEE);
  static const Color filterChipActive = Color(0xFF1E293B);
  static const Color filterChipActiveText = Color(0xFFFFFFFF);

  // --- EFFECTS ---
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color overlayBg = Color(0x80000000);
}
