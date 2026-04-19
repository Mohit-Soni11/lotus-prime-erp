import 'package:flutter/material.dart';

class NewCustomerColors {
  // --- Base Theme (Matches BillCard) ---
  static const Color cardBgStart = Color(0xFF1F2937); // Dark Slate
  static const Color cardBgEnd = Color(0xFF0F172A);   // Rich Navy Black
  
  // --- Icon Container (New) ---
  static const Color iconBoxBg = Color(0xFF374151);  
  static const Color iconBoxBorder = Color(0x33F59E0B); 

  // --- Text Colors ---
  static const Color textTitle = Color(0xFF9CA3AF);  
  static const Color textCount = Color(0xFFFFFFFF);  
  
  // --- Dynamic Accents (Logic based) ---
  static const Color valueGrowth = Color(0xFF00E676); // Neon Green
  static const Color iconGrowth = Color(0xFF00E676);
  
  static const Color valueDefault = Colors.white; 
  static const Color iconDefault = Color(0xFFFFD700); // Gold

  // --- Glows (Dynamic) ---
  static const Color glowDefault = Color(0x1AD4AF37); // Gold Glow
  static const Color glowGrowth = Color(0x3300E676);  // Green Glow (Stronger)

  // ✨ GOLD GRADIENT (For Title Sync)
  static const Gradient goldTextGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}