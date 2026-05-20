// -----------------------------------------------------------------------------
// FILE: tax_gst_colors.dart
// TYPE: Theme / Presentation (Step C)
// AUTHOR: Senior System Architect
// DESCRIPTION: Centralized color palette. Includes pre-computed opacity
//              variants to prevent runtime color creation lag in UI.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class TaxGstColors {
  TaxGstColors._(); // Private constructor to prevent instantiation

  // --- Backgrounds ---
  static const Color bgMain = Color(0xFFF8F5F1);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color inputBg = Color(0xFFF9FAFB);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color transparent = Colors.transparent;
  static const Color overlayDark = Colors.black;

  // --- Pre-computed Opacities (Extracted from UI) ---
  // Using final to avoid object recreation during 60-FPS rebuilds
  static final Color overlayDark80 = overlayDark.withValues(alpha: 0.8);
  static final Color overlayDark90 = overlayDark.withValues(alpha: 0.9);
  static final Color overlayDark60 =
      cardBg.withValues(alpha: 0.6); // For Loading Overlay
  static final Color overlayDark03 =
      overlayDark.withValues(alpha: 0.03); // For Shadows

  // --- Branding ---
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color borderLight = Color(0xFFE5E7EB);

  // --- Branding Opacities (Extracted from UI) ---
  static final Color goldAccent10 = goldAccent.withValues(alpha: 0.1);
  static final Color goldAccent30 = goldAccent.withValues(alpha: 0.3);
  static final Color goldAccent40 = goldAccent.withValues(alpha: 0.4);

  // --- Brand Specific (Magic Colors) ---
  static const Color brandGstin = Color(0xFF2563EB); // Deep Blue
  static const Color brandLegal = Color(0xFF7C3AED); // Violet
  static const Color brandBis = Color(0xFFD97706); // Amber

  // --- Text ---
  static const Color textDark = Color(0xFF111827);
  static const Color textBody = Color(0xFF374151);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // --- Actions & States ---
  static const Color btnDanger = Color(0xFFEF4444);
  static const Color iconEdit = Color(0xFF374151);
  static const Color saveBtn = Color(0xFF166534);
  static const Color iconSuccess = Color(0xFF059669);
  static const Color actionBlue = Colors.blueAccent;

  // --- Badges & Status ---
  static const Color statusActiveBg = Color(0xFFDCFCE7);
  static const Color statusActiveText = Color(0xFF166534);
  static final Color statusActiveText30 =
      statusActiveText.withValues(alpha: 0.3); // Extracted from UI Pill

  static const Color badgeRedBg = Color(0xFFFEE2E2);
  static const Color badgeRedText = Color(0xFF991B1B);

  // --- Locks & States ---
  static const Color lockedBg = Color(0xFFF3F4F6); // Soft Grey
  static const Color lockedBorder = Color(0xFFE5E7EB);
  static const Color lockedIcon = Color(0xFF6B7280);

  // --- Documents ---
  static const Color docIconMuted = Color(0xFFD1D5DB);
  static const Color uploadZoneBg = Color(0xFFF9FAFB);
}
