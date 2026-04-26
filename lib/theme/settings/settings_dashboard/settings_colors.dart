// =============================================================================
// FILE : lib/theme/settings/settings_dashboard/settings_colors.dart
// THEME: Dark Premium — matches Dashboard, Sidebar, Shell
// =============================================================================

import 'package:flutter/material.dart';

class SettingsColors {
  // ── Page Background ──
  static const Color pageBackground = Color(0xFF0B0F19); // Deep Dark Navy

  // ── Cards ──
  static const Color cardBg = Color(0xFF1F2937); // Dark Slate
  static const Color cardBgEnd = Color(0xFF111827); // Darker Navy
  static const Color cardHoverBg = Color(0xFF2D3748); // Lighter on hover
  static const Color cardBorder = Color(0xFF374151); // Subtle border
  static const Color cardHoverBorder = Color(0xFFD4AF37); // Gold on hover

  // ── Card Gradient ──
  static const Gradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardBg, cardBgEnd],
  );

  // ── Gold Brand Accents ──
  static const Color accentGold = Color(0xFFD4AF37); // Classic Jewellery Gold
  static const Color accentGoldLight = Color(0x1AD4AF37); // Pale gold tint
  static const Color accentGoldGlow = Color(0x25D4AF37); // Gold glow/shadow

  // ── Text ──
  static const Color textHeading = Color(0xFFF9FAFB); // Near white
  static const Color textTitle = Color(0xFFE5E7EB); // Soft white
  static const Color textSubtitle = Color(0xFF6B7280); // Muted grey
  static const Color textMuted = Color(0xFF4B5563); // Dimmer muted

  // ── Divider ──
  static const Color divider = Color(0xFF1F2937);

  // ── System Status ──
  static const Color onlineGreen = Color(0xFF16A34A);
  static const Color onlineGlow = Color(0x3016A34A);
}
