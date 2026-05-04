// =============================================================================
// FILE        : add_stock_styles.dart
// MODULE      : Stock & Inventory
// LAYER       : Theme / Styles
// DESCRIPTION : Master typography and decorations for Add Stock.
//               Mirrors SalesPosStyles + BasicInfoStyles pattern.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_stock_colors.dart';

class AddStockStyles {
  AddStockStyles._();

  // ✅ NEW: Added for PC 2 App Bar setup
  static const double appBarHeight = 60.0;

  // ── SHELL / APP BAR ───────────────────────────────────────────
  static TextStyle get shellTitle => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AddStockColors.shellTextTitle,
        letterSpacing: 0.8,
      );

  // ── PAGE HEADER ───────────────────────────────────────────────
  static TextStyle get pageTitle => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AddStockColors.textDark,
        letterSpacing: 0.3,
      );

  // ── SECTION CARD HEADER ───────────────────────────────────────
  static TextStyle get sectionTitle => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AddStockColors.textDark,
        letterSpacing: 0.2,
      );

  // ── FIELD LABEL ───────────────────────────────────────────────
  static TextStyle get fieldLabel => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AddStockColors.textBody,
        letterSpacing: 0.1,
      );

  // ── FIELD INPUT TEXT ─────────────────────────────────────────
  static TextStyle get fieldInput => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AddStockColors.textDark,
      );

  // ── FIELD HINT ───────────────────────────────────────────────
  static TextStyle get fieldHint => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AddStockColors.textHint,
      );

  // ── READ-ONLY VALUE (Net Weight, etc.) ───────────────────────
  static TextStyle get readOnlyValue => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AddStockColors.success,
      );

  // ── SMALL MUTED TEXT ─────────────────────────────────────────
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AddStockColors.textMuted,
      );

  // ── SAVE BUTTON ───────────────────────────────────────────────
  static TextStyle get saveButtonText => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AddStockColors.shellBg,
        letterSpacing: 0.3,
      );

  // ── RESET BUTTON ─────────────────────────────────────────────
  static TextStyle get resetButtonText => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AddStockColors.textMuted,
      );

  // ══════════════════════════════════════════════════════════════
  // DECORATIONS
  // ══════════════════════════════════════════════════════════════

  // ── MAIN CARD ────────────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AddStockColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AddStockColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AddStockColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: AddStockColors.shadowMedium,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      );

  // ── CARD WITH GOLD ACCENT BORDER (active/filled section) ─────
  static BoxDecoration cardWithAccent(Color accentColor) => BoxDecoration(
        color: AddStockColors.cardBg,
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
            color: AddStockColors.shadowMedium,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  // ── INPUT FIELD (Normal) ──────────────────────────────────────
  static BoxDecoration get inputNormal => BoxDecoration(
        color: AddStockColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AddStockColors.cardBorder, width: 1),
      );

  // ── INPUT FIELD (Focused — gold border) ──────────────────────
  static BoxDecoration get inputFocused => BoxDecoration(
        color: AddStockColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AddStockColors.brandGold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AddStockColors.brandGold.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // ── INPUT FIELD (Disabled) ───────────────────────────────────
  static BoxDecoration get inputDisabled => BoxDecoration(
        color: AddStockColors.inputBgLocked,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AddStockColors.borderLight.withOpacity(0.5), width: 1),
      );

  // ── INPUT FIELD (Error) ──────────────────────────────────────
  static BoxDecoration get inputError => BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AddStockColors.danger, width: 1.5),
      );

  // ── READ-ONLY VALUE BOX ───────────────────────────────────────
  static BoxDecoration readOnlyBox(Color color) => BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      );

  // ── SHELL APP BAR ─────────────────────────────────────────────
  static const BoxDecoration shellDecoration = BoxDecoration(
    color: AddStockColors.shellPanelBg,
    border: Border(
      bottom: BorderSide(color: AddStockColors.shellBorder, width: 1),
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
