// =============================================================================
// FILE        : counter_security_colors.dart
// MODULE      : Dashboard / Counter Security Check
// =============================================================================

import 'package:flutter/material.dart';
import '../../../models/dashboard/counter_security_model.dart';

class CounterSecurityColors {
  // ── CARD BACKGROUND ───────────────────────────────────────────────────────
  static const Color cardBgStart = Color(0xFF1F2937);
  static const Color cardBgEnd = Color(0xFF0F172A);

  // ── IDLE STATE — neutral dark ─────────────────────────────────────────────
  static const Color idleBorder = Color(0x14FFFFFF);
  static const Color idleBg = Color(0xFF1C2533);

  // ── LOCKED STATE — amber/gold warm ────────────────────────────────────────
  static const Color lockedBorder = Color(0xFFF59E0B);
  static const Color lockedBg = Color(0xFF2D2008);
  static const Color lockedBadge = Color(0xFFB8860B);

  // ── RESULT — MATCHED (Green) ──────────────────────────────────────────────
  static const Color matchedBg = Color(0xFF0D2B1E);
  static const Color matchedBorder = Color(0xFF10B981);
  static const Color matchedText = Color(0xFF34D399);
  static const Color matchedIcon = Color(0xFF10B981);

  // ── RESULT — MISMATCH (Red) ───────────────────────────────────────────────
  static const Color mismatchBg = Color(0xFF2D1515);
  static const Color mismatchBorder = Color(0xFFEF4444);
  static const Color mismatchText = Color(0xFFFC8181);
  static const Color mismatchIcon = Color(0xFFF59E0B); // Warning amber

  // ── GOLD ACCENT ───────────────────────────────────────────────────────────
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentGoldDark = Color(0xFFB8860B);
  static const Gradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
  );

  // ── METAL CHIPS ───────────────────────────────────────────────────────────
  static const Color goldChipActive = Color(0xFFB8860B);
  static const Color silverChipActive = Color(0xFF757575);
  static const Color platinumChipActive = Color(0xFF546E7A);
  static const Color diamondChipActive = Color(0xFF1565C0);
  static const Color chipInactive = Color(0xFF374151);
  static const Color chipInactiveBorder = Color(0x1AFFFFFF);

  // ── INPUT FIELDS ──────────────────────────────────────────────────────────
  static const Color inputBg = Color(0xFF111827);
  static const Color inputBorder = Color(0x33F59E0B);
  static const Color inputFocus = Color(0xFFF59E0B);
  static const Color inputText = Colors.white;
  static const Color inputHint = Color(0x61FFFFFF);
  static const Color inputLabel = Color(0xFF9CA3AF);

  // ── LOCK BUTTON ───────────────────────────────────────────────────────────
  static const Color lockBtnBg = Color(0xFF1A2238);
  static const Color lockBtnText = Colors.white;

  // ── VERIFY BUTTON ─────────────────────────────────────────────────────────
  static const Color verifyBtnBg = Color(0xFF065F46);
  static const Color verifyBtnText = Colors.white;

  // ── TEXT ──────────────────────────────────────────────────────────────────
  static const Color textWhite = Colors.white;
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textSubtle = Color(0x61FFFFFF);

  // ── METAL COLOR HELPERS ───────────────────────────────────────────────────
  static Color metalActiveColor(SecurityMetal m) {
    switch (m) {
      case SecurityMetal.gold:
        return goldChipActive;
      case SecurityMetal.silver:
        return silverChipActive;
      case SecurityMetal.platinum:
        return platinumChipActive;
      case SecurityMetal.diamond:
        return diamondChipActive;
    }
  }
}
