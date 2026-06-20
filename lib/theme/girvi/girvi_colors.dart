// =============================================================================
// FILE        : girvi_colors.dart
// MODULE      : Girvi / Pawn
// LAYER       : Theme / Colors
// =============================================================================

import 'package:flutter/material.dart';

class GirviColors {
  GirviColors._();

  // ── BRAND ─────────────────────────────────────────────────────────────────
  static const Color brandGold = Color(0xFFD4AF37);
  static const Color brandGoldLight = Color(0x1AD4AF37);
  static const Color brandGoldGlow = Color(0x40D4AF37);
  static const Color brandDeep = Color(0xFF8B6914);
  static const Color goldGradientStart =
      Color(0xFFFFD700); // Premium Gradient Start

  // ── STATUS ────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0x1A10B981);
  static const Color successBorder = Color(0x3310B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0x1AF59E0B);
  static const Color warningBorder = Color(0x33F59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0x1AEF4444);
  static const Color dangerBorder = Color(0x33EF4444);
  static const Color onlineGreen = Color(0xFF00E676);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0x1A3B82F6);
  static const Color purple = Color(0xFF9C6FDE);
  static const Color purpleBg = Color(0x1A9C6FDE);

  // ── DARK SHELL (App Bar) ──────────────────────────────────────────────────
  static const Color shellBg = Color(0xFF111827);
  static const Color shellPanelBg = Color(0xFF1F2937);
  static const Color shellBorder = Color(0xFF374151);
  static const Color shellTextTitle = Color(0xFFF9FAFB);
  static const Color shellTextMuted = Color(0xFFD1D5DB);

  // ── LIGHT BODY (Main Content) ─────────────────────────────────────────────
  static const Color bodyBg = Color(0xFFF9F6F0);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE5E0D8);
  static const Color inputBg = Color(0xFFF9FAFB);
  static const Color inputBgLocked = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFEEEBE4);

  // ── TYPOGRAPHY ────────────────────────────────────────────────────────────
  static const Color textDark = Color(0xFF111827);
  static const Color textBody = Color(0xFF111827);
  static const Color textMuted = Color(0xFF1F2937);
  static const Color textHint = Color(0xFF374151);

  // ── MODULE BADGE ─────────────────────────────────────────────────────────
  static const Color moduleBadgeBg = Color(0xFF1A2332);
  static const Color moduleBadgeBorder = Color(0x2AFFFFFF);

  // ── SECTION ACCENT COLORS ────────────────────────────────────────────────
  static const Color accentCustomer = Color(0xFF3B82F6); // Blue
  static const Color accentItem = Color(0xFFD4AF37); // Gold
  static const Color accentWeight = Color(0xFFFFD700); // Bright gold
  static const Color accentValuation = Color(0xFF10B981); // Green
  static const Color accentLoan = Color(0xFF9C6FDE); // Purple
  static const Color accentInterest = Color(0xFFF59E0B); // Amber
  static const Color accentDates = Color(0xFF06B6D4); // Cyan
  static const Color accentKyc = Color(0xFFEF4444); // Red
  static const Color accentNotes = Color(0xFF374151); // Slate

  // ── STATUS TAGS ──────────────────────────────────────────────────────────
  static const Color statusActive = Color(0xFF10B981);
  static const Color statusActiveBg = Color(0x1A10B981);
  static const Color statusOverdue = Color(0xFFEF4444);
  static const Color statusOverdueBg = Color(0x1AEF4444);
  static const Color statusReleased = Color(0xFF3B82F6);
  static const Color statusReleasedBg = Color(0x1A3B82F6);
  static const Color statusAuctioned = Color(0xFF374151);
  static const Color statusAucBg = Color(0x1A6B7280);

  // ── EFFECTS ──────────────────────────────────────────────────────────────
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowMedium = Color(0x1A000000);
}
