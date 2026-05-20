// -----------------------------------------------------------------------------
// FILE: add_supplier_styles.dart
// MODULE: Supplier â†’ Add Supplier
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_supplier_colors.dart';

class AddSupplierStyles {
  AddSupplierStyles._();

  static const double appBarHeight = 70.0;
  static const double inputHeight = 52.0;
  static const double cardRadius = 16.0;
  static const double inputRadius = 10.0;
  static const double sectionIconSize = 20.0;
  static const double sectionIconBox = 38.0;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 20, 20, 100);
  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);
  static const EdgeInsets fieldGap = EdgeInsets.only(bottom: 16.0);

  // â”€â”€ TYPOGRAPHY (Updated to Premium Style) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get appBarTitle => GoogleFonts.inter(
        fontSize: 18, // Changed to 18
        fontWeight: FontWeight.w700,
        color: AddSupplierColors.shellTextTitle,
        letterSpacing: 1.2, // Changed to 1.2
      );

  static TextStyle get appBarSubtitle => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AddSupplierColors.brandGold,
        letterSpacing: 1.5,
      );

  static const TextStyle systemOnlineText = TextStyle(
    color: AddSupplierColors.onlineGreen, // Using theme color
    fontSize: 12.0, // Changed to 12.0
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5, // Changed to 0.5
  );

  static TextStyle get sectionTitle => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AddSupplierColors.bodyTextMain,
      );

  static TextStyle get sectionSubtitle => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AddSupplierColors.bodyTextMuted,
        letterSpacing: 1.2,
      );

  static TextStyle get fieldLabel => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AddSupplierColors.inputLabel,
      );

  static TextStyle get fieldInput => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AddSupplierColors.inputText,
      );

  static TextStyle get fieldHint => GoogleFonts.inter(
        fontSize: 13,
        color: AddSupplierColors.inputHint,
      );

  static TextStyle get saveButtonText => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AddSupplierColors.saveBtnText,
      );

  static BoxDecoration get sectionCard => BoxDecoration(
        color: AddSupplierColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
            color: AddSupplierColors.bodyBorder.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
              color: AddSupplierColors.shadowLight,
              blurRadius: 15,
              offset: Offset(0, 5))
        ],
      );

  static InputDecoration fieldDecoration({
    required String label,
    String? hint,
    Widget? prefix,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefix,
        suffixIcon: suffix,
        labelStyle: fieldLabel,
        hintStyle: fieldHint,
        floatingLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AddSupplierColors.brandGold),
        filled: true,
        fillColor: AddSupplierColors.inputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(inputRadius),
            borderSide: const BorderSide(color: AddSupplierColors.inputBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(inputRadius),
            borderSide: const BorderSide(color: AddSupplierColors.inputBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(inputRadius),
            borderSide: const BorderSide(
                color: AddSupplierColors.inputBorderFocus, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(inputRadius),
            borderSide: const BorderSide(color: AddSupplierColors.error)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(inputRadius),
            borderSide:
                const BorderSide(color: AddSupplierColors.error, width: 1.5)),
        counterText: '',
      );
}
