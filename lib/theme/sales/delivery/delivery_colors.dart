// =============================================================================
// FILE        : delivery_colors.dart
// MODULE      : Sales → Delivery Management
// LAYER       : Theme / Colors
// DESCRIPTION : Color palette — consistent with BookingAdvanceColors.
//               Shell = Dark Navy | Body = Cream/White
// =============================================================================

import 'package:flutter/material.dart';

class DeliveryColors {
  DeliveryColors._();

  // ── BRAND ─────────────────────────────────────────────────────────────────
  static const Color brandGold = Color(0xFFD4AF37);
  static const Color brandGoldLight = Color(0x1AD4AF37);
  static const Color goldGradientStart = Color(0xFFFFD700);
  static const Color goldGradientEnd = Color(0xFFD4AF37);

  // ── SHELL (AppBar) — Dark Navy ─────────────────────────────────────────────
  static const Color shellBg = Color(0xFF111827);
  static const Color shellPanelBg = Color(0xFF1F2937);
  static const Color shellBorder = Color(0xFF374151);
  static const Color shellTextTitle = Color(0xFFF9FAFB);
  static const Color shellTextMuted = Color(0xFF9CA3AF);

  // ── BODY — Cream / White ──────────────────────────────────────────────────
  static const Color bodyBg = Color(0xFFF9F6F0);
  static const Color bodyPanelBg = Color(0xFFFFFFFF);
  static const Color bodyBorder = Color(0xFFE5E0D8);
  static const Color bodyTextMain = Color(0xFF1E293B);
  static const Color bodyTextMuted = Color(0xFF475569);
  static const Color cardHoverBg = Color(0xFFF6F3EC);
  static const Color textDark = Color(0xFF0B1220);

  // ── STATUS PIPELINE COLORS ────────────────────────────────────────────────
  static const Color statusBooked = Color(0xFF6366F1); // Indigo
  static const Color statusBookedBg = Color(0xFFEEF2FF);
  static const Color statusInMaking = Color(0xFFF59E0B); // Amber
  static const Color statusInMakingBg = Color(0xFFFEF3C7);
  static const Color statusReady = Color(0xFF10B981); // Emerald
  static const Color statusReadyBg = Color(0xFFD1FAE5);
  static const Color statusDelivered = Color(0xFF3B82F6); // Blue
  static const Color statusDeliveredBg = Color(0xFFDBEAFE);
  static const Color statusCancelled = Color(0xFF6B7280); // Gray
  static const Color statusCancelledBg = Color(0xFFF3F4F6);

  // ── URGENCY COLORS ────────────────────────────────────────────────────────
  static const Color urgencyOverdue = Color(0xFFEF4444); // Red
  static const Color urgencyOverdueBg = Color(0xFFFEE2E2);
  static const Color urgencyToday = Color(0xFFF59E0B); // Amber
  static const Color urgencyTodayBg = Color(0xFFFEF3C7);
  static const Color urgencyTomorrow = Color(0xFF6366F1); // Indigo
  static const Color urgencyTomorrowBg = Color(0xFFEEF2FF);

  // ── PAYMENT STATUS COLORS ─────────────────────────────────────────────────
  static const Color paymentPaid = Color(0xFF10B981);
  static const Color paymentPaidBg = Color(0xFFD1FAE5);
  static const Color paymentPartial = Color(0xFFF59E0B);
  static const Color paymentPartialBg = Color(0xFFFEF3C7);
  static const Color paymentUnpaid = Color(0xFFEF4444);
  static const Color paymentUnpaidBg = Color(0xFFFEE2E2);

  // ── TAB COLORS ────────────────────────────────────────────────────────────
  static const Color tabActive = Color(0xFFD4AF37);
  static const Color tabInactive = Color(0xFF9CA3AF);
  static const Color tabBadgeBg = Color(0xFFEF4444);

  // ── ACTION COLORS ─────────────────────────────────────────────────────────
  static const Color actionDeliver = Color(0xFF10B981);
  static const Color actionInMaking = Color(0xFFF59E0B);
  static const Color actionReady = Color(0xFF6366F1);
  static const Color actionCancel = Color(0xFFEF4444);
  static const Color actionWhatsApp = Color(0xFF25D366);

  // ── ONLINE INDICATOR ─────────────────────────────────────────────────────
  static const Color onlineGreen = Color(0xFF00E676);

  // ── SHADOWS ───────────────────────────────────────────────────────────────
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowDark = Color(0x1A000000);
}
