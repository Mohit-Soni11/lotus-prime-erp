import 'package:flutter/material.dart';
import 'topbar_colors.dart';

class TopBarStyles {
  // --- DIMENSIONS ---
  static const double height = 70.0; // Slightly compact for better view
  static const double paddingHorizontal = 20.0;
  static const double paddingVertical = 10.0;

  static const double iconBoxSize = 40.0;
  static const double searchRadius = 12.0;

  // --- TEXT STYLES ---
  static const TextStyle dashboardTitle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w800,
    color: TopBarColors.textPrimary,
    letterSpacing: 1.0,
    fontFamily: 'Roboto',
  );

  static const TextStyle systemStatus = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w600,
    color: TopBarColors.systemText,
    letterSpacing: 0.5,
  );

  static const TextStyle searchInput = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: Colors.white, // White text for dark search bar
  );

  static const TextStyle searchHint = TextStyle(
    fontSize: 14.0,
    color: TopBarColors.textSecondary,
  );

  // --- DECORATIONS ---
  static List<BoxShadow> searchShadow = [
    const BoxShadow(
      color: TopBarColors.searchShadow,
      blurRadius: 15,
      offset: Offset(0, 5),
    )
  ];
}
