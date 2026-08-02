// -----------------------------------------------------------------------------
// FILE: branding_colors.dart
// TYPE: Theme Layer / Colors
// AUTHOR: Senior System Architect
// DESCRIPTION: Centralized color palette with pre-calculated opacity states
//              to prevent runtime color calculation in the UI layer.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class BrandingColors {
  // Private constructor
  BrandingColors._();

  // --- Backgrounds ---
  static const Color bgMain = Color(0xFFF8F5F1);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color inputBg = Color(0xFFF9FAFB);
  static const Color inputBgLocked = Color(0xFFF3F4F6);
  static const Color transparent = Colors.transparent;

  // --- Branding ---
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color shadowSubtle = Color(0x0A000000);

  // ðŸš€ UPGRADE: Extracted Hardcoded Opacities from UI
  static Color goldAccentLight = goldAccent.withValues(alpha: 0.1);
  static Color borderLockedState = textHint.withValues(alpha: 0.3);
  static Color borderActiveState = statusActiveText.withValues(alpha: 0.3);

  // --- Text ---
  static const Color textDark = Color(0xFF0B1220);
  static const Color textBody = Color(0xFF111827);
  static const Color textHint = Color(0xFF111827);
  static const Color textMuted = Color(0xFF111827);
  static const Color textWhite = Colors.white;
  static const Color textWhite70 = Colors.white70;

  // --- Actions & States ---
  static const Color btnDanger = Color(0xFFEF4444);
  static const Color iconEdit = Color(0xFF374151);
  static const Color saveBtn = Color(0xFF166534);
  static const Color iconSuccess = Color(0xFF059669);

  // --- Badges ---
  static const Color statusActiveBg = Color(0xFFDCFCE7);
  static const Color statusActiveText = Color(0xFF166534);

  // --- Social Brand Colors ---
  static const Color brandInsta = Color(0xFFE1306C);
  static const Color brandFb = Color(0xFF1877F2);
  static const Color brandYoutube = Color(0xFFFF0000);
  static const Color brandWeb = Color(0xFF2563EB);
  static const Color brandWhatsapp = Color(0xFF25D366);
  static const Color brandEmail = Color(0xFFEA4335);
  static const Color brandPhone = Color(0xFF34A853);
}
