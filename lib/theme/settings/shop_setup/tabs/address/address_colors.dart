// -----------------------------------------------------------------------------
// FILE: address_colors.dart
// TYPE: Theme / Colors
// AUTHOR: Senior System Architect
// DESCRIPTION: 100% Centralized color palette. Zero magic numbers or dynamic 
//              opacities in UI layer for maximum 60-FPS rendering performance.
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';

class AddressColors {
  // --- Backgrounds ---
  static const Color bgMain = Color(0xFFF8F5F1);       
  static const Color cardBg = Color(0xFFFFFFFF);       
  static const Color inputBg = Color(0xFFF9FAFB);      
  static const Color inputBgLocked = Color(0xFFF3F4F6); 

  // --- Common Elements ---
  static const Color goldAccent = Color(0xFFD4AF37);   // Premium Gold
  static const Color borderLight = Color(0xFFE5E7EB);  
  static const Color shadowSubtle = Color(0x0A000000); 
  static const Color transparent = Colors.transparent; 
  
  // --- Typography ---
  static const Color textDark = Color(0xFF111827);     
  static const Color textBody = Color(0xFF374151);     
  static const Color textHint = Color(0xFF9CA3AF);     
  static const Color textMuted = Color(0xFF6B7280);    
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textWhite70 = Color(0xB3FFFFFF);  // White with 70% opacity
  static const Color mandatoryStar = Color(0xFFEF5350); // Red 400

  // --- Actions & States ---
  static const Color btnDanger = Color(0xFFEF4444);    
  static const Color iconEdit = Color(0xFF374151);      
  static const Color saveBtn = Color(0xFF166534);      // Forest Green      
  static const Color iconSuccessDefault = Color(0xFF059669); 

  // --- Header Badge & Status ---
  static const Color statusActiveBg = Color(0xFFDCFCE7); 
  static const Color statusActiveText = Color(0xFF166534); 

  // --- Pre-Calculated Opacities (🚀 UPGRADE: Zero .withOpacity() in UI) ---
  static const Color goldAccent10 = Color(0x1AD4AF37); // Gold 10%
  static const Color goldAccent20 = Color(0x33D4AF37); // Gold 20%
  static const Color statusActiveText30 = Color(0x4D166534); // Active Text 30%
  static const Color textHint30 = Color(0x4D9CA3AF); // Hint 30%

  // --- BRAND COLORS (Input Fields & Chips) ---
  static const Color brandLocation = Color(0xFFEA4335); // Red
  static const Color brandStreet   = Color(0xFF2563EB); // Blue
  static const Color brandCity     = Color(0xFF7C3AED); // Violet
  static const Color brandState    = Color(0xFF0891B2); // Cyan
  static const Color brandPin      = Color(0xFFD97706); // Amber
  static const Color brandCountry  = Color(0xFF059669); // Green
  
  // --- Map Specific ---
  static const Color mapPlaceholderBg = Color(0xFFF3F4F6);
  static const Color mapOverlayLocked = Color(0x26FFFFFF);  // White 15% opacity
  static const Color mapOverlayLoading = Color(0x42000000); // Black 26% opacity
}