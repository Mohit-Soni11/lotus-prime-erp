// =============================================================================
// FILE        : silver_stock_colors.dart
// MODULE      : Stock & Inventory (Silver)
// LAYER       : Theme / Colors
// DESCRIPTION : Isolated color palette for Silver Add Stock.
//               Full parity with AddStockColors (Gold) — Silver tones only.
//               Zero conflict with Gold, Diamond, Platinum modules.
// =============================================================================

import 'package:flutter/material.dart';

class SilverStockColors {
  SilverStockColors._();

  // ── BRAND SILVER ─────────────────────────────────────────────
  static const Color brandSilver = Color(0xFF8BA1AF); // Main silver accent
  static const Color brandSilverLight = Color(0x1A8BA1AF); // 10% silver tint
  static const Color brandSilverGlow = Color(0x408BA1AF); // 25% silver glow
  static const Color silverAccent = Color(0xFF586E7C); // Darker silver
  static const Color silverSurfaceBg =
      Color(0xFFF8FAFC); // Very light silver surface
  static const Color gradientStart = Color(0xFFD4DDE3); // Gradient highlight

  // ── BRAND BG & BORDER (Selected / Highlighted states) ────────
  static const Color brandSilverBg = Color(0xFFF4F7F9); // Silver-tinted bg
  static const Color brandSilverBorder = Color(0xFFCBD5E1); // Silver border

  // ── STATUS ───────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0x1A10B981);
  static const Color successBorder = Color(0x3310B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0x1AF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0x1AEF4444);
  static const Color onlineGreen = Color(0xFF00E676);

  // ── DARK SHELL (App Bar) ──────────────────────────────────────
  static const Color shellBg = Color(0xFF111827);
  static const Color shellPanelBg = Color(0xFF1F2937);
  static const Color shellBorder = Color(0xFF374151);
  static const Color shellTextTitle = Color(0xFFF9FAFB);
  static const Color shellTextMuted = Color(0xFF9CA3AF);

  // ── LIGHT BODY (Main Content) ─────────────────────────────────
  static const Color bodyBg = Color(0xFFF4F7F9); // Cool blue-grey — Silver feel
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color cardHoverBg = Color(0xFFF1F5F9);
  static const Color inputBg = Color(0xFFF8FAFC);
  static const Color inputBgLocked = Color(0xFFF1F5F9);
  static const Color panelBg = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);

  // ── TYPOGRAPHY ───────────────────────────────────────────────
  static const Color textDark = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textBlack = Color(0xFF000000);

  // ── MODULE BADGE (header right side) ─────────────────────────
  static const Color moduleBadgeBg = Color(0xFF1A2332);
  static const Color moduleBadgeBorder = Color(0x2AFFFFFF);
  static const Color moduleBadgeText = Color(0xFF8BA1AF); // Silver tone

  // ── SECTION ACCENT COLORS ────────────────────────────────────
  static const Color accentBasicInfo = Color(0xFF8BA1AF); // Silver — identity
  static const Color accentMetal = Color(0xFF64748B); // Steel — metal weight
  static const Color accentStone = Color(0xFF00BCD4); // Cyan — gemstone
  static const Color accentPricing = Color(0xFF10B981); // Green — money/price
  static const Color accentCompliance = Color(0xFFF59E0B); // Amber — legal/GST
  static const Color accentInventory = Color(0xFF9C6FDE); // Purple — warehouse

  // ── EFFECTS ──────────────────────────────────────────────────
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color activeToggleBg = Color(0xFFE2E8F0);

  // ── SILVER SHIMMER (for App Bar coin badge) ───────────────────
  static const Color shimmerBase = Color(0xFFCBD5E1);
  static const Color shimmerHighlight = Color(0xFFFFFFFF);
  static const Color silverOrbShadow = Color(0x408BA1AF);
}
