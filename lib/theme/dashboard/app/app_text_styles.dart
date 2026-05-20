import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart'; // ✅ Direct Import to avoid UV circular loop

class AppTextStyles {
  const AppTextStyles();

  // Internal Helper (Private)
  // We use a static instance of colors here to keep it independent
  static const _colors = AppColors();

  TextStyle get _base => GoogleFonts.inter();

  // --- 1. HEADINGS ---

  // Hero: For Brand Names (LOTUS ERP)
  TextStyle get hero => _base.copyWith(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      letterSpacing: 2.0,
      color: _colors.textPrimary);

  // H1: Page Titles (Welcome Back)
  TextStyle get h1 => _base.copyWith(
      fontSize: 32, fontWeight: FontWeight.bold, color: _colors.textPrimary);

  // H2: Section Headers
  TextStyle get h2 => _base.copyWith(
      fontSize: 24, fontWeight: FontWeight.w600, color: _colors.textPrimary);

  // --- 2. BODY CONTENT ---

  // Body: Standard Text
  TextStyle get body => _base.copyWith(
      fontSize: 14, fontWeight: FontWeight.normal, color: _colors.textPrimary);

  // Label: Subtitles / Input Labels
  TextStyle get label => _base.copyWith(
      fontSize: 14, fontWeight: FontWeight.w500, color: _colors.textSecondary);

  // Hint: Small text / placeholders
  TextStyle get hint => _base.copyWith(
      fontSize: 12, fontWeight: FontWeight.w400, color: _colors.textSecondary);

  // --- 3. COMPONENTS ---

  // Button Text (Usually Dark on Gold)
  TextStyle get button => _base.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF000000) // Always black for contrast on Gold
      );

  // Link / Action Text
  TextStyle get action => _base.copyWith(
      fontSize: 14, fontWeight: FontWeight.bold, color: _colors.primary);
}
