// =============================================================================
// FILE        : daily_counter_colors.dart
// MODULE      : Dashboard / Daily Counter Activity
// LAYER       : Theme / Colors
// =============================================================================

import 'package:flutter/material.dart';

class DailyCounterColors {

  // ── OUTER CARD — same dark as BillCard/ShopCard ────────────────────────────
  static const Color cardBgStart = Color(0xFF1F2937);
  static const Color cardBgEnd   = Color(0xFF0F172A);

  // ── HEADER ────────────────────────────────────────────────────────────────
  static const Color accentGold      = Color(0xFFF59E0B);
  static const Color accentGoldDark  = Color(0xFFB8860B);
  static const Gradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
  );

  // ── GROUP CONTAINER (inner white card) ───────────────────────────────────
  // Dark mein semi-transparent white look
  static const Color groupBg     = Color(0xFF1C2533);
  static const Color groupBorder = Color(0x1AFFFFFF);

  // ── INNER BOXES — har section ka apna accent ─────────────────────────────

  // SOLD (Green) — Metal becha
  static const Color soldAccent   = Color(0xFF10B981); // Emerald
  static const Color soldBg       = Color(0x1810B981); // 10% opacity
  static const Color soldIconBg   = Color(0xFF0D2B1E); // Deep green bg

  // BOUGHT (Red) — Old gold/silver kharida
  static const Color boughtAccent = Color(0xFFEF4444); // Red
  static const Color boughtBg     = Color(0x18EF4444);
  static const Color boughtIconBg = Color(0xFF2D1515);

  // DUE (Blue) — Udhaar
  static const Color dueAccent    = Color(0xFF3B82F6); // Blue
  static const Color dueBg        = Color(0x183B82F6);
  static const Color dueIconBg    = Color(0xFF0F1F3D);

  // GIRVI (Orange) — Loan
  static const Color girviAccent  = Color(0xFFF97316); // Orange
  static const Color girviBg      = Color(0x18F97316);
  static const Color girviIconBg  = Color(0xFF2D1505);

  // ── TEXT ─────────────────────────────────────────────────────────────────
  static const Color textWhite    = Colors.white;
  static const Color textMuted    = Color(0xFF9CA3AF);
  static const Color textSubtle   = Color(0x61FFFFFF);

  // ── METAL ROW ─────────────────────────────────────────────────────────────
  static const Color metalLabel   = Color(0xFF9CA3AF); // muted label
  static const Color metalValue   = Colors.white;      // bold value
  static const Color metalDivider = Color(0x1AFFFFFF); // subtle pipe

  // ── AMOUNT BOX (inner white pill) ─────────────────────────────────────────
  static const Color amountBoxBg  = Color(0xFF0D1117); // deep dark

  // ── SHIMMER ───────────────────────────────────────────────────────────────
  static const Color shimmerBase      = Color(0xFF1F2937);
  static const Color shimmerHighlight = Color(0xFF374151);
}