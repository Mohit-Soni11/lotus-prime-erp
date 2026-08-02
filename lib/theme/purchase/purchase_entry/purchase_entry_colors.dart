// =============================================================================
// FILE        : purchase_entry_colors.dart
// MODULE      : Purchase Entry
// LAYER       : Theme
// DESCRIPTION : Master color palette for Purchase Entry module.
//               Matches the existing gold/cream design language.
// =============================================================================

import 'package:flutter/material.dart';

class PurchaseEntryColors {
  PurchaseEntryColors._();

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color brandGold = Color(0xFFD4AF37);
  static const Color brandGoldLight = Color(0x1AD4AF37);
  static const Color goldGradStart = Color(0xFFFFD700);
  static const Color goldHoverDark = Color(0xFFB8860B);

  // ── Metal accent colors ──────────────────────────────────────────────────
  static const Color metalGold = Color(0xFFD4AF37);
  static const Color metalSilver = Color(0xFF64748B);
  static const Color metalPlatinum = Color(0xFF607D8B);
  static const Color metalDiamond = Color(0xFF00BCD4);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color onlineGreen =
      Color(0xFF00E676); // <-- Bright neon green added
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // ── Purchase accent (teal-blue — visually distinct from Sales orange) ───
  static const Color purchaseAccent = Color(0xFF0EA5E9); // Sky blue
  static const Color purchaseAccentLight = Color(0x1A0EA5E9);
  static const Color purchaseAccentMid = Color(0xFF0284C7);

  // ── Dark Shell (AppBar) ──────────────────────────────────────────────────
  static const Color shellBg = Color(0xFF111827);
  static const Color shellPanel = Color(0xFF1F2937);
  static const Color shellBorder = Color(0xFF374151);
  static const Color shellTitle = Color(0xFFF9FAFB);
  static const Color shellMuted = Color(0xFF9CA3AF);

  // ── Badge ────────────────────────────────────────────────────────────────
  static const Color badgeBg = Color(0xFF1A1D24);
  static const Color badgeBorder = Color(0x1AFFFFFF);

  // ── Light body (cream/white — same as Sales POS) ─────────────────────────
  static const Color bodyBg = Color(0xFFF9F6F0); // cream
  static const Color bodyPanel = Color(0xFFFFFFFF); // white card
  static const Color bodyBorder = Color(0xFFE5E0D8);
  static const Color formInputBg = Color(0xFFFAFAFA);
  static const Color cardHoverBg = Color(0xFFF6F3EC);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textMain = Color(0xFF0B1220);
  static const Color textMuted = Color(0xFF111827);
  static const Color textDark = Color(0xFF0B1220);

  // ── Shadows ──────────────────────────────────────────────────────────────
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowDark = Color(0x1A000000);
}
