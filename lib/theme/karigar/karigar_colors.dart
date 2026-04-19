// =============================================================================
// FILE        : karigar_colors.dart
// MODULE      : Karigar
// LAYER       : Theme / Colors
// DESCRIPTION : Master color palette for the entire Karigar module.
//               Follows AddStockColors / SalesPosColors pattern exactly.
//               Dark shell AppBar + warm cream body background.
// =============================================================================

import 'package:flutter/material.dart';

class KarigarColors {
  KarigarColors._();

  // ── BRAND ─────────────────────────────────────────────────────────────────
  static const Color brandGold      = Color(0xFFD4AF37);
  static const Color brandGoldLight = Color(0x1AD4AF37);
  static const Color brandGoldGlow  = Color(0x40D4AF37);

  // ── STATUS ────────────────────────────────────────────────────────────────
  static const Color success        = Color(0xFF10B981);
  static const Color successBg      = Color(0x1A10B981);
  static const Color successBorder  = Color(0x3310B981);
  static const Color warning        = Color(0xFFF59E0B);
  static const Color warningBg      = Color(0x1AF59E0B);
  static const Color warningBorder  = Color(0x33F59E0B);
  static const Color danger         = Color(0xFFEF4444);
  static const Color dangerBg       = Color(0x1AEF4444);
  static const Color dangerBorder   = Color(0x33EF4444);
  static const Color onlineGreen    = Color(0xFF00E676);
  static const Color info           = Color(0xFF3B82F6);
  static const Color infoBg         = Color(0x1A3B82F6);

  // ── DARK SHELL (App Bar) ──────────────────────────────────────────────────
  static const Color shellBg        = Color(0xFF111827);
  static const Color shellPanelBg   = Color(0xFF1F2937);
  static const Color shellBorder    = Color(0xFF374151);
  static const Color shellTextTitle = Color(0xFFF9FAFB);
  static const Color shellTextMuted = Color(0xFF9CA3AF);

  // ── LIGHT BODY (Main Content) ─────────────────────────────────────────────
  static const Color bodyBg         = Color(0xFFF9F6F0);
  static const Color cardBg         = Color(0xFFFFFFFF);
  static const Color cardBorder     = Color(0xFFE5E0D8);
  static const Color inputBg        = Color(0xFFF9FAFB);
  static const Color inputBgLocked  = Color(0xFFF3F4F6);
  static const Color divider        = Color(0xFFEEEBE4);

  // ── TYPOGRAPHY ────────────────────────────────────────────────────────────
  static const Color textDark       = Color(0xFF111827);
  static const Color textBody       = Color(0xFF374151);
  static const Color textMuted      = Color(0xFF6B7280);
  static const Color textHint       = Color(0xFF9CA3AF);

  // ── MODULE BADGE ─────────────────────────────────────────────────────────
  static const Color moduleBadgeBg     = Color(0xFF1A2332);
  static const Color moduleBadgeBorder = Color(0x2AFFFFFF);

  // ── SECTION ACCENT COLORS ────────────────────────────────────────────────
  static const Color accentKarigar    = Color(0xFFD4AF37);  // Gold — Karigar selection
  static const Color accentIssue      = Color(0xFF3B82F6);  // Blue — Issue details
  static const Color accentMetal      = Color(0xFFFFD700);  // Bright gold — Metal
  static const Color accentDelivery   = Color(0xFF10B981);  // Green — Timeline
  static const Color accentWastage    = Color(0xFFEF4444);  // Red — Wastage analysis
  static const Color accentCharges    = Color(0xFF9C6FDE);  // Purple — Making charges
  static const Color accentPayment    = Color(0xFF10B981);  // Green — Payment
  static const Color accentNotes      = Color(0xFF6B7280);  // Gray — Notes

  // ── JOB STATUS COLORS ────────────────────────────────────────────────────
  static const Color statusPending    = Color(0xFFF59E0B);
  static const Color statusPendingBg  = Color(0x1AF59E0B);
  static const Color statusInProgress = Color(0xFF3B82F6);
  static const Color statusInProgBg   = Color(0x1A3B82F6);
  static const Color statusCompleted  = Color(0xFF10B981);
  static const Color statusCompBg     = Color(0x1A10B981);
  static const Color statusCancelled  = Color(0xFF6B7280);
  static const Color statusCancBg     = Color(0x1A6B7280);
  static const Color statusOverdue    = Color(0xFFEF4444);
  static const Color statusOverdueBg  = Color(0x1AEF4444);

  // ── LEFT PANEL (Hisaab Screen) ────────────────────────────────────────────
  static const Color leftPanelBg      = Color(0xFF1A2235);
  static const Color leftPanelBorder  = Color(0xFF2A3347);
  static const Color selectedRowBg    = Color(0x1AD4AF37);
  static const Color selectedRowBorder = Color(0x33D4AF37);

  // ── EFFECTS ──────────────────────────────────────────────────────────────
  static const Color shadowLight      = Color(0x0F000000);
  static const Color shadowMedium     = Color(0x1A000000);
}
