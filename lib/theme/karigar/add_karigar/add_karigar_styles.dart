// =============================================================================
// FILE        : add_karigar_styles.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_karigar_colors.dart';

class AddKarigarStyles {
  AddKarigarStyles._();

  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 20);

  static const double cardRadius = 16.0;

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AddKarigarColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: AddKarigarColors.inputBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      );

  static BoxDecoration get shellDecoration => const BoxDecoration(
        color: AddKarigarColors.shellBg,
        border: Border(
          bottom: BorderSide(color: AddKarigarColors.shellBorder, width: 1),
        ),
      );

  static TextStyle get fieldLabel => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: AddKarigarColors.bodyTextMuted,
        letterSpacing: 0.5,
      );

  static TextStyle get fieldText => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AddKarigarColors.bodyTextMain,
      );

  static TextStyle get fieldHint => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AddKarigarColors.bodyTextHint,
      );

  static TextStyle get saveBtnText => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      );

  static TextStyle get requiredNote => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AddKarigarColors.bodyTextHint,
      );

  static TextStyle get shellTitle => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AddKarigarColors.shellTextTitle,
        letterSpacing: 0.3,
      );
}
