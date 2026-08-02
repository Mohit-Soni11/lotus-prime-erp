// =============================================================================
// FILE        : silver_stock_styles.dart
// MODULE      : Stock & Inventory (Silver)
// LAYER       : Theme / Styles
// DESCRIPTION : Premium ERP typography + decorations for Silver UI.
//               Full parity with AddStockStyles (Gold).
//               Silver-toned input focus borders instead of gold.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'silver_stock_colors.dart';

class SilverStockStyles {
  SilverStockStyles._();

  // â”€â”€ APP BAR HEIGHT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const double appBarHeight = 114.0; // 70 top + 44 stepper

  // â”€â”€ SHELL / APP BAR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get shellTitle => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: SilverStockColors.shellTextTitle,
        letterSpacing: 0.8,
      );

  // â”€â”€ HEADER TYPOGRAPHY â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get headerTitle => GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: SilverStockColors.textDark,
      );

  // â”€â”€ PAGE HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get pageTitle => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: SilverStockColors.textDark,
        letterSpacing: 0.3,
      );

  // â”€â”€ SECTION CARD HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get sectionTitle => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: SilverStockColors.textDark,
        letterSpacing: 0.2,
      );

  // â”€â”€ PANEL & CARD HEADERS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get panelHeader => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: SilverStockColors.textDark,
      );

  // â”€â”€ FIELD LABEL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get fieldLabel => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: SilverStockColors.textBody,
        letterSpacing: 0.1,
      );

  // â”€â”€ INPUT LABEL (alias) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get inputLabel => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: SilverStockColors.textMuted,
      );

  // â”€â”€ FIELD INPUT TEXT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get fieldInput => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: SilverStockColors.textDark,
      );

  // â”€â”€ INPUT TEXT (alias) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get inputText => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: SilverStockColors.textDark,
      );

  // â”€â”€ FIELD HINT / PLACEHOLDER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get fieldHint => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: SilverStockColors.textHint,
      );

  // â”€â”€ TAG LINE / SUBTITLE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get tagLine => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: SilverStockColors.textMuted,
        letterSpacing: 0.5,
      );

  // â”€â”€ READ-ONLY VALUE (Net Weight, etc.) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get readOnlyValue => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: SilverStockColors.success,
      );

  // â”€â”€ SMALL MUTED / CAPTION TEXT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: SilverStockColors.textMuted,
      );

  // â”€â”€ SAVE BUTTON â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get saveButtonText => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: SilverStockColors.shellBg,
        letterSpacing: 0.3,
      );

  // â”€â”€ RESET BUTTON â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get resetButtonText => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: SilverStockColors.textMuted,
      );

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // DECORATIONS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  // â”€â”€ MAIN CARD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: SilverStockColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SilverStockColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: SilverStockColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: SilverStockColors.shadowMedium,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      );

  // â”€â”€ CARD WITH SILVER ACCENT BORDER (active section) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration cardWithAccent(Color accentColor) => BoxDecoration(
        color: SilverStockColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: SilverStockColors.shadowMedium,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  // â”€â”€ INPUT FIELD (Normal) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get inputNormal => BoxDecoration(
        color: SilverStockColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SilverStockColors.cardBorder, width: 1),
      );

  // â”€â”€ INPUT FIELD (Focused â€” silver border) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get inputFocused => BoxDecoration(
        color: SilverStockColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SilverStockColors.brandSilver, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: SilverStockColors.brandSilver.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // â”€â”€ INPUT FIELD (Disabled) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get inputDisabled => BoxDecoration(
        color: SilverStockColors.inputBgLocked,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SilverStockColors.borderLight.withValues(alpha: 0.5),
          width: 1,
        ),
      );

  // â”€â”€ INPUT FIELD (Error) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get inputError => BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SilverStockColors.danger, width: 1.5),
      );

  // â”€â”€ READ-ONLY VALUE BOX â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration readOnlyBox(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      );

  // â”€â”€ SHELL APP BAR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const BoxDecoration shellDecoration = BoxDecoration(
    color: SilverStockColors.shellPanelBg,
    border: Border(
      bottom: BorderSide(color: SilverStockColors.shellBorder, width: 1),
    ),
  );

  // â”€â”€ SECTION ICON CONTAINER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration sectionIconBox(Color accent) => BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      );

  // â”€â”€ DIMENSIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const double inputHeight = 52.0;
  static const double dropdownHeight = 52.0;
  static const EdgeInsets cardPadding = EdgeInsets.all(24);
  static const EdgeInsets pagePadding = EdgeInsets.all(24);
}
