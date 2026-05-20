// =============================================================================
// FILE        : quick_actions_colors.dart
// MODULE      : Dashboard / Quick Actions
// LAYER       : Theme / Colors
// DESCRIPTION : Complete color palette for Quick Actions card.
//               Matched with the project's dark theme (BillCard, ShopCard pattern).
// =============================================================================

import 'package:flutter/material.dart';

class QuickActionsColors {
  // ==========================================
  // CARD BACKGROUND (matches ShopCard & BillCard)
  // ==========================================
  static const Color cardBgStart = Color(0xFF1F2937); // Dark Slate
  static const Color cardBgEnd = Color(0xFF111827); // Deep Navy Black

  // ==========================================
  // HEADER
  // ==========================================
  static const Color headerText =
      Color(0xFFD4AF37); // Gold â€” matches shop card
  static const Color headerLetterSpacing = Color(0xFFD4AF37);

  // ==========================================
  // ACTION BUTTON (Cream background â€” Python QA_BG matches this)
  // ==========================================
  static const Color btnBg =
      Color(0xFFF4F1E8); // Cream â€” exactly Python CARD_CREAM
  static const Color btnText =
      Color(0xFF1A2238); // Dark Blue â€” exactly Python TEXT_DARK_BLUE
  static const Color btnIconDefault = Color(0xFF1A2238); // Dark
  static const Color btnBorderDefault =
      Color(0x22C8A660); // Gold border, subtle

  // Button pressed state
  static const Color btnBgPressed = Color(0xFFE8E3D5); // Slightly darker cream
  static const Color btnBorderPressed =
      Color(0xFFC8A660); // Gold border visible

  // Button hover state
  static const Color btnBgHover = Color(0xFFFAF7F0); // Lighter cream

  // ==========================================
  // DIVIDER
  // ==========================================
  static const Color divider = Color(0x1AD4AF37); // Gold, very subtle

  // ==========================================
  // GLOW (ambient background glow â€” like BillCard)
  // ==========================================
  static const Color glowTopRight = Color(0x0FD4AF37); // Very subtle gold
  static const Color glowBottomLeft = Color(0x08D4AF37);

  // ==========================================
  // ACCENT COLORS per button (same as model, kept here for easy theming)
  // ==========================================
  static const Color accentInvoice = Color(0xFFF59E0B); // Gold
  static const Color accentStock = Color(0xFF10B981); // Emerald
  static const Color accentCustomer = Color(0xFF6366F1); // Indigo
  static const Color accentCash = Color(0xFFEC4899); // Pink

  // Shadow on icon circle bg
  static Color iconCircleBg(Color accent) => accent.withValues(alpha: 0.12);
  static Color btnShadow = Colors.black.withValues(alpha: 0.18);
}
