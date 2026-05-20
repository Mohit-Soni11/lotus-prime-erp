// =============================================================================
// FILE        : cash_register_colors.dart
// MODULE      : Dashboard / Cash Register
// LAYER       : Theme / Colors
// =============================================================================

import 'package:flutter/material.dart';

class CashRegisterColors {
  // ── CARD BACKGROUND — same dark as all other cards ────────────────────────
  static const Color cardBgStart = Color(0xFF1F2937);
  static const Color cardBgEnd = Color(0xFF0F172A);

  // ── GOLD ACCENT ───────────────────────────────────────────────────────────
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentGoldBright = Color(0xFFFFD700);
  static const Gradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
  );

  // ── OPENING BALANCE ROW ───────────────────────────────────────────────────
  static const Color openingBg = Color(0xFF374151); // Slate chip
  static const Color openingBorder = Color(0x1AFFFFFF);
  static const Color openingText = Colors.white;
  static const Color openingIcon = Color(0xFFF59E0B);

  // ── RECEIVED BLOCK (Green) ────────────────────────────────────────────────
  static const Color receivedAccent = Color(0xFF10B981);
  static const Color receivedBg = Color(0x1810B981);
  static const Color receivedBorder = Color(0x2510B981);
  static const Color receivedText = Color(0xFF34D399);

  // ── PAID OUT BLOCK (Red) ──────────────────────────────────────────────────
  static const Color paidAccent = Color(0xFFEF4444);
  static const Color paidBg = Color(0x18EF4444);
  static const Color paidBorder = Color(0x25EF4444);
  static const Color paidText = Color(0xFFFC8181);

  // ── NET CASH FOOTER (Gold pill) ───────────────────────────────────────────
  static const Color footerBg = Color(0xFFF59E0B);
  static const Color footerText = Color(0xFF1A2238);
  static const Color footerShadow = Color(0x33000000);

  // ── REPORT ICON BUTTON ────────────────────────────────────────────────────
  static const Color reportIconBg = Color(0x14F59E0B);
  static const Color reportIconBorder = Color(0x25F59E0B);
  static const Color reportIconColor = Color(0xFFF59E0B);

  // ── TEXT ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0x61FFFFFF);

  // ── DIVIDER ───────────────────────────────────────────────────────────────
  static const Color divider = Color(0x14FFFFFF);

  // ── SHIMMER ───────────────────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFF1F2937);
  static const Color shimmerHighlight = Color(0xFF374151);
}
