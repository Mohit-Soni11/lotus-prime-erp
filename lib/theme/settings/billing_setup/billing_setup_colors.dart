// =============================================================================
// FILE        : lib/theme/settings/billing_setup/billing_setup_colors.dart
// MODULE      : Billing Setup
// LAYER       : Theme / Colors
// DESCRIPTION : Master color palette — mirrors KarigarColors exactly.
//               Dark shell AppBar + warm cream body. 4 accent families.
//               v14 UPDATE: Metal-specific accents added for Sales/Purchase hub.
// =============================================================================

import 'package:flutter/material.dart';

class BillingSetupColors {
  BillingSetupColors._();

  // ── BRAND ─────────────────────────────────────────────────────────────────
  static const Color brandGold = Color(0xFFD4AF37);
  static const Color brandGoldBright = Color(0xFFFFD700);
  static const Color brandGoldLight = Color(0x1AD4AF37);
  static const Color brandGoldGlow = Color(0x40D4AF37);

  // ── STATUS ────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0x1A10B981);
  static const Color successBorder = Color(0x3310B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0x1AF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0x1AEF4444);
  static const Color onlineGreen = Color(0xFF00E676);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0x1A3B82F6);

  // ── DARK SHELL (AppBar) ───────────────────────────────────────────────────
  static const Color shellBg = Color(0xFF111827);
  static const Color shellPanelBg = Color(0xFF1F2937);
  static const Color shellBorder = Color(0xFF374151);
  static const Color shellTextTitle = Color(0xFFF9FAFB);
  static const Color shellTextMuted = Color(0xFF9CA3AF);

  // ── LIGHT BODY ────────────────────────────────────────────────────────────
  static const Color bodyBg = Color(0xFFF9F6F0);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE5E0D8);
  static const Color inputBg = Color(0xFFF9FAFB);
  static const Color inputBgLocked = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFEEEBE4);
  static const Color transparent = Colors.transparent;
  static const Color overlayDark = Color(0xCC000000);

  // ── TYPOGRAPHY ────────────────────────────────────────────────────────────
  static const Color textDark = Color(0xFF111827);
  static const Color textBody = Color(0xFF374151);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // ── MODULE BADGE ─────────────────────────────────────────────────────────
  static const Color moduleBadgeBg = Color(0xFF1A2332);
  static const Color moduleBadgeBorder = Color(0x2AFFFFFF);

  // ── ACTIONS ──────────────────────────────────────────────────────────────
  static const Color saveBtn = Color(0xFF166534);
  static const Color statusActiveBg = Color(0xFFDCFCE7);
  static const Color statusActiveText = Color(0xFF166534);
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color shadowSubtle = Color(0x0A000000);
  static const Color shadowLight = Color(0x0F000000);

  // ══ 💎 SALES — Sky Blue (#0EA5E9) ═════════════════════════════════════════
  static const Color salesBrand = Color(0xFF0EA5E9);
  static const Color salesBrandLight = Color(0x1A0EA5E9);
  static const Color salesBrandBorder = Color(0x330EA5E9);
  static const Color salesInvoice = Color(0xFF0891B2);
  static const Color salesEstimate = Color(0xFF7C3AED);
  static const Color salesPayment = Color(0xFF059669);
  static const Color salesDiscount = Color(0xFFD97706);
  static const Color salesDisplay = Color(0xFF2563EB);
  static const Color salesTerms = Color(0xFF374151);

  // ══ 📦 PURCHASE — Royal Blue (#2563EB) ════════════════════════════════════
  static const Color purchaseBrand = Color(0xFF2563EB);
  static const Color purchaseBrandLight = Color(0x1A2563EB);
  static const Color purchaseBrandBorder = Color(0x332563EB);
  static const Color purInvoice = Color(0xFF2563EB);
  static const Color purPayment = Color(0xFF0EA5E9);
  static const Color purItem = Color(0xFF0891B2);
  static const Color purTerms = Color(0xFF374151);

  // ══ 🔒 GIRVI — Amber (#D97706) ════════════════════════════════════════════
  static const Color girviBrand = Color(0xFFD97706);
  static const Color girviBrandLight = Color(0x1AD97706);
  static const Color girviBrandBorder = Color(0x33D97706);
  static const Color grvVoucher = Color(0xFFD97706);
  static const Color grvInterest = Color(0xFFDC2626);
  static const Color grvNotice = Color(0xFF9333EA);
  static const Color grvTerms = Color(0xFF374151);

  // ══ 🔄 RETURN — Rose Red (#E11D48) ════════════════════════════════════════
  static const Color returnBrand = Color(0xFFE11D48);
  static const Color returnBrandLight = Color(0x1AE11D48);
  static const Color returnBrandBorder = Color(0x33E11D48);
  static const Color retPolicy = Color(0xFFE11D48);
  static const Color retBuyback = Color(0xFFD97706);
  static const Color retTerms = Color(0xFF374151);

  // ══════════════════════════════════════════════════════════════════════════
  // v14 — METAL TYPE ACCENTS (Sales & Purchase Metal Hub)
  // ══════════════════════════════════════════════════════════════════════════

  // 🥇 Gold
  static const Color metalGold = Color(0xFFB8860B);
  static const Color metalGoldLight = Color(0x1AB8860B);
  static const Color metalGoldBg = Color(0xFFFFFBEB);

  // 🥈 Silver
  static const Color metalSilver = Color(0xFF6B7280);
  static const Color metalSilverLight = Color(0x1A6B7280);
  static const Color metalSilverBg = Color(0xFFF9FAFB);

  // 💎 Diamond
  static const Color metalDiamond = Color(0xFF0EA5E9);
  static const Color metalDiamondLight = Color(0x1A0EA5E9);
  static const Color metalDiamondBg = Color(0xFFF0F9FF);

  // ⬜ Platinum
  static const Color metalPlatinum = Color(0xFF7C3AED);
  static const Color metalPlatinumLight = Color(0x1A7C3AED);
  static const Color metalPlatinumBg = Color(0xFFF5F3FF);

  // Helper — returns accent color for a given metal string
  static Color metalAccent(String metal) {
    switch (metal) {
      case 'gold':
        return metalGold;
      case 'silver':
        return metalSilver;
      case 'diamond':
        return metalDiamond;
      case 'platinum':
        return metalPlatinum;
      default:
        return metalSilver;
    }
  }

  static Color metalBg(String metal) {
    switch (metal) {
      case 'gold':
        return metalGoldBg;
      case 'silver':
        return metalSilverBg;
      case 'diamond':
        return metalDiamondBg;
      case 'platinum':
        return metalPlatinumBg;
      default:
        return metalSilverBg;
    }
  }
}
