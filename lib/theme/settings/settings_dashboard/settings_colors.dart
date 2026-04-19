import 'package:flutter/material.dart';

class SettingsColors {
  // --- Core Backgrounds ---
  static const Color pageBackground = Color(0xFF0B0F19); // Deepest Black/Blue
  
  // --- Card Gradients (Premium Look) ---
  static const Color cardBgStart = Color(0xFF1F2937); // Dark Slate
  static const Color cardBgEnd = Color(0xFF111827);   // Darker Navy
  static const Color cardHoverBg = Color(0xFF374151); // Lighter for hover

  // --- Accents & Borders ---
  static const Color accentGold = Color(0xFFD4AF37);  // Classic Gold
  static const Color borderDefault = Color(0xFF1F2937);
  static const Color borderHighlight = Color(0xFF4B5563);
  
  // --- Text System ---
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF); // Muted Grey
  static const Color textGold = Color(0xFFFFD700);

  // --- Glow Effects ---
  static const Color glowGold = Color(0x1AD4AF37); // Subtle Gold Glow
  static const Color glowBlue = Color(0x1A3B82F6); // Subtle Blue Glow

  // ✨ GOLD GRADIENT (For Headers/Icons)
  static const Gradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFC5A059)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 🔥 CARD GRADIENT (Glassmorphism Base)
  static const Gradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cardBgStart, cardBgEnd],
    stops: [0.0, 1.0],
  );
}