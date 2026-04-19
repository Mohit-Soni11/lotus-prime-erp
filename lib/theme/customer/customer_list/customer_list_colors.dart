// -----------------------------------------------------------------------------
// FILE: customer_list_colors.dart
// MODULE: Customer → Customer List
// AUTHOR: Senior System Architect
// DESCRIPTION: Centralized color palette for Customer List module.
//              Matches SalesPOS light theme (cream bg + white cards).
// -----------------------------------------------------------------------------
 
import 'package:flutter/material.dart';
 
class CustomerListColors {
  CustomerListColors._();
 
  // ── SHELL (App Bar - Dark like POS) ─────────────────────────────────────
  static const Color shellBg        = Color(0xFF111827); // Deep Navy
  static const Color shellPanelBg   = Color(0xFF1F2937); // Dark Slate
  static const Color shellBorder    = Color(0xFF374151); // Border
  static const Color shellTextTitle = Color(0xFFF9FAFB); // White
  static const Color shellTextMuted = Color(0xFF9CA3AF); // Muted Grey
 
  // ── BODY (Light Cream - same as POS) ────────────────────────────────────
  static const Color bodyBg         = Color(0xFFF9F6F0); // Cream Background
  static const Color bodyPanelBg    = Color(0xFFFFFFFF); // White Cards
  static const Color bodyBorder     = Color(0xFFE8E3DA); // Subtle Border
  static const Color bodyTextMain   = Color(0xFF1E293B); // Dark Text
  static const Color bodyTextMuted  = Color(0xFF64748B); // Muted Text
 
  // ── BRAND ────────────────────────────────────────────────────────────────
  static const Color brandGold      = Color(0xFFD4AF37); // Royal Gold
  static const Color brandGoldLight = Color(0x1AD4AF37); // Gold 10%
  static const Color brandGoldBg    = Color(0xFFFAF6EC); // Gold Tint BG
 
  // ── STATUS ───────────────────────────────────────────────────────────────
  static const Color success        = Color(0xFF10B981); // Green
  static const Color successBg      = Color(0xFFD1FAE5); // Green Tint
  static const Color successText    = Color(0xFF065F46); // Dark Green
  static const Color warning        = Color(0xFFF59E0B); // Amber
  static const Color warningBg      = Color(0xFFFEF3C7); // Amber Tint
  static const Color warningText    = Color(0xFF92400E); // Dark Amber
  static const Color danger         = Color(0xFFEF4444); // Red
  static const Color dangerBg       = Color(0xFFFEE2E2); // Red Tint
  static const Color onlineGreen    = Color(0xFF00E676); // Neon Green
 
  // ── CUSTOMER TYPE BADGES ─────────────────────────────────────────────────
  static const Color vipBadgeBg     = Color(0xFFFFF8E1); // Gold tint
  static const Color vipBadgeText   = Color(0xFF996B00); // Dark Gold
  static const Color vipBadgeBorder = Color(0xFFD4AF37); // Gold border
 
  static const Color regularBadgeBg     = Color(0xFFEFF6FF); // Blue tint
  static const Color regularBadgeText   = Color(0xFF1D4ED8); // Blue
  static const Color regularBadgeBorder = Color(0xFF93C5FD); // Light Blue
 
  // ── SEARCH BAR ───────────────────────────────────────────────────────────
  static const Color searchBg       = Color(0xFFFFFFFF); // White
  static const Color searchBorder   = Color(0xFFE5E7EB); // Grey Border
  static const Color searchFocus    = Color(0xFFD4AF37); // Gold on Focus
 
  // ── FILTER CHIPS ─────────────────────────────────────────────────────────
  static const Color chipActive     = Color(0xFFD4AF37);
  static const Color chipActiveBg   = Color(0xFFFAF6EC);
  static const Color chipInactive   = Color(0xFF6B7280);
  static const Color chipInactiveBg = Color(0xFFF3F4F6);
 
  // ── HOVER ────────────────────────────────────────────────────────────────
  static const Color cardHover      = Color(0xFFF6F3EC); // Cream hover
 
  // ── SHADOWS ──────────────────────────────────────────────────────────────
  static const Color shadowLight    = Color(0x0F000000);
  static const Color shadowMedium   = Color(0x1A000000);
}