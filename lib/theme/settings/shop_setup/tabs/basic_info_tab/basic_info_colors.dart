// -----------------------------------------------------------------------------
// FILE: basic_info_colors.dart
// TYPE: Theme / Colors
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';

class BasicInfoColors {
  // --- Backgrounds ---
  static const Color bgMain = Color(0xFFF8F5F1); // Page Background
  static const Color cardBg = Color(0xFFFFFFFF); // Card Surface
  static const Color inputBg = Color(0xFFF9FAFB); // Text Field Background
  static const Color inputBgLocked =
      Color(0xFFF3F4F6); // Locked Field Background (Greyish)

  // --- UTILS & NEW EXTRACTED SURFACES ---
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceBlack = Color(0xFF000000);
  static const Color transparent = Colors.transparent;
  static const Color overlayDark = Color(0xCC000000); // For Dialog Backgrounds

  // --- Common Elements ---
  static const Color goldAccent =
      Color(0xFFD4AF37); // Focus/Active State (Premium Gold)
  static const Color borderLight = Color(0xFFE5E7EB); // Subtle Borders
  static const Color shadowSubtle = Color(0x0A000000); // Soft Shadow for Cards

  // --- Typography (Contrast Optimized) ---
  static const Color textDark = Color(0xFF111827); // Headings (Near Black)
  static const Color textBody = Color(0xFF374151); // Labels (Dark Grey)
  static const Color textHeaderSub =
      Color(0xFF4B5563); // 🚀 UPGRADE: Darker grey for Header visibility
  static const Color textHint = Color(0xFF9CA3AF); // Placeholders
  static const Color textMuted = Color(0xFF6B7280); // Secondary Text
  static const Color textBlack87 = Colors.black87;

  // --- Extracted Greys (For Photo Widget Dialogs) ---
  static const Color bgGrey50 = Color(0xFFF9FAFB);
  static const Color bgGrey100 = Color(0xFFF3F4F6);
  static const Color borderGrey300 = Color(0xFFE0E0E0);
  static const Color textGrey500 = Color(0xFF9E9E9E);
  static const Color textGrey600 = Color(0xFF757575);
  static const Color textGrey700 = Color(0xFF616161);

  // --- Actions & Status ---
  static const Color btnDanger = Color(0xFFEF4444); // Delete/Remove (Red)
  static const Color iconEdit = Color(0xFF374151); // Edit Icon (Dark Grey)
  static const Color saveBtn = Color(0xFF166534); // Save Icon (Forest Green)
  static const Color actionBlue =
      Colors.blueAccent; // 🚀 UPGRADE: Extracted from UI

  static const Color statusActiveBg = Color(0xFFDCFCE7); // Verified Badge Bg
  static const Color statusActiveText =
      Color(0xFF166534); // Verified Badge Text

  static const Color borderWarning = Color(0xFFFCD34D); // Warning Border
  static const Color imgPlaceholderBg =
      Color(0xFFF3F4F6); // Image Upload Placeholder

  // --- PROFESSIONAL CONTEXT COLORS ---
  static const Color iconDefaultSuccess = Color(0xFF059669); // Default Green

  // 1. Enterprise Section
  static const Color brandIdentity = Color(0xFF7C3AED); // 💜 Violet
  static const Color brandPhone = Color(0xFF2563EB); // 💙 Royal Blue
  static const Color brandWhatsapp = Color(0xFF25D366); // 💚 WhatsApp Green
  static const Color brandTime = Color(0xFFD97706); // 🧡 Amber
  static const Color brandLocation = Color(0xFFDC2626); // ❤️ Red

  // 2. Communication Section
  static const Color brandDisplay = Color(0xFF0891B2); // 🩵 Cyan
  static const Color brandEmail = Color(0xFFEA4335); // 🔴 Gmail Red

  // 3. Special
  static const Color signatureInk = Color(0xFF000080); // ✒️ Navy Blue
}
