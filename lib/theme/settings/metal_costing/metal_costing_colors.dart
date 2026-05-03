// =============================================================================
// FILE        : lib/theme/settings/metal_costing/metal_costing_colors.dart
// MODULE      : Metal Costing Analysis
// LAYER       : Theme / Colors
// DESCRIPTION : Master color palette — mirrors BillingSetupColors exactly.
//               Dark shell AppBar + warm cream body. Amber/Gold accent family.
// =============================================================================

import 'package:flutter/material.dart';

class MetalCostingColors {
  MetalCostingColors._();

  // ── BRAND ─────────────────────────────────────────────────────────────────
  static const Color brandGold = Color(0xFFD4AF37);
  static const Color brandGoldLight = Color(0x1AD4AF37);
  static const Color brandGoldGlow = Color(0x40D4AF37);

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

  // ── DARK SHELL (AppBar) ───────────────────────────────────────────────────
  static const Color shellBg = Color(0xFF111827);
  static const Color shellPanelBg = Color(0xFF1F2937);
  static const Color shellBorder = Color(0xFF374151);
  static const Color shellTextTitle = Color(0xFFF9FAFB);
  static const Color shellTextMuted = Color(0xFF9CA3AF);

  // ── LIGHT BODY ────────────────────────────────────────────────────────────
  static const Color bodyBg = Color(0xFFF9F6F0);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE5E0D8);
  static const Color inputBg = Color(0xFFF9FAFB);
  static const Color divider = Color(0xFFEEEBE4);
  static const Color transparent = Colors.transparent;

  // ── TYPOGRAPHY ────────────────────────────────────────────────────────────
  static const Color textDark = Color(0xFF111827);
  static const Color textBody = Color(0xFF374151);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // ── MODULE BADGE ─────────────────────────────────────────────────────────
  static const Color moduleBadgeBg = Color(0xFF1A2332);
  static const Color moduleBadgeBorder = Color(0x2AFFFFFF);

  // ── SHADOW ────────────────────────────────────────────────────────────────
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowSubtle = Color(0x0A000000);
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color borderLight = Color(0xFFE5E7EB);

  // ══ 🥇 GOLD — Amber ═══════════════════════════════════════════════════════
  static const Color goldBrand = Color(0xFFD97706);
  static const Color goldBrandLight = Color(0x1AD97706);
  static const Color goldBrandBorder = Color(0x33D97706);
  static const Color goldCard = Color(0xFFFAEDDA);

  // ══ 🥈 SILVER — Steel Blue ════════════════════════════════════════════════
  static const Color silverBrand = Color(0xFF64748B);
  static const Color silverBrandLight = Color(0x1A64748B);
  static const Color silverBrandBorder = Color(0x3364748B);
  static const Color silverCard = Color(0xFFEDF2F7);

  // ══ 💎 PLATINUM — Violet ══════════════════════════════════════════════════
  static const Color platinumBrand = Color(0xFF7C3AED);
  static const Color platinumBrandLight = Color(0x1A7C3AED);
  static const Color platinumBrandBorder = Color(0x337C3AED);
  static const Color platinumCard = Color(0xFFF3EFFE);

  // ══ 💠 DIAMOND — Teal ═════════════════════════════════════════════════════
  static const Color diamondBrand = Color(0xFF0891B2);
  static const Color diamondBrandLight = Color(0x1A0891B2);
  static const Color diamondBrandBorder = Color(0x330891B2);
  static const Color diamondCard = Color(0xFFE0F7FA);

  // ── PROFIT / LOSS ─────────────────────────────────────────────────────────
  static const Color profitGreen = Color(0xFF10B981);
  static const Color profitGreenBg = Color(0xFFE1F5EE);
  static const Color profitGreenBorder = Color(0xFF5DCAA5);
  static const Color lossRed = Color(0xFFEF4444);
  static const Color lossRedBg = Color(0xFFFCEBEB);
  static const Color lossRedBorder = Color(0xFFF09595);
  static const Color warnAmberBg = Color(0xFFFFF8E1);
  static const Color warnAmberBorder = Color(0xFFEF9F27);
  static const Color warnAmberText = Color(0xFF633806);
}
