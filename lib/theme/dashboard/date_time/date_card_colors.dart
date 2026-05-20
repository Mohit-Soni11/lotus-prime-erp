import 'package:flutter/material.dart';

class DateCardColors {
  // 🔥 PREMIUM DARK THEME (Synced with Bill Card)

  // Backgrounds (Matching Bill Card's Deep Gradient)
  static const Color cardBgStart = Color(0xFF1F2937); // Dark Slate
  static const Color cardBgEnd = Color(0xFF0F172A); // Rich Navy Black

  // Accents
  static const Color goldAccent = Color(0xFFF59E0B);
  static const Color goldBright = Color(0xFFFFD700);

  // Icon Box
  static const Color iconBoxBg = Color(0xFF374151);
  static const Color iconBoxBorder = Color(0x33F59E0B); // Low opacity gold

  // --- TEXT COLORS ---
  static const Color textTime = Color(0xFFFFFFFF); // Pure White for contrast
  static const Color textDay = Color(0xFFD4AF37); // Gold (Will use Shader)
  static const Color textDate = Color(0xFF9CA3AF); // Cool Grey

  // --- GLOWS ---
  static const Color glowColor1 = Color(0x1AF59E0B); // Top Right Glow
  static const Color glowColor2 = Color(0x0DF59E0B); // Bottom Left Glow

  // ✨ GOLDEN GRADIENT (For Day Name)
  static const Gradient goldTextGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
