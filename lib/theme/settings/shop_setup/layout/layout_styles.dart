import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'layout_colors.dart';

class LayoutStyles {
  // --- ðŸ“ DIMENSIONS ---
  static const double headerHeight = 85.0;

  // --- âœï¸ TYPOGRAPHY (Clean & Sharp) ---
  // Thin, Spaced out, Uppercase looks expensive.
  static TextStyle get headerTitle => GoogleFonts.inter(
        fontSize: 16.0,
        fontWeight: FontWeight.w600, // Dark mode mein thoda weight badhaya
        color: LayoutColors.textTitle,
        letterSpacing: 1.2, // Wide tracking
      );

  static TextStyle get stepTitle => GoogleFonts.manrope(
        fontSize: 13.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  // --- ðŸ“¦ CONTAINERS & DECORATIONS ---

  // The "Floating Glass Panel" Effect
  static BoxDecoration glassPanelDecoration = BoxDecoration(
    color: LayoutColors.panelBg.withValues(alpha: 0.95), // Deep Navy opacity
    border: const Border(
      bottom: BorderSide(color: LayoutColors.borderStroke, width: 1),
    ),
  );

  // --- âŒ¨ï¸ MINIMALIST INPUT ---
  static InputDecoration inputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      // âœ… Updated: Uses 'inputFill' from new LayoutColors
      fillColor: LayoutColors.inputFill,
      hintText: hint,
      // âœ… Updated: Uses 'textPlaceholder'
      hintStyle:
          GoogleFonts.inter(color: LayoutColors.textPlaceholder, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), // Modern Standard
        borderSide:
            const BorderSide(color: LayoutColors.borderStroke, width: 1),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        // âœ… Updated: Focus par Royal Gold Border
        borderSide:
            const BorderSide(color: LayoutColors.goldPrimary, width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: LayoutColors.error, width: 1),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: LayoutColors.error, width: 1.5),
      ),
    );
  }
}
