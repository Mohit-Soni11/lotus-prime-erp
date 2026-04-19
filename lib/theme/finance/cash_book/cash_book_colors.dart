// =============================================================================
// FILE        : cash_book_colors.dart
// MODULE      : Accounts / Cash Book
// LAYER       : Theme
// DESCRIPTION : Master color palette. Dark AppBar + Cream body — identical
//               design language as Purchase Entry and Sales POS.
// =============================================================================

import 'package:flutter/material.dart';

class CashBookColors {
  CashBookColors._();

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color brandGold      = Color(0xFFD4AF37);
  static const Color brandGoldLight = Color(0x1AD4AF37);
  static const Color brandGoldGlow  = Color(0x33D4AF37);

  // ── Dark Shell (AppBar) ───────────────────────────────────────────────────
  static const Color shellBg     = Color(0xFF111827);
  static const Color shellPanel  = Color(0xFF1F2937);
  static const Color shellBorder = Color(0xFF374151);
  static const Color shellTitle  = Color(0xFFF9FAFB);
  static const Color shellMuted  = Color(0xFF9CA3AF);

  // ── Light Body (Cream) ────────────────────────────────────────────────────
  static const Color bodyBg     = Color(0xFFF9F6F0); // Cream
  static const Color bodyPanel  = Color(0xFFFFFFFF); // White card
  static const Color bodyBorder = Color(0xFFE5E0D8);

  // ── Income (Green) ────────────────────────────────────────────────────────
  static const Color incomeAccent = Color(0xFF10B981);
  static const Color incomeBg     = Color(0xFFECFDF5);
  static const Color incomeBorder = Color(0xFFD1FAE5);
  static const Color incomeText   = Color(0xFF065F46);
  static const Color incomeChip   = Color(0xFF059669);

  // ── Expense (Red) ─────────────────────────────────────────────────────────
  static const Color expenseAccent = Color(0xFFEF4444);
  static const Color expenseBg     = Color(0xFFFEF2F2);
  static const Color expenseBorder = Color(0xFFFEE2E2);
  static const Color expenseText   = Color(0xFF991B1B);
  static const Color expenseChip   = Color(0xFFDC2626);

  // ── Net Balance ───────────────────────────────────────────────────────────
  static const Color netPositiveBg   = Color(0xFFECFDF5);
  static const Color netPositiveText = Color(0xFF065F46);
  static const Color netNegativeBg   = Color(0xFFFEF2F2);
  static const Color netNegativeText = Color(0xFF991B1B);

  // ── Card UI ───────────────────────────────────────────────────────────────
  static const Color cardBg     = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x0F000000);
  static const Color cardBorderLight = Color(0xFFEEE9E0);

  // ── Summary Panel ─────────────────────────────────────────────────────────
  static const Color summaryPanelBg = Color(0xFFFFFFFF);
  static const Color summaryChipBg  = Color(0xFFF5F0E8);

  // ── View Mode Toggle ─────────────────────────────────────────────────────
  static const Color toggleActiveBg   = Color(0xFFD4AF37);
  static const Color toggleActiveText = Color(0xFF111827);
  static const Color toggleInactiveBg = Color(0xFFE8E3D8);
  static const Color toggleInactiveText = Color(0xFF6B7280);

  // ── Search & Filter Bar ───────────────────────────────────────────────────
  static const Color searchBg     = Color(0xFFF5F0E8);
  static const Color searchBorder = Color(0xFFE5E0D8);
  static const Color searchIcon   = Color(0xFF9CA3AF);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted     = Color(0xFF94A3B8);
  static const Color textDark      = Color(0xFF0F172A);

  // ── Auto-generated badge ──────────────────────────────────────────────────
  static const Color autoBadgeBg   = Color(0xFFF0F9FF);
  static const Color autoBadgeText = Color(0xFF0369A1);

  // ── Divider ───────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFEEEAE2);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger  = Color(0xFFEF4444);
}
