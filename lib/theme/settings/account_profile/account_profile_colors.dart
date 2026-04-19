// -----------------------------------------------------------------------------
// FILE: lib/theme/settings/account_profile/account_profile_colors.dart
// MODULE: Settings → Account Profile
// DESCRIPTION: Color palette — Dark shell (app bar) + Cream/White body
//              Exact match to CustomerList / SalesPOS style system
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class AccountProfileColors {
  AccountProfileColors._();

  // ── SHELL (App Bar — Dark Navy like Customer List) ────────────────────────
  static const Color shellBg        = Color(0xFF111827);
  static const Color shellPanelBg   = Color(0xFF1F2937);
  static const Color shellBorder    = Color(0xFF374151);
  static const Color shellTextTitle = Color(0xFFF9FAFB);
  static const Color shellTextMuted = Color(0xFF9CA3AF);

  // ── BODY (Cream + White — same as CustomerList) ───────────────────────────
  static const Color bodyBg         = Color(0xFFF9F6F0); // Cream background
  static const Color bodyPanelBg    = Color(0xFFFFFFFF); // White cards
  static const Color bodyBorder     = Color(0xFFE8E3DA); // Subtle warm border
  static const Color bodyTextMain   = Color(0xFF1E293B); // Dark slate text
  static const Color bodyTextMuted  = Color(0xFF64748B); // Muted grey

  // ── BRAND GOLD ────────────────────────────────────────────────────────────
  static const Color brandGold      = Color(0xFFD4AF37);
  static const Color brandGoldLight = Color(0x1AD4AF37); // Gold 10%
  static const Color brandGoldBg    = Color(0xFFFAF6EC); // Gold tint bg
  static const Color brandGoldBorder= Color(0x33D4AF37); // Gold 20%

  // ── STATUS ────────────────────────────────────────────────────────────────
  static const Color success        = Color(0xFF10B981);
  static const Color successBg      = Color(0xFFD1FAE5);
  static const Color successText    = Color(0xFF065F46);
  static const Color danger         = Color(0xFFEF4444);
  static const Color dangerBg       = Color(0xFFFEE2E2);
  static const Color info           = Color(0xFF3B82F6);
  static const Color infoBg         = Color(0xFFEFF6FF);

  // ── ROLE BADGE COLORS ─────────────────────────────────────────────────────
  static const Color ownerBadgeBg     = Color(0xFFFFF8E1);
  static const Color ownerBadgeText   = Color(0xFF996B00);
  static const Color ownerBadgeBorder = Color(0xFFD4AF37);

  static const Color managerBadgeBg     = Color(0xFFEFF6FF);
  static const Color managerBadgeText   = Color(0xFF1D4ED8);
  static const Color managerBadgeBorder = Color(0xFF93C5FD);

  static const Color staffBadgeBg     = Color(0xFFF0FDF4);
  static const Color staffBadgeText   = Color(0xFF166534);
  static const Color staffBadgeBorder = Color(0xFF86EFAC);

  // ── INPUT FIELDS ──────────────────────────────────────────────────────────
  static const Color inputBg        = Color(0xFFFFFFFF);
  static const Color inputBorder    = Color(0xFFE2E8F0);
  static const Color inputFocus     = Color(0xFFD4AF37);
  static const Color inputDisabledBg= Color(0xFFF8F8F8);
  static const Color inputDisabledText = Color(0xFFB0B8C4);

  // ── AVATAR ────────────────────────────────────────────────────────────────
  static const Color avatarBg       = Color(0xFFFAF6EC);
  static const Color avatarBorder   = Color(0xFFD4AF37);
  static const Color avatarInitials = Color(0xFFD4AF37);

  // ── SHADOW ────────────────────────────────────────────────────────────────
  static const Color shadowLight    = Color(0x0F000000);
  static const Color shadowMedium   = Color(0x1A000000);
  static const Color goldGlow       = Color(0x26D4AF37);
}