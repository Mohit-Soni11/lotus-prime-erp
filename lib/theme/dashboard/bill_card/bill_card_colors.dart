import 'package:flutter/material.dart';

class BillCardColors {
  // 🔥 PREMIUM DARK THEME PALETTE

  // Backgrounds (Subtle Deep Gradient)
  static const Color cardBgStart = Color(0xFF1F2937); // Dark Slate
  static const Color cardBgEnd = Color(0xFF0F172A); // Rich Navy Black

  // Accents
  static const Color accentGold = Color(0xFFF59E0B); // Amber Gold
  static const Color accentGoldBright = Color(0xFFFFD700); // Bright Gold

  // Icon Container
  static const Color iconBoxBg = Color(0xFF374151); // Lighter Slate
  static const Color iconBoxBorder =
      Color(0x33F59E0B); // Low opacity gold border

  // --- TEXT SYSTEM ---
  static const Color textTitle = Color(0xFF9CA3AF); // Muted Cool Grey
  static const Color textCount = Color(0xFFFFFFFF); // Pure White
  static const Color textSub = Color(0xFFD4AF37); // Standard Gold

  // --- GLOWS & SHADOWS ---
  static const Color borderHighlight =
      Color(0x1AFFFFFF); // Top White Highlight (Glass effect)
  static const Color borderShadow = Color(0x4D000000); // Bottom Black Shadow

  static const Color glowTopRight = Color(0x1AF59E0B); // 10% Gold
  static const Color glowBottomLeft = Color(0x0DF59E0B); // 5% Gold

  // ✨ THE GOLDEN GRADIENT (For Text Shader)
  static const Gradient goldTextGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
