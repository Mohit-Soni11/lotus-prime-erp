// =============================================================================
// FILE        : add_stock_colors.dart
// MODULE      : Stock & Inventory
// LAYER       : Theme / Colors
// DESCRIPTION : Master color palette for the Add Stock module.
//               Follows SalesPosColors pattern exactly.
//               Light body + Dark shell — same as POS.
// =============================================================================

import 'package:flutter/material.dart';

class AddStockColors {
  AddStockColors._();

  // ── BRAND ─────────────────────────────────────────────────────
  static const Color brandGold = Color(0xFFD4AF37);
  static const Color brandGoldLight = Color(0x1AD4AF37);
  static const Color brandGoldGlow = Color(0x40D4AF37);
  static const Color goldGradientStart =
      Color(0xFFFFD700); // Premium Gradient Start

  // ✅ NEW: Added for PC 2 UI Compatibility (Selected/Highlighted states)
  static const Color brandGoldBg = Color(0xFFFFFDF5);
  static const Color brandGoldBorder = Color(0xFFFDE68A);

  // ── STATUS ────────────────────────────────────────────────────
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
  static const Color bodyBg = Color(0xFFF9F6F0); // Warm cream — same as POS
  static const Color cardBg = Color(0xFFFFFFFF); // White cards
  static const Color cardBorder = Color(0xFFE5E0D8); // Subtle warm border
  static const Color cardHoverBg = Color(0xFFF6F3EC); // Hover tint
  static const Color inputBg = Color(0xFFF9FAFB); // Input background
  static const Color inputBgLocked = Color(0xFFF3F4F6); // Disabled input

  // ── TYPOGRAPHY ────────────────────────────────────────────────
  static const Color textDark = Color(0xFF0B1220); // Headings
  static const Color textBody = Color(0xFF111827); // Body text
  static const Color textMuted = Color(0xFF111827); // Secondary
  static const Color textHint = Color(0xFF111827); // Placeholders
  static const Color textBlack = Color(0xFF000000);

  // ── MODULE BADGE ─────────────────────────────────────────────
  // Stock & Inventory badge in header (right side)
  static const Color moduleBadgeBg = Color(0xFF1A2332);
  static const Color moduleBadgeBorder = Color(0x2AFFFFFF);
  static const Color moduleBadgeText = Color(0xFFD4AF37);

  // ── SECTION ACCENT COLORS (each section has its own) ─────────
  static const Color accentBasicInfo = Color(0xFFD4AF37); // Gold
  static const Color accentMetal = Color(0xFFFFD700); // Bright Gold
  static const Color accentStone = Color(0xFF00BCD4); // Cyan / Diamond
  static const Color accentPricing = Color(0xFF10B981); // Green / Money
  static const Color accentCompliance = Color(0xFFF59E0B); // Amber / Legal
  static const Color accentInventory = Color(0xFF9C6FDE); // Purple / Warehouse

  // ── EFFECTS ──────────────────────────────────────────────────
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFEEEBE4);
}
