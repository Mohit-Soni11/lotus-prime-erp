import 'package:flutter/material.dart';

class LayoutColors {
  // --- ðŸŒŒ DASHBOARD MATCHED BACKGROUNDS (Deep Navy) ---
  // Ye wahi color hai jo topbar_colors.dart mein 'background' hai (0xFF111827)
  static const Color scaffoldBg = Color(0xFF111827);

  // Panels ke liye thoda light shade (Dark Slate - 0xFF1F2937)
  static const Color panelBg = Color(0xFF1F2937);
  static const Color cardSurface =
      Color(0xFF252F3F); // Thoda sa aur light for cards

  // --- ðŸ† ROYAL GOLD (Dashboard Accent) ---
  // Ye wahi 'accentGold' hai (0xFFD4AF37)
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFB8860B);

  // --- ðŸŸ¢ SYSTEM STATUS (Dashboard Green) ---
  // Ye wahi 'systemOnline' color hai (0xFF10B981)
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFF064E3B); // Dark Green bg for badge

  static const Color error = Color(0xFFEF4444);

  // --- ðŸŒ«ï¸ BORDERS & DIVIDERS ---
  static const Color borderStroke =
      Color(0xFF374151); // Divider Color form Dashboard
  static const Color glassBorder = Color(0xFF374151);

  // --- âœï¸ TYPOGRAPHY ---
  static const Color textTitle = Color(0xFFF9FAFB); // Pure White
  static const Color textBody = Color(0xFF9CA3AF); // Muted Grey
  static const Color textPlaceholder = Color(0xFF6B7280);

  // --- ðŸ“ INPUT FIELDS ---
  static const Color inputFill = Color(0xFF1F2937); // Search Bar wala color

  // --- âœ¨ GRADIENTS ---
  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldLight, goldPrimary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navyGradient = LinearGradient(
    colors: [Color(0xFF1F2937), Color(0xFF111827)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // --- ðŸŒ‘ SHADOWS ---
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> goldShadow = [
    BoxShadow(
      color: goldPrimary.withValues(alpha: 0.3),
      blurRadius: 15,
      offset: const Offset(0, 4),
    ),
  ];
}
