// ==========================================
// FILE: sales_pos_colors.dart
// TYPE: Theme Core (UPGRADED)
// AUTHOR: Senior System Architect
// DESCRIPTION: Master color palette, semantic card controls & effects.
//              ✅ 100% extracted hardcoded colors integrated.
// ==========================================

import 'package:flutter/material.dart';

class SalesPosColors {
  SalesPosColors._();

  // --- BRAND & SYSTEM COLORS ---
  static const Color brandGold = Color(0xFFD4AF37);
  static const Color brandGoldLight = Color(0x1AD4AF37);
  static const Color brandSilver = Color(0xFF64748B);

  // 🚀 NEW: Extracted Metal Colors
  static const Color brandPlatinum = Color(0xFF607D8B);
  static const Color brandDiamond = Color(0xFF00BCD4);

  // 🚀 NEW: Extracted Gold Gradients & Accents
  static const Color goldGradientStart = Color(0xFFFFD700);
  static const Color goldGradientEnd = Color(0xFFD4AF37);
  static const Color goldHoverDark = Color(0xFFB8860B);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color onlineIndicator = Color(0xFF00E676);

  // 🚀 NEW: Extracted Action Colors
  static const Color upiButtonBg =
      Color(0xFF00796B); // Extracted from UPI Return Button

  // --- DARK SHELL (App Bar & Global Background) ---
  static const Color shellBg = Color(0xFF111827);
  static const Color shellPanelBg = Color(0xFF1F2937);
  static const Color shellBorder = Color(0xFF374151);
  static const Color shellTextTitle = Color(0xFFF9FAFB);
  static const Color shellTextMuted = Color(0xFF9CA3AF);

  // --- LOGIN BADGE SPECIFIC ---
  static const Color badgeBg = Color(0xFF1A1D24);
  static const Color badgeMenuBg = Color(0xFF0B0F19);
  static const Color badgeBorder = Color(0x1AFFFFFF);
  static const Color badgeDeepShadow =
      Color(0xFF111520); // 🚀 NEW: Extracted from Login Badge depth

  // ==========================================
  // 🌟 EYE-COMFORT THEME (LIGHT BODY)
  // ==========================================

  static const Color bodyBg = Color(0xFFF9F6F0);
  static const Color bodyPanelBg = Color(0xFFFFFFFF);
  static const Color bodyBorder = Color(0xFFE5E0D8);

  // 🚀 NEW: Extracted Form Field Colors
  static const Color formInputBg =
      Color(0xFFFAFAFA); // Extracted from Input TextFields

  static const Color bodyTextMain = Color(0xFF1E293B);
  static const Color bodyTextMuted = Color(0xFF475569);

  // --- ROLE COLORS ---
  static const Color roleOwner = brandGold;
  static const Color roleManager = Color(0xFF9C27B0);
  static const Color roleStaff = Color(0xFF64B5F6);

  static const Color textDark = Color(0xFF000000);

  // --- EFFECTS & OVERLAYS ---
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowDark = Color(0x1A000000);
  static const Color overlayBg = Color(0x80000000);

  // ==========================================
  // SEMANTIC CARD CONTROLS (Future-Proofing)
  // ==========================================
  static const Color topControlBarBg = bodyPanelBg;
  static const Color invoiceStripBg = bodyPanelBg;
  static const Color customerCardBg = bodyPanelBg;
  static const Color itemsTableBg = bodyPanelBg;
  static const Color tradeInTableBg = bodyPanelBg;
  static const Color billingRightPanelBg = bodyPanelBg;

  static const Color cardHoverBg = Color(0xFFF6F3EC);
}
