// ============================================================
// FILE    : lib/theme/settings/tax_gst/tax_gst_colors.dart
// MODULE  : Tax & GST Configuration
// AUTHOR  : Lotus Prime ERP
// VERSION : 1.0.0
// ============================================================

import 'package:flutter/material.dart';

/// Master color palette for the Tax & GST Settings module.
/// Dark shell AppBar + warm cream body — identical shell to
/// BillingSetup & MetalCosting modules for visual consistency.
abstract final class TaxGstColors {
  TaxGstColors._();

  // ── Brand Gold ─────────────────────────────────────────────
  static const Color brandGold = Color(0xFFD4AF37);
  static const Color brandGoldLight = Color(0x1AD4AF37);
  static const Color brandGoldGlow = Color(0x40D4AF37);

  // ── Module Accent — GST Green ───────────────────────────────
  static const Color accentPrimary = Color(0xFF16A34A);
  static const Color accentPrimaryLight = Color(0x1A16A34A);
  static const Color accentPrimaryBorder = Color(0x4016A34A);
  static const Color accentPrimaryGlow = Color(0x2516A34A);

  // ── Status Palette ──────────────────────────────────────────
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusSuccessBg = Color(0x1A10B981);
  static const Color statusSuccessBorder = Color(0x3310B981);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusWarningBg = Color(0x1AF59E0B);
  static const Color statusWarningBorder = Color(0x33F59E0B);
  static const Color statusDanger = Color(0xFFEF4444);
  static const Color statusDangerBg = Color(0x1AEF4444);
  static const Color statusDangerBorder = Color(0x33EF4444);
  static const Color statusInfo = Color(0xFF3B82F6);
  static const Color statusInfoBg = Color(0x1A3B82F6);
  static const Color statusInfoBorder = Color(0x333B82F6);
  static const Color onlinePulse = Color(0xFF00E676);

  // ── Shell (AppBar) — Dark ───────────────────────────────────
  static const Color shellBackground = Color(0xFF111827);
  static const Color shellSurface = Color(0xFF1F2937);
  static const Color shellBorder = Color(0xFF374151);
  static const Color shellTitleText = Color(0xFFF9FAFB);
  static const Color shellSubtitleText = Color(0xFF9CA3AF);
  static const Color shellDivider = Color(0xFF2D3748);
  static const Color shellBackBtn = Color(0xFF6B7280);
  static const Color shellBackBtnHover = Color(0xFF16A34A);
  static const Color shellBackBtnHoverBg = Color(0x1A16A34A);
  static const Color shellBadgeBg = Color(0xFF1A2332);
  static const Color shellBadgeBorder = Color(0x2AFFFFFF);
  static const Color shellBadgeText = Color(0xFF9CA3AF);

  // ── Body — Warm Cream Light ─────────────────────────────────
  static const Color bodyBackground = Color(0xFFF9F6F0);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE5E0D8);
  static const Color cardBorderHovered = Color(0xFFD4C9B8);
  static const Color inputSurface = Color(0xFFF9FAFB);
  static const Color inputSurfaceLocked = Color(0xFFF3F4F6);
  static const Color inputBorder = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFEEEBE4);
  static const Color sectionSeparator = Color(0xFFF3EFE8);

  // ── Typography ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF374151);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color textHint = Color(0xFFBBC0C8);

  // ── Buttons ─────────────────────────────────────────────────
  static const Color btnSave = Color(0xFF166534);
  static const Color btnSaveText = Color(0xFFFFFFFF);
  static const Color btnEdit = Color(0xFF1D4ED8);
  static const Color btnCancel = Color(0xFF6B7280);
  static const Color btnDelete = Color(0xFFEF4444);

  // ── Section Accent Colors (7 Cards) ────────────────────────

  /// Card 1 — GST Registration (Green)
  static const Color card01Accent = Color(0xFF16A34A);
  static const Color card01Light = Color(0xFFDCFCE7);
  static const Color card01Border = Color(0xFFA7F3D0);
  static const Color card01IconBg = Color(0xFFDCFCE7);
  static const Color card01Glow = Color(0x2016A34A);

  /// Card 2 — GST Slabs (Sky Blue)
  static const Color card02Accent = Color(0xFF0284C7);
  static const Color card02Light = Color(0xFFE0F2FE);
  static const Color card02Border = Color(0xFF7DD3FC);
  static const Color card02IconBg = Color(0xFFE0F2FE);
  static const Color card02Glow = Color(0x200284C7);

  /// Card 3 — HSN Codes (Amber)
  static const Color card03Accent = Color(0xFFD97706);
  static const Color card03Light = Color(0xFFFEF3C7);
  static const Color card03Border = Color(0xFFFCD34D);
  static const Color card03IconBg = Color(0xFFFEF3C7);
  static const Color card03Glow = Color(0x20D97706);

  /// Card 4 — Tax Preferences (Violet)
  static const Color card04Accent = Color(0xFF7C3AED);
  static const Color card04Light = Color(0xFFEDE9FE);
  static const Color card04Border = Color(0xFFC4B5FD);
  static const Color card04IconBg = Color(0xFFEDE9FE);
  static const Color card04Glow = Color(0x207C3AED);

  /// Card 5 — TCS/TDS (Red)
  static const Color card05Accent = Color(0xFFDC2626);
  static const Color card05Light = Color(0xFFFEE2E2);
  static const Color card05Border = Color(0xFFFCA5A5);
  static const Color card05IconBg = Color(0xFFFEE2E2);
  static const Color card05Glow = Color(0x20DC2626);

  /// Card 6 — E-Invoice (Cyan)
  static const Color card06Accent = Color(0xFF0891B2);
  static const Color card06Light = Color(0xFFCFFAFE);
  static const Color card06Border = Color(0xFF67E8F9);
  static const Color card06IconBg = Color(0xFFCFFAFE);
  static const Color card06Glow = Color(0x200891B2);

  /// Card 7 — BIS Hallmarking (Dark Gold)
  static const Color card07Accent = Color(0xFFB45309);
  static const Color card07Light = Color(0xFFFEF3C7);
  static const Color card07Border = Color(0xFFFCD34D);
  static const Color card07IconBg = Color(0xFFFEF3C7);
  static const Color card07Glow = Color(0x20B45309);

  // ── Module Icon Gradient ─────────────────────────────────────
  static const LinearGradient moduleIconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
  );

  // ── Card Shimmer (loading skeleton) ─────────────────────────
  static const Color shimmerBase = Color(0xFFEEEBE4);
  static const Color shimmerHighlight = Color(0xFFFAF8F4);
}
