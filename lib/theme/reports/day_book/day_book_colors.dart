// =============================================================================
// FILE        : day_book_colors.dart
// MODULE      : Reports & Analytics → Day Book
// LAYER       : Theme / Colors
// DESCRIPTION : Master color palette.
//               Dark AppBar (Navy) + Cream body — identical design language
//               as Cash Book, Purchase Entry, Sales POS.
//               Adds Day Book-specific: GST green, Non-GST blue,
//               Metal gold/silver, Anomaly amber.
// =============================================================================

import 'package:flutter/material.dart';

class DayBookColors {
  DayBookColors._();

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color brandGold = Color(0xFFD4AF37);
  static const Color brandGoldLight = Color(0x1AD4AF37);
  static const Color brandGoldGlow = Color(0x33D4AF37);
  static const Color goldGradStart = Color(0xFFFFD700);

  // ── Dark Shell (AppBar) — same as Cash Book / POS ─────────────────────────
  static const Color shellBg = Color(0xFF111827);
  static const Color shellPanel = Color(0xFF1F2937);
  static const Color shellBorder = Color(0xFF374151);
  static const Color shellTitle = Color(0xFFF9FAFB);
  static const Color shellMuted = Color(0xFF9CA3AF);
  static const Color onlineGreen = Color(0xFF00E676);

  // ── Light Body (Cream) — same as Cash Book ────────────────────────────────
  static const Color bodyBg = Color(0xFFF9F6F0);
  static const Color bodyPanel = Color(0xFFFFFFFF);
  static const Color bodyBorder = Color(0xFFE5E0D8);
  static const Color cardHover = Color(0xFFF6F3EC);

  // ── Cash Flow — Inward (Green) ────────────────────────────────────────────
  static const Color cashInAccent = Color(0xFF10B981);
  static const Color cashInBg = Color(0xFFECFDF5);
  static const Color cashInBorder = Color(0xFFD1FAE5);
  static const Color cashInText = Color(0xFF065F46);
  static const Color cashInLight = Color(0xFFA7F3D0);

  // ── Cash Flow — Outward (Red) ─────────────────────────────────────────────
  static const Color cashOutAccent = Color(0xFFEF4444);
  static const Color cashOutBg = Color(0xFFFEF2F2);
  static const Color cashOutBorder = Color(0xFFFEE2E2);
  static const Color cashOutText = Color(0xFF991B1B);
  static const Color cashOutLight = Color(0xFFFCA5A5);

  // ── GST Bill Section (Teal/Emerald) ───────────────────────────────────────
  static const Color gstAccent = Color(0xFF0D9488);
  static const Color gstBg = Color(0xFFF0FDFA);
  static const Color gstBorder = Color(0xFFCCFBF1);
  static const Color gstText = Color(0xFF134E4A);
  static const Color gstBadge = Color(0xFF0F766E);

  // ── Non-GST / Normal Bill Section (Blue) ─────────────────────────────────
  static const Color nonGstAccent = Color(0xFF3B82F6);
  static const Color nonGstBg = Color(0xFFEFF6FF);
  static const Color nonGstBorder = Color(0xFFDBEAFE);
  static const Color nonGstText = Color(0xFF1E3A5F);
  static const Color nonGstBadge = Color(0xFF2563EB);

  // ── Metal Inward (Gold/Amber) ─────────────────────────────────────────────
  static const Color metalInAccent = Color(0xFFD97706);
  static const Color metalInBg = Color(0xFFFFFBEB);
  static const Color metalInBorder = Color(0xFFFDE68A);
  static const Color metalInText = Color(0xFF78350F);

  // ── Metal Outward (Purple/Slate) ──────────────────────────────────────────
  static const Color metalOutAccent = Color(0xFF7C3AED);
  static const Color metalOutBg = Color(0xFFF5F3FF);
  static const Color metalOutBorder = Color(0xFFDDD6FE);
  static const Color metalOutText = Color(0xFF3B0764);

  // ── Payment Mode ─────────────────────────────────────────────────────────
  static const Color cashMode = Color(0xFF10B981);
  static const Color upiMode = Color(0xFF00BCD4);
  static const Color cardMode = Color(0xFF6366F1);
  static const Color bankMode = Color(0xFF3B82F6);

  // ── Anomaly Alert (Amber) ─────────────────────────────────────────────────
  static const Color anomalyBg = Color(0xFFFFFBEB);
  static const Color anomalyBorder = Color(0xFFFCD34D);
  static const Color anomalyText = Color(0xFF78350F);
  static const Color anomalyIcon = Color(0xFFF59E0B);

  // ── Net Balance ───────────────────────────────────────────────────────────
  static const Color netPositiveBg = Color(0xFFECFDF5);
  static const Color netPositiveText = Color(0xFF065F46);
  static const Color netNegativeBg = Color(0xFFFEF2F2);
  static const Color netNegativeText = Color(0xFF991B1B);

  // ── EOD / Settlement ─────────────────────────────────────────────────────
  static const Color eodMatchBg = Color(0xFFECFDF5);
  static const Color eodMatchText = Color(0xFF065F46);
  static const Color eodMismatchBg = Color(0xFFFEF2F2);
  static const Color eodMismatchText = Color(0xFF991B1B);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDark = Color(0xFF0F172A);

  // ── Divider / Border ─────────────────────────────────────────────────────
  static const Color divider = Color(0xFFEEEAE2);
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowMedium = Color(0x1A000000);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}
