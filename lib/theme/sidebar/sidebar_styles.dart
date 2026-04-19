import 'package:flutter/material.dart';
import 'sidebar_colors.dart';

class SidebarStyles {
  // --- TEXT STYLES ---
  
  // Header (LOTUS ERP)
  static const TextStyle hero = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: SidebarColors.textPrimary,
    letterSpacing: 1.0,
  );

  // Normal Menu Item
  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: SidebarColors.textSecondary,
    fontWeight: FontWeight.w400,
  );

  // Active/Selected Item (Gold & Bold)
  static const TextStyle action = TextStyle(
    fontSize: 14,
    color: SidebarColors.primary, 
    fontWeight: FontWeight.w600,
  );

  // Tooltip Text
  static const TextStyle tooltip = TextStyle(
    fontSize: 12,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );
}