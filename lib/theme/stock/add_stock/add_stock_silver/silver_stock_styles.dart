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

  // ── APP BAR HEIGHT ───────────────────────────────────────────
  static const double appBarHeight = 114.0; // 70 top + 44 stepper

  // ── SHELL / APP BAR ───────────────────────────────────────────
  static TextStyle get shellTitle => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: SilverStockColors.shellTextTitle,
        letterSpacing: 0.8,
      );

  // ── HEADER TYPOGRAPHY ────────────────────────────────────────
  static TextStyle get headerTitle => GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: SilverStockColors.textDark,
      );

  // ── PAGE HEADER ───────────────────────────────────────────────
  static TextStyle get pageTitle => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: SilverStockColors.textDark,
        letterSpacing: 0.3,
      );

  // ── SECTION CARD HEADER ───────────────────────────────────────
  static TextStyle get sectionTitle => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: SilverStockColors.textDark,
        letterSpacing: 0.2,
      );

  // ── PANEL & CARD HEADERS ─────────────────────────────────────
  static TextStyle get panelHeader => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: SilverStockColors.textDark,
      );

  // ── FIELD LABEL ───────────────────────────────────────────────
  static TextStyle get fieldLabel => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: SilverStockColors.textBody,
        letterSpacing: 0.1,
      );

  // ── INPUT LABEL (alias) ───────────────────────────────────────
  static TextStyle get inputLabel => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: SilverStockColors.textMuted,
      );

  // ── FIELD INPUT TEXT ─────────────────────────────────────────
  static TextStyle get fieldInput => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: SilverStockColors.textDark,
      );

  // ── INPUT TEXT (alias) ────────────────────────────────────────
  static TextStyle get inputText => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: SilverStockColors.textDark,
      );

  // ── FIELD HINT / PLACEHOLDER ─────────────────────────────────
  static TextStyle get fieldHint => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: SilverStockColors.textHint,
      );

  // ── TAG LINE / SUBTITLE ───────────────────────────────────────
  static TextStyle get tagLine => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: SilverStockColors.textMuted,
        letterSpacing: 0.5,
      );

  // ── READ-ONLY VALUE (Net Weight, etc.) ───────────────────────
  static TextStyle get readOnlyValue => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: SilverStockColors.success,
      );

  // ── SMALL MUTED / CAPTION TEXT ───────────────────────────────
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: SilverStockColors.textMuted,
      );

  // ── SAVE BUTTON ───────────────────────────────────────────────
  static TextStyle get saveButtonText => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: SilverStockColors.shellBg,
        letterSpacing: 0.3,
      );

  // ── RESET BUTTON ─────────────────────────────────────────────
  static TextStyle get resetButtonText => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: SilverStockColors.textMuted,
      );

  // ══════════════════════════════════════════════════════════════
  // DECORATIONS
  // ══════════════════════════════════════════════════════════════

  // ── MAIN CARD ────────────────────────────────────────────────
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

  // ── CARD WITH SILVER ACCENT BORDER (active section) ──────────
  static BoxDecoration cardWithAccent(Color accentColor) => BoxDecoration(
        color: SilverStockColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
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

  // ── INPUT FIELD (Normal) ──────────────────────────────────────
  static BoxDecoration get inputNormal => BoxDecoration(
        color: SilverStockColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SilverStockColors.cardBorder, width: 1),
      );

  // ── INPUT FIELD (Focused — silver border) ────────────────────
  static BoxDecoration get inputFocused => BoxDecoration(
        color: SilverStockColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SilverStockColors.brandSilver, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: SilverStockColors.brandSilver.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // ── INPUT FIELD (Disabled) ───────────────────────────────────
  static BoxDecoration get inputDisabled => BoxDecoration(
        color: SilverStockColors.inputBgLocked,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SilverStockColors.borderLight.withOpacity(0.5),
          width: 1,
        ),
      );

  // ── INPUT FIELD (Error) ──────────────────────────────────────
  static BoxDecoration get inputError => BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SilverStockColors.danger, width: 1.5),
      );

  // ── READ-ONLY VALUE BOX ───────────────────────────────────────
  static BoxDecoration readOnlyBox(Color color) => BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      );

  // ── SHELL APP BAR ─────────────────────────────────────────────
  static const BoxDecoration shellDecoration = BoxDecoration(
    color: SilverStockColors.shellPanelBg,
    border: Border(
      bottom: BorderSide(color: SilverStockColors.shellBorder, width: 1),
    ),
  );

  // ── SECTION ICON CONTAINER ────────────────────────────────────
  static BoxDecoration sectionIconBox(Color accent) => BoxDecoration(
        color: accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      );

  // ── DIMENSIONS ───────────────────────────────────────────────
  static const double inputHeight = 52.0;
  static const double dropdownHeight = 52.0;
  static const EdgeInsets cardPadding = EdgeInsets.all(24);
  static const EdgeInsets pagePadding = EdgeInsets.all(24);
}
