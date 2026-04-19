import 'package:flutter/material.dart';

class UV {
  static const AppColors colors = AppColors();
  // Icons aur Styles bhi yahan connect honge future mein
}

class AppColors {
  const AppColors(); 

  // --- 1. PRIMITIVES (Base Palette - Internal Use) ---
  static const Color _slate900 = Color(0xFF111827); 
  static const Color _slate800 = Color(0xFF1F2937); 
  static const Color _goldMain = Color(0xFFD4AF37); 
  static const Color _goldLight = Color(0xFFE5C578); 
  static const Color _creamWhite = Color(0xFFF9FAFB); 
  static const Color _greyText  = Color(0xFF9CA3AF);
  static const Color _success   = Color(0xFF10B981);
  static const Color _error     = Color(0xFFEF4444);
  static const Color _blueGlow  = Color(0xFF448AFF); // Added for ambient effect

  // --- 2. SEMANTIC USAGE (Public Getters) ---
  // Backgrounds
  Color get bgPrimary => _slate900;
  Color get bgSecondary => _slate800;
  
  // Text
  Color get textPrimary => _creamWhite;
  Color get textSecondary => _greyText;
  
  // Status
  Color get success => _success;
  Color get error => _error;
  Color get primary => _goldMain;

  // --- 3. UI SPECIFIC TOKENS (No Hard-coding in UI) ---
  
  // Glassmorphism specific
  Color get glassBase => _slate800.withOpacity(0.6);
  Color get glassBorder => const Color(0xFFFFFFFF).withOpacity(0.08);
  Color get overlayDark => const Color(0xFF000000).withOpacity(0.3); // For Left Panel
  
  // Ambient Glows
  Color get glowPrimary => _goldMain.withOpacity(0.3);
  Color get glowAccent => _blueGlow.withOpacity(0.2);

  // Form Fields
  Color get inputFill => _slate800;
  Color get inputBorderFocus => _goldMain;

  // --- 4. PREMIUM EFFECTS ---
  LinearGradient get goldGradient => const LinearGradient(
    colors: [_goldMain, _goldLight, _goldMain],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  BoxShadow get softShadow => const BoxShadow(
    color: Color(0x40000000), 
    blurRadius: 10,
    offset: Offset(0, 4),
  );
  
  // Success Badge Style
  Color get successBg => _success.withOpacity(0.1);
  Color get successBorder => _success.withOpacity(0.3);
}