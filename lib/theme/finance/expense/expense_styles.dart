// =============================================================================
// FILE        : expense_styles.dart
// MODULE      : Expense Entry
// LAYER       : Theme
// DESCRIPTION : Typography & visual decorations for Expense Entry.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'expense_colors.dart';

class ExpenseStyles {
  ExpenseStyles._();

  // ── App Bar ───────────────────────────────────────────────────────────────

  static TextStyle get appBarTitle => GoogleFonts.inter(
        fontSize: 18.0,
        fontWeight: FontWeight.w700,
        color: ExpenseColors.shellTitle,
        letterSpacing: 0.5,
      );

  static TextStyle get appBarSubtitle => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: ExpenseColors.shellMuted,
      );

  // ── Left Panel ────────────────────────────────────────────────────────────

  static TextStyle get totalLabel => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ExpenseColors.textSecondary,
        letterSpacing: 0.8,
      );

  static TextStyle get totalAmount => GoogleFonts.manrope(
        fontSize: 28.0,
        fontWeight: FontWeight.w900,
        color: ExpenseColors.moduleAccentMid,
        height: 1.0,
      );

  static TextStyle get sectionHeader => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: ExpenseColors.textSecondary,
        letterSpacing: 1.1,
      );

  static TextStyle get metaLabel => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: ExpenseColors.textMuted,
      );

  static TextStyle get metaValue => GoogleFonts.manrope(
        fontSize: 13.0,
        fontWeight: FontWeight.w700,
        color: ExpenseColors.textPrimary,
      );

  // ── List Items ────────────────────────────────────────────────────────────

  static TextStyle get groupHeader => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: ExpenseColors.textSecondary,
        letterSpacing: 0.4,
      );

  static TextStyle get groupTotal => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: ExpenseColors.moduleAccentMid,
      );

  static TextStyle get itemCategory => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: ExpenseColors.textPrimary,
      );

  static TextStyle get itemMeta => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: ExpenseColors.textSecondary,
      );

  static TextStyle get itemAmount => GoogleFonts.manrope(
        fontSize: 15.0,
        fontWeight: FontWeight.w800,
        color: ExpenseColors.moduleAccentMid,
      );

  static TextStyle get expenseId => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: ExpenseColors.textMuted,
        fontFeatures: [const FontFeature.tabularFigures()],
      );

  // ── Dialog / Form ─────────────────────────────────────────────────────────

  static TextStyle get labelPrimary => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: ExpenseColors.textPrimary,
      );

  static TextStyle get labelSecondary => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ExpenseColors.textSecondary,
      );

  static TextStyle get labelMuted => GoogleFonts.inter(
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
        color: ExpenseColors.textMuted,
      );

  static TextStyle get inputText => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: ExpenseColors.textDark,
      );

  static TextStyle get amountInput => GoogleFonts.manrope(
        fontSize: 22.0,
        fontWeight: FontWeight.w900,
        color: ExpenseColors.textDark,
      );

  // ── Breakdown Bar ─────────────────────────────────────────────────────────

  static TextStyle get breakdownLabel => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: ExpenseColors.textSecondary,
      );

  static TextStyle get breakdownAmount => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: ExpenseColors.textPrimary,
      );

  static TextStyle get breakdownPct => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: ExpenseColors.textMuted,
      );
}
