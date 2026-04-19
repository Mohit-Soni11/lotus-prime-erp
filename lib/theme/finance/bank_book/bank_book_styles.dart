// =============================================================================
// FILE        : bank_book_styles.dart
// MODULE      : Finance & Ledgers / Bank Book
// LAYER       : Theme
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bank_book_colors.dart';

class BankBookStyles {
  BankBookStyles._();

  static TextStyle get appBarTitle => GoogleFonts.inter(
    fontSize:      18.0,
    fontWeight:    FontWeight.w700,
    color:         BankBookColors.shellTitle,
    letterSpacing: 1.2,
  );

  static TextStyle get sectionTitle => GoogleFonts.inter(
    fontSize:      13.0,
    fontWeight:    FontWeight.w700,
    color:         BankBookColors.textMuted,
    letterSpacing: 1.0,
  );

  static TextStyle get amountHero => GoogleFonts.inter(
    fontSize:      28.0,
    fontWeight:    FontWeight.w800,
    color:         BankBookColors.textDark,
    letterSpacing: -0.5,
  );

  static TextStyle get amountMedium => GoogleFonts.inter(
    fontSize:   18.0,
    fontWeight: FontWeight.w700,
    color:      BankBookColors.textDark,
  );

  static TextStyle get amountSmall => GoogleFonts.inter(
    fontSize:   14.0,
    fontWeight: FontWeight.w700,
    color:      BankBookColors.textDark,
  );

  static TextStyle get labelPrimary => GoogleFonts.inter(
    fontSize:   14.0,
    fontWeight: FontWeight.w600,
    color:      BankBookColors.textPrimary,
  );

  static TextStyle get labelSecondary => GoogleFonts.inter(
    fontSize:   12.0,
    fontWeight: FontWeight.w500,
    color:      BankBookColors.textSecondary,
  );

  static TextStyle get labelMuted => GoogleFonts.inter(
    fontSize:   11.0,
    fontWeight: FontWeight.w500,
    color:      BankBookColors.textMuted,
  );

  static TextStyle get txnCategory => GoogleFonts.inter(
    fontSize:   14.0,
    fontWeight: FontWeight.w600,
    color:      BankBookColors.textPrimary,
  );

  static TextStyle get txnSubtitle => GoogleFonts.inter(
    fontSize:   12.0,
    fontWeight: FontWeight.w400,
    color:      BankBookColors.textSecondary,
  );

  static TextStyle get txnAmountCredit => GoogleFonts.inter(
    fontSize:   15.0,
    fontWeight: FontWeight.w700,
    color:      BankBookColors.creditChip,
  );

  static TextStyle get txnAmountDebit => GoogleFonts.inter(
    fontSize:   15.0,
    fontWeight: FontWeight.w700,
    color:      BankBookColors.debitChip,
  );

  static TextStyle get inputText => GoogleFonts.inter(
    fontSize:   15.0,
    fontWeight: FontWeight.w600,
    color:      BankBookColors.textDark,
  );

  static TextStyle get toggleActive => GoogleFonts.inter(
    fontSize:   12.0,
    fontWeight: FontWeight.w700,
    color:      BankBookColors.toggleActiveText,
  );

  static TextStyle get toggleInactive => GoogleFonts.inter(
    fontSize:   12.0,
    fontWeight: FontWeight.w600,
    color:      BankBookColors.toggleInactiveText,
  );

  // Account card (dark panel)
  static TextStyle get accountName => GoogleFonts.inter(
    fontSize:   14.0,
    fontWeight: FontWeight.w700,
    color:      BankBookColors.shellTitle,
  );

  static TextStyle get accountNumber => GoogleFonts.inter(
    fontSize:   11.0,
    fontWeight: FontWeight.w500,
    color:      BankBookColors.shellMuted,
    letterSpacing: 1.0,
  );

  static TextStyle get accountBalance => GoogleFonts.inter(
    fontSize:   20.0,
    fontWeight: FontWeight.w800,
    color:      BankBookColors.brandGold,
  );
}