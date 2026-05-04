// -----------------------------------------------------------------------------
// FILE: add_customer_colors.dart
// MODULE: Customer → Add New Customer
// DESCRIPTION: Centralized color palette. Matches Customer List + POS theme.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class AddCustomerColors {
  AddCustomerColors._();

  // ── SHELL (App Bar - Dark like POS & Customer List) ──────────────────────
  static const Color shellBg = Color(0xFF111827);
  static const Color shellPanelBg = Color(0xFF1F2937);
  static const Color shellBorder = Color(0xFF374151);
  static const Color shellTextTitle = Color(0xFFF9FAFB);
  static const Color shellTextMuted = Color(0xFF9CA3AF);

  // ── BODY (Cream - same as POS & Customer List) ───────────────────────────
  static const Color bodyBg = Color(0xFFF9F6F0);
  static const Color bodyPanelBg = Color(0xFFFFFFFF);
  static const Color bodyBorder = Color(0xFFE8E3DA);
  static const Color bodyTextMain = Color(0xFF1E293B);
  static const Color bodyTextMuted = Color(0xFF64748B);

  // ── BRAND ────────────────────────────────────────────────────────────────
  static const Color brandGold = Color(0xFFD4AF37);
  static const Color goldGradientStart =
      Color(0xFFFFD700); // <-- Added this color for the premium gradient
  static const Color brandGoldLight = Color(0x1AD4AF37);
  static const Color brandGoldBg = Color(0xFFFAF6EC);
  static const Color brandGoldBorder = Color(0x33D4AF37);

  // ── FORM FIELDS ──────────────────────────────────────────────────────────
  static const Color inputBg = Color(0xFFFAFAFA);
  static const Color inputBgFocus = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFE5E7EB);
  static const Color inputBorderFocus = Color(0xFFD4AF37);
  static const Color inputLabel = Color(0xFF374151);
  static const Color inputHint = Color(0xFF9CA3AF);
  static const Color inputText = Color(0xFF111827);

  // ── CUSTOMER TYPE TOGGLE ─────────────────────────────────────────────────
  static const Color regularActiveBg = Color(0xFFEFF6FF);
  static const Color regularActiveText = Color(0xFF1D4ED8);
  static const Color regularActiveBorder = Color(0xFF93C5FD);
  static const Color vipActiveBg = Color(0xFFFFF8E1);
  static const Color vipActiveText = Color(0xFF996B00);
  static const Color vipActiveBorder = Color(0xFFD4AF37);
  static const Color inactiveToggleBg = Color(0xFFF3F4F6);
  static const Color inactiveToggleText = Color(0xFF6B7280);

  // ── STATUS ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color errorLight = Color(0x1AEF4444);
  static const Color onlineGreen = Color(0xFF00E676);

  // ── REQUIRED STAR ────────────────────────────────────────────────────────
  static const Color requiredStar = Color(0xFFEF4444);

  // ── SAVE BUTTON ──────────────────────────────────────────────────────────
  static const Color saveBtnBg = Color(0xFFD4AF37);
  static const Color saveBtnText = Color(0xFF000000);
  static const Color saveBtnDisabled = Color(0xFFE5E0D0);

  // ── SHADOWS ──────────────────────────────────────────────────────────────
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowMedium = Color(0x1A000000);
}
