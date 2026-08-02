// =============================================================================
// FILE        : cash_book_styles.dart
// MODULE      : Accounts / Cash Book
// LAYER       : Theme
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cash_book_colors.dart';

class CashBookStyles {
  CashBookStyles._();

  // ── AppBar ────────────────────────────────────────────────────────────────
  static TextStyle get appBarTitle => GoogleFonts.inter(
        fontSize: 18.0,
        fontWeight: FontWeight.w700,
        color: CashBookColors.shellTitle,
        letterSpacing: 1.2,
      );

  // ── Section Title ─────────────────────────────────────────────────────────
  static TextStyle get sectionTitle => GoogleFonts.inter(
        fontSize: 13.0,
        fontWeight: FontWeight.w700,
        color: CashBookColors.textMuted,
        letterSpacing: 1.0,
      );

  // ── Amount — large display ────────────────────────────────────────────────
  static TextStyle get amountHero => GoogleFonts.inter(
        fontSize: 28.0,
        fontWeight: FontWeight.w800,
        color: CashBookColors.textDark,
        letterSpacing: -0.5,
      );

  static TextStyle get amountMedium => GoogleFonts.inter(
        fontSize: 18.0,
        fontWeight: FontWeight.w700,
        color: CashBookColors.textDark,
      );

  static TextStyle get amountSmall => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w700,
        color: CashBookColors.textDark,
      );

  // ── Labels ────────────────────────────────────────────────────────────────
  static TextStyle get labelPrimary => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: CashBookColors.textPrimary,
      );

  static TextStyle get labelSecondary => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: CashBookColors.textSecondary,
      );

  static TextStyle get labelMuted => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: CashBookColors.textMuted,
      );

  // ── Transaction Row ───────────────────────────────────────────────────────
  static TextStyle get txnCategory => GoogleFonts.inter(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: CashBookColors.textPrimary,
      );

  static TextStyle get txnSubtitle => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: CashBookColors.textSecondary,
      );

  static TextStyle get txnAmountIncome => GoogleFonts.inter(
        fontSize: 15.0,
        fontWeight: FontWeight.w700,
        color: CashBookColors.incomeChip,
      );

  static TextStyle get txnAmountExpense => GoogleFonts.inter(
        fontSize: 15.0,
        fontWeight: FontWeight.w700,
        color: CashBookColors.expenseChip,
      );

  // ── Input ─────────────────────────────────────────────────────────────────
  static TextStyle get inputText => GoogleFonts.inter(
        fontSize: 15.0,
        fontWeight: FontWeight.w600,
        color: CashBookColors.textDark,
      );

  // ── Toggle chips ──────────────────────────────────────────────────────────
  static TextStyle get toggleActive => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: CashBookColors.toggleActiveText,
      );

  static TextStyle get toggleInactive => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: CashBookColors.toggleInactiveText,
      );
}
