// -----------------------------------------------------------------------------
// FILE: customer_profile_colors.dart
// MODULE: Customer → Customer Profile
// CHANGE LOG:
//   - Added: Advance Orders color palette
//   - Added: Dues section color palette
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class CustomerProfileColors {
  CustomerProfileColors._();

  // ── SHELL (Dark App Bar) ─────────────────────────────────────────────────
  static const Color shellBg        = Color(0xFF111827);
  static const Color shellPanelBg   = Color(0xFF1F2937);
  static const Color shellBorder    = Color(0xFF374151);
  static const Color shellTextTitle = Color(0xFFF9FAFB);
  static const Color shellTextMuted = Color(0xFF9CA3AF);

  // ── BODY ─────────────────────────────────────────────────────────────────
  static const Color bodyBg         = Color(0xFFF9F6F0);
  static const Color bodyPanelBg    = Color(0xFFFFFFFF);
  static const Color bodyBorder     = Color(0xFFE8E3DA);
  static const Color bodyTextMain   = Color(0xFF1E293B);
  static const Color bodyTextMuted  = Color(0xFF64748B);

  // ── BRAND ────────────────────────────────────────────────────────────────
  static const Color brandGold      = Color(0xFFD4AF37);
  static const Color brandGoldLight = Color(0x1AD4AF37);
  static const Color brandGoldBg    = Color(0xFFFAF6EC);

  // ── CREDIT STATUS ─────────────────────────────────────────────────────────
  static const Color clearBg        = Color(0xFFD1FAE5);
  static const Color clearText      = Color(0xFF065F46);
  static const Color clearBorder    = Color(0xFF6EE7B7);
  static const Color clearIcon      = Color(0xFF10B981);

  static const Color dueBg          = Color(0xFFFEF3C7);
  static const Color dueText        = Color(0xFF92400E);
  static const Color dueBorder      = Color(0xFFFCD34D);
  static const Color dueIcon        = Color(0xFFF59E0B);

  static const Color defaulterBg    = Color(0xFFFEE2E2);
  static const Color defaulterText  = Color(0xFF991B1B);
  static const Color defaulterBorder= Color(0xFFFCA5A5);
  static const Color defaulterIcon  = Color(0xFFEF4444);

  // ── CUSTOMER TYPE ─────────────────────────────────────────────────────────
  static const Color vipBg          = Color(0xFFFFF8E1);
  static const Color vipText        = Color(0xFF996B00);
  static const Color vipBorder      = Color(0xFFD4AF37);
  static const Color regularBg      = Color(0xFFEFF6FF);
  static const Color regularText    = Color(0xFF1D4ED8);
  static const Color regularBorder  = Color(0xFF93C5FD);

  // ── 4 ACTION BUTTONS ──────────────────────────────────────────────────────
  static const Color newSaleBg      = Color(0xFFD4AF37);
  static const Color newSaleText    = Color(0xFF000000);
  static const Color editBg         = Color(0xFFEFF6FF);
  static const Color editText       = Color(0xFF1D4ED8);
  static const Color editBorder     = Color(0xFF93C5FD);
  static const Color historyBg      = Color(0xFFF3E8FF);
  static const Color historyText    = Color(0xFF6D28D9);
  static const Color historyBorder  = Color(0xFFC4B5FD);
  static const Color deleteBg       = Color(0xFFFEE2E2);
  static const Color deleteText     = Color(0xFF991B1B);
  static const Color deleteBorder   = Color(0xFFFCA5A5);

  // ── BILL HISTORY ──────────────────────────────────────────────────────────
  static const Color paidBg         = Color(0xFFD1FAE5);
  static const Color paidText       = Color(0xFF065F46);
  static const Color unpaidBg       = Color(0xFFFEE2E2);
  static const Color unpaidText     = Color(0xFF991B1B);

  // ── CREDIT LIMIT BAR ──────────────────────────────────────────────────────
  static const Color progressTrack  = Color(0xFFE8E3DA);
  static const Color progressSafe   = Color(0xFF10B981);
  static const Color progressWarn   = Color(0xFFF59E0B);
  static const Color progressDanger = Color(0xFFEF4444);

  static const Color onlineGreen    = Color(0xFF00E676);
  static const Color shadowLight    = Color(0x0F000000);
  static const Color divider        = Color(0xFFE8E3DA);

  // ── ADVANCE ORDERS ───────────────────────────────────────────────────────  ✅ NEW
  static const Color advanceBg          = Color(0xFFF0F9FF);
  static const Color advanceBorder      = Color(0xFFBAE6FD);
  static const Color advanceAccent      = Color(0xFF0284C7);
  static const Color advancePendingBg   = Color(0xFFFFF7ED);
  static const Color advancePendingText = Color(0xFFC2410C);
  static const Color advancePendingBdr  = Color(0xFFFED7AA);
  static const Color advanceReadyBg     = Color(0xFFF0FDF4);
  static const Color advanceReadyText   = Color(0xFF166534);
  static const Color advanceReadyBdr    = Color(0xFFBBF7D0);
  static const Color advanceConvertBtn  = Color(0xFF0284C7);
  static const Color advanceConvertText = Color(0xFFFFFFFF);
  static const Color advanceAmountColor = Color(0xFFD4AF37);
  static const Color advanceRemaining   = Color(0xFFEF4444);

  // ── DUES SECTION ─────────────────────────────────────────────────────────  ✅ NEW
  static const Color duesSectionBg      = Color(0xFFFFFBEB);
  static const Color duesSectionBorder  = Color(0xFFFDE68A);
  static const Color duesSectionAccent  = Color(0xFFB45309);
  static const Color dueRowBg           = Color(0xFFFEFCE8);
  static const Color dueRowBorder       = Color(0xFFFCD34D);
  static const Color dueTotalBg         = Color(0xFFFEF3C7);
  static const Color dueTotalText       = Color(0xFF92400E);
  static const Color duesBillNo         = Color(0xFF1E293B);
  static const Color duesAmount         = Color(0xFFDC2626);
  static const Color duesClearedBg      = Color(0xFFD1FAE5);
  static const Color duesClearedText    = Color(0xFF065F46);
}