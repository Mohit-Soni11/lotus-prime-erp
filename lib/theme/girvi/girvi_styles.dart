// =============================================================================
// FILE        : girvi_styles.dart
// MODULE      : Girvi / Pawn
// LAYER       : Theme / Styles
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'girvi_colors.dart';

class GirviStyles {
  GirviStyles._();

  // â”€â”€ Shell â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get shellDecoration => const BoxDecoration(
        color: GirviColors.shellBg,
        border: Border(
          bottom: BorderSide(color: GirviColors.shellBorder, width: 1),
        ),
      );

  // â”€â”€ Typography â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get shellTitle => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: GirviColors.shellTextTitle,
        letterSpacing: 0.8,
      );

  static TextStyle get shellMuted => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: GirviColors.shellTextMuted,
        letterSpacing: 0.3,
      );

  static TextStyle get sectionTitle => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: GirviColors.textDark,
        letterSpacing: 0.2,
      );

  static TextStyle get fieldLabel => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: GirviColors.textBody,
        letterSpacing: 0.1,
      );

  static TextStyle get fieldInput => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: GirviColors.textDark,
      );

  static TextStyle get fieldHint => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: GirviColors.textHint,
      );

  static TextStyle get readOnlyValue => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: GirviColors.success,
      );

  static TextStyle get readOnlyLabel => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: GirviColors.textMuted,
      );

  static TextStyle get ticketNumber => GoogleFonts.robotoMono(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: GirviColors.brandGold,
        letterSpacing: 1.0,
      );

  static TextStyle get saveButtonText => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: GirviColors.shellBg,
        letterSpacing: 0.3,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: GirviColors.textMuted,
      );

  static TextStyle get amountLarge => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: GirviColors.textDark,
      );

  static TextStyle get statusBadge => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );

  // â”€â”€ Heights â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const double inputHeight = 52.0;

  // â”€â”€ Padding â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const EdgeInsets cardPadding = EdgeInsets.all(20);
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const EdgeInsets sectionGap = EdgeInsets.only(bottom: 16);

  // â”€â”€ Decorations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration cardWithAccent(Color accent) => BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border(left: BorderSide(color: accent, width: 4)),
        boxShadow: const [
          BoxShadow(
              color: GirviColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      );

  static BoxDecoration get inputNormal => BoxDecoration(
        color: GirviColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GirviColors.cardBorder),
      );

  static BoxDecoration get inputFocused => BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GirviColors.brandGold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: GirviColors.brandGold.withValues(alpha: 0.12),
            blurRadius: 8,
          )
        ],
      );

  static BoxDecoration get inputDisabled => BoxDecoration(
        color: GirviColors.inputBgLocked,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GirviColors.divider),
      );

  static BoxDecoration sectionIconBox(Color accent) => BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      );

  static BoxDecoration statCardDecoration(Color accent) => BoxDecoration(
        color: GirviColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
              color: GirviColors.shadowLight,
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      );
}
