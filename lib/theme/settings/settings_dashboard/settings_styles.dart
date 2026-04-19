import 'package:flutter/material.dart';
import 'settings_colors.dart';

class SettingsStyles {
  // --- Dimensions ---
  static const double cardHeight = 160.0; // Fixed height for Grid
  static const double cardRadius = 16.0;
  static const EdgeInsets pagePadding = EdgeInsets.all(30.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(24.0);

  // --- Typography ---
  static const TextStyle headerTitle = TextStyle(
    fontSize: 26.0,
    fontWeight: FontWeight.bold,
    color: SettingsColors.textPrimary,
    letterSpacing: 1.0,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: SettingsColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.normal,
    color: SettingsColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle systemStatus = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    color: SettingsColors.textSecondary,
  );

  // --- DECORATIONS (The Master UI Touch) ---
  
  // 1. Base Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    gradient: SettingsColors.cardGradient,
    borderRadius: BorderRadius.circular(cardRadius),
    border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
    boxShadow: const [
      BoxShadow(
        color: Colors.black45,
        blurRadius: 20,
        offset: Offset(0, 10),
        spreadRadius: -5,
      ),
    ],
  );

  // 2. Icon Box Decoration (Glassy Look)
  static BoxDecoration iconBoxDecoration = BoxDecoration(
    color: SettingsColors.cardHoverBg.withOpacity(0.5),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: SettingsColors.borderHighlight.withOpacity(0.3)),
  );
}