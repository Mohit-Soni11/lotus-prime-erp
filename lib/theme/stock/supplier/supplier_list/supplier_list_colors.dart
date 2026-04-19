// -----------------------------------------------------------------------------
// FILE: supplier_list_colors.dart
// MODULE: Supplier → Supplier List
// DESCRIPTION: Centralized color palette. Matches Customer List + POS theme.
//              Dark shell + Cream body — consistent across all list screens.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class SupplierListColors {
  SupplierListColors._();

  // ── SHELL (App Bar - Dark like POS & Customer List) ──────────────────────
  static const Color shellBg        = Color(0xFF111827);
  static const Color shellPanelBg   = Color(0xFF1F2937);
  static const Color shellBorder    = Color(0xFF374151);
  static const Color shellTextTitle = Color(0xFFF9FAFB);
  static const Color shellTextMuted = Color(0xFF9CA3AF);

  // ── BODY (Cream - same as Customer List + POS) ───────────────────────────
  static const Color bodyBg         = Color(0xFFF9F6F0);
  static const Color bodyPanelBg    = Color(0xFFFFFFFF);
  static const Color bodyBorder     = Color(0xFFE8E3DA);
  static const Color bodyTextMain   = Color(0xFF1E293B);
  static const Color bodyTextMuted  = Color(0xFF64748B);

  // ── BRAND ────────────────────────────────────────────────────────────────
  static const Color brandGold      = Color(0xFFD4AF37);
  static const Color brandGoldLight = Color(0x1AD4AF37);
  static const Color brandGoldBg    = Color(0xFFFAF6EC);

  // ── SUPPLIER TYPE BADGES ──────────────────────────────────────────────────
  static const Color manufacturerBg     = Color(0xFFFFF8E1);
  static const Color manufacturerText   = Color(0xFF996B00);
  static const Color manufacturerBorder = Color(0xFFD4AF37);

  static const Color wholesalerBg       = Color(0xFFEFF6FF);
  static const Color wholesalerText     = Color(0xFF1D4ED8);
  static const Color wholesalerBorder   = Color(0xFF93C5FD);

  static const Color retailerBg         = Color(0xFFECFDF5);
  static const Color retailerText       = Color(0xFF065F46);
  static const Color retailerBorder     = Color(0xFF6EE7B7);

  static const Color individualBg       = Color(0xFFF5F3FF);
  static const Color individualText     = Color(0xFF5B21B6);
  static const Color individualBorder   = Color(0xFFC4B5FD);

  // ── STATUS ───────────────────────────────────────────────────────────────
  static const Color success        = Color(0xFF10B981);
  static const Color successBg      = Color(0xFFD1FAE5);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color warningBg      = Color(0xFFFEF3C7);
  static const Color danger         = Color(0xFFEF4444);
  static const Color dangerBg       = Color(0xFFFEE2E2);

  // ── SEARCH BAR ───────────────────────────────────────────────────────────
  static const Color searchBg       = Color(0xFFFFFFFF);
  static const Color searchBorder   = Color(0xFFE5E7EB);
  static const Color searchFocus    = Color(0xFFD4AF37);

  // ── FILTER CHIPS ─────────────────────────────────────────────────────────
  static const Color chipActive     = Color(0xFFD4AF37);
  static const Color chipActiveBg   = Color(0xFFFAF6EC);
  static const Color chipInactive   = Color(0xFF6B7280);
  static const Color chipInactiveBg = Color(0xFFF3F4F6);

  // ── HOVER ────────────────────────────────────────────────────────────────
  static const Color cardHover      = Color(0xFFF6F3EC);

  // ── SHADOWS ──────────────────────────────────────────────────────────────
  static const Color shadowLight    = Color(0x0F000000);
  static const Color shadowMedium   = Color(0x1A000000);
}