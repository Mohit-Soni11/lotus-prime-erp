// =============================================================================
// FILE        : bank_book_colors.dart
// MODULE      : Finance & Ledgers / Bank Book
// LAYER       : Theme
// DESCRIPTION : Master color palette. Dark AppBar + Cream body — identical
//               design language as Cash Book, Purchase Entry and Sales POS.
// =============================================================================

import 'package:flutter/material.dart';

class BankBookColors {
  BankBookColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color brandGold      = Color(0xFFD4AF37);
  static const Color brandGoldLight = Color(0x1AD4AF37);
  static const Color brandGoldGlow  = Color(0x33D4AF37);

  // ── Dark Shell (AppBar) ────────────────────────────────────────────────────
  static const Color shellBg     = Color(0xFF111827);
  static const Color shellPanel  = Color(0xFF1F2937);
  static const Color shellBorder = Color(0xFF374151);
  static const Color shellTitle  = Color(0xFFF9FAFB);
  static const Color shellMuted  = Color(0xFF9CA3AF);

  // ── Light Body (Cream) ─────────────────────────────────────────────────────
  static const Color bodyBg     = Color(0xFFF9F6F0);
  static const Color bodyPanel  = Color(0xFFFFFFFF);
  static const Color bodyBorder = Color(0xFFE5E0D8);

  // ── Credit (Green) ─────────────────────────────────────────────────────────
  static const Color creditAccent = Color(0xFF10B981);
  static const Color creditBg     = Color(0xFFECFDF5);
  static const Color creditBorder = Color(0xFFD1FAE5);
  static const Color creditText   = Color(0xFF065F46);
  static const Color creditChip   = Color(0xFF059669);

  // ── Debit (Red) ────────────────────────────────────────────────────────────
  static const Color debitAccent = Color(0xFFEF4444);
  static const Color debitBg     = Color(0xFFFEF2F2);
  static const Color debitBorder = Color(0xFFFEE2E2);
  static const Color debitText   = Color(0xFF991B1B);
  static const Color debitChip   = Color(0xFFDC2626);

  // ── Cheque (Amber) ─────────────────────────────────────────────────────────
  static const Color chequeAccent = Color(0xFFF59E0B);
  static const Color chequeBg     = Color(0xFFFFFBEB);
  static const Color chequeBorder = Color(0xFFFEF3C7);
  static const Color chequeText   = Color(0xFF92400E);

  // ── Cheque Status Colors ───────────────────────────────────────────────────
  static const Color statusIssuedBg    = Color(0xFFFFFBEB);
  static const Color statusIssuedText  = Color(0xFF92400E);
  static const Color statusClearedBg   = Color(0xFFECFDF5);
  static const Color statusClearedText = Color(0xFF065F46);
  static const Color statusBouncedBg   = Color(0xFFFEF2F2);
  static const Color statusBouncedText = Color(0xFF991B1B);

  // ── Net Balance ────────────────────────────────────────────────────────────
  static const Color netPositiveBg   = Color(0xFFECFDF5);
  static const Color netPositiveText = Color(0xFF065F46);
  static const Color netNegativeBg   = Color(0xFFFEF2F2);
  static const Color netNegativeText = Color(0xFF991B1B);

  // ── Card UI ────────────────────────────────────────────────────────────────
  static const Color cardBg          = Color(0xFFFFFFFF);
  static const Color cardShadow      = Color(0x0F000000);
  static const Color cardBorderLight = Color(0xFFEEE9E0);

  // ── Account Card ───────────────────────────────────────────────────────────
  static const Color accountCardBg       = Color(0xFF1F2937);
  static const Color accountCardSelected = Color(0xFF111827);
  static const Color accountCardBorder   = Color(0xFF374151);

  // ── Toggle ─────────────────────────────────────────────────────────────────
  static const Color toggleActiveBg      = Color(0xFFD4AF37);
  static const Color toggleActiveText    = Color(0xFF111827);
  static const Color toggleInactiveBg    = Color(0xFFE8E3D8);
  static const Color toggleInactiveText  = Color(0xFF6B7280);

  // ── Search ─────────────────────────────────────────────────────────────────
  static const Color searchBg     = Color(0xFFF5F0E8);
  static const Color searchBorder = Color(0xFFE5E0D8);
  static const Color searchIcon   = Color(0xFF9CA3AF);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted     = Color(0xFF94A3B8);
  static const Color textDark      = Color(0xFF0F172A);

  // ── Reconciled Badge ───────────────────────────────────────────────────────
  static const Color reconciledBg   = Color(0xFFECFDF5);
  static const Color reconciledText = Color(0xFF059669);
  static const Color pendingBg      = Color(0xFFFFFBEB);
  static const Color pendingText    = Color(0xFFD97706);

  // ── Auto-generated ─────────────────────────────────────────────────────────
  static const Color autoBadgeBg   = Color(0xFFF0F9FF);
  static const Color autoBadgeText = Color(0xFF0369A1);

  // ── Divider ────────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFEEEAE2);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger  = Color(0xFFEF4444);
  static const Color info    = Color(0xFF3B82F6);
}