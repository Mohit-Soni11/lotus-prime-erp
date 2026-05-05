// =============================================================================
// FILE        : inventory_colors.dart
// MODULE      : Stock & Inventory
// LAYER       : Theme / Colors
// DESCRIPTION : Color palette for Inventory Ledger screen.
// =============================================================================

import 'package:flutter/material.dart';

class InvColors {
  InvColors._();

  // ── BRAND ─────────────────────────────────────────────────────
  static const Color brandGold = Color(0xFFD4AF37);
  static const Color brandGoldLight = Color(0x1AD4AF37);
  static const Color brandGoldGlow = Color(0x40D4AF37);
  static const Color goldGradientStart =
      Color(0xFFFFD700); // Premium Gradient Start

  // ── STATUS ────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0x1210B981);
  static const Color successBorder = Color(0x3310B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0x14F59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0x14EF4444);
  static const Color onlineGreen = Color(0xFF00E676);

  // ── DARK SHELL (App Bar) ──────────────────────────────────────
  static const Color shellBg = Color(0xFF111827);
  static const Color shellPanelBg = Color(0xFF1F2937);
  static const Color shellBorder = Color(0xFF374151);
  static const Color shellTextTitle = Color(0xFFF9FAFB);
  static const Color shellTextMuted = Color(0xFF9CA3AF);

  // ── LIGHT BODY ────────────────────────────────────────────────
  static const Color bodyBg = Color(0xFFF9F6F0);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE5E0D8);
  static const Color divider = Color(0xFFEEEBE4);

  // ── TYPOGRAPHY ───────────────────────────────────────────────
  static const Color textDark = Color(0xFF111827);
  static const Color textBody = Color(0xFF374151);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // ── MODULE BADGE ─────────────────────────────────────────────
  static const Color moduleBadgeBg = Color(0xFF1A2332);
  static const Color moduleBadgeBorder = Color(0x2AFFFFFF);

  // ── SUMMARY CARD ACCENTS ─────────────────────────────────────
  static const Color openingAccent = Color(0xFF6366F1);
  static const Color openingBg = Color(0xFFF0F1FF);
  static const Color openingBorder = Color(0xFFBBBEF9);

  static const Color closingAccent = Color(0xFF10B981);
  static const Color closingBg = Color(0xFFECFDF5);
  static const Color closingBorder = Color(0xFF6EE7B7);

  static const Color metalAccent = Color(0xFFD4AF37);
  static const Color metalBg = Color(0xFFFFFBEB);
  static const Color metalBorder = Color(0xFFFBD86D);

  // ── METAL CHIP COLORS ────────────────────────────────────────
  static const Color goldChipBg = Color(0xFFFEF3C7);
  static const Color goldChipText = Color(0xFF92400E);
  static const Color goldChipBorder = Color(0xFFFBD86D);

  static const Color silverChipBg = Color(0xFFF1F5F9);
  static const Color silverChipText = Color(0xFF334155);
  static const Color silverChipBorder = Color(0xFFCBD5E1);

  static const Color diamondChipBg = Color(0xFFEFF6FF);
  static const Color diamondChipText = Color(0xFF1E40AF);
  static const Color diamondChipBorder = Color(0xFFBFDBFE);

  static const Color platinumChipBg = Color(0xFFF5F3FF);
  static const Color platinumChipText = Color(0xFF4C1D95);
  static const Color platinumChipBorder = Color(0xFFDDD6FE);

  // ── STATUS BADGE COLORS ───────────────────────────────────────
  static const Color statusAvailBg = Color(0xFFECFDF5);
  static const Color statusAvailText = Color(0xFF065F46);
  static const Color statusSoldBg = Color(0xFFFEF2F2);
  static const Color statusSoldText = Color(0xFF991B1B);
  static const Color statusOrderBg = Color(0xFFFFFBEB);
  static const Color statusOrderText = Color(0xFF92400E);
  static const Color statusKarigarBg = Color(0xFFF5F3FF);
  static const Color statusKarigarText = Color(0xFF4C1D95);

  // ── SHADOWS ──────────────────────────────────────────────────
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowMedium = Color(0x1A000000);
}
