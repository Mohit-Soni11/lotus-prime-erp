// =============================================================================
// FILE        : expense_colors.dart
// MODULE      : Expense Entry
// LAYER       : Theme
// DESCRIPTION : Master color palette for the Expense Entry module.
//               Dark navy AppBar + Cream body — matches existing design system.
//               Module accent: Deep Orange — distinct from Cash Book (green/red),
//               Purchase (sky blue), and Sales POS (gold).
// =============================================================================

import 'package:flutter/material.dart';

class ExpenseColors {
  ExpenseColors._();

  // ── Brand Gold (shared across all modules) ────────────────────────────────
  static const Color brandGold       = Color(0xFFD4AF37);
  static const Color brandGoldLight  = Color(0x1AD4AF37);
  static const Color brandGoldGlow   = Color(0x33D4AF37);

  // ── Module Accent: Deep Orange ────────────────────────────────────────────
  static const Color moduleAccent      = Color(0xFFF97316); // Orange-500
  static const Color moduleAccentLight = Color(0x1AF97316); // Orange bg tint
  static const Color moduleAccentMid   = Color(0xFFEA580C); // Orange-600
  static const Color moduleAccentDark  = Color(0xFFC2410C); // Orange-700
  static const Color moduleAccentBg    = Color(0xFFFFF7ED); // Orange-50

  // ── Dark Shell (AppBar) — same as all modules ─────────────────────────────
  static const Color shellBg     = Color(0xFF111827); // gray-900
  static const Color shellPanel  = Color(0xFF1F2937); // gray-800
  static const Color shellBorder = Color(0xFF374151); // gray-700
  static const Color shellTitle  = Color(0xFFF9FAFB); // gray-50
  static const Color shellMuted  = Color(0xFF9CA3AF); // gray-400

  // ── Light Body (Cream) ────────────────────────────────────────────────────
  static const Color bodyBg     = Color(0xFFF9F6F0); // Cream
  static const Color bodyPanel  = Color(0xFFFFFFFF); // White card
  static const Color bodyBorder = Color(0xFFE5E0D8);

  // ── Cards & Surfaces ─────────────────────────────────────────────────────
  static const Color cardBg          = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0xFFEEE9E0);
  static const Color cardHoverBg     = Color(0xFFFFF7ED);
  static const Color summaryChipBg   = Color(0xFFF5F0E8);

  // ── Search & Input ────────────────────────────────────────────────────────
  static const Color searchBg     = Color(0xFFF5F0E8);
  static const Color searchBorder = Color(0xFFE5E0D8);
  static const Color formInputBg  = Color(0xFFFAFAFA);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger  = Color(0xFFEF4444);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted     = Color(0xFF94A3B8);
  static const Color textDark      = Color(0xFF0F172A);

  // ── Void / Cancelled ─────────────────────────────────────────────────────
  static const Color voidedBg   = Color(0xFFFEF2F2);
  static const Color voidedText = Color(0xFF9CA3AF);

  // ── Amount badge (large total in left panel) ──────────────────────────────
  static const Color amountBadgeBg   = Color(0xFFFFF7ED);
  static const Color amountBadgeText = Color(0xFFC2410C);

  // ── Divider ───────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFEEEAE2);

  // ── Shadow ───────────────────────────────────────────────────────────────
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowDark  = Color(0x1A000000);
}
