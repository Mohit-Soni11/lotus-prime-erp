import 'package:flutter/material.dart';

class PendingOrderColors {
  // 🔥 UPDATED BACKGROUND: Thoda Light kiya hai taaki Dashboard se alag dikhe
  static const Color cardBgStart = Color(0xFF2A3441); // Lighter Slate (Pop effect)
  static const Color cardBgEnd = Color(0xFF0F172A);   // Deep Navy

  // --- Icons & Box ---
  static const Color iconBoxBg = Color(0xFF374151);  
  static const Color iconBoxBorder = Color(0x33FF7043); 

  // --- Text Colors ---
  static const Color textTitle = Color(0xFF9CA3AF);  
  static const Color textCount = Color(0xFFFFFFFF);  
  
  // --- Accents (Neon Orange) ---
  static const Color accentColor = Color(0xFFFF7043); 
  static const Color accentGlow = Color(0xFFFF5722);  

  // 🔥 GLOWS (Opacity Increased for "Alive" feel)
  static const Color glowAmbient = Color(0x33FF7043); // 20% Opacity (Visible Glow)

  // Stats Specific
  static const Color goldStats = Color(0xFFFFD700); 
  static const Color silverStats = Color(0xFFC0C0C0); 

  // ✨ ORANGE GRADIENT
  static const Gradient orangeTextGradient = LinearGradient(
    colors: [Color(0xFFFFAB91), Color(0xFFFF7043)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}