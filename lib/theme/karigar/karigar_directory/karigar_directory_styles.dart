// =============================================================================
// FILE        : karigar_directory_styles.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'karigar_directory_colors.dart';

class KarigarDirectoryStyles {
  KarigarDirectoryStyles._();

  // â”€â”€ CARD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: KarigarDirectoryColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KarigarDirectoryColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: KarigarDirectoryColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get cardDecorationHover => BoxDecoration(
        color: KarigarDirectoryColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KarigarDirectoryColors.brandGold.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: KarigarDirectoryColors.brandGold.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // â”€â”€ STATS CARD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get statsCardDecoration => BoxDecoration(
        color: KarigarDirectoryColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KarigarDirectoryColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: KarigarDirectoryColors.shadowLight,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      );

  // â”€â”€ SEARCH â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get searchDecoration => BoxDecoration(
        color: KarigarDirectoryColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KarigarDirectoryColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: KarigarDirectoryColors.shadowLight,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      );

  // â”€â”€ SHELL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get shellDecoration => const BoxDecoration(
        color: KarigarDirectoryColors.shellBg,
        border: Border(
          bottom:
              BorderSide(color: KarigarDirectoryColors.shellBorder, width: 1),
        ),
      );

  // â”€â”€ FILTER CHIPS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const double filterBarHeight = 38;
  static const EdgeInsets chipPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const double chipBorderRadius = 20;

  // â”€â”€ AVATAR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const double avatarSize = 56;

  // â”€â”€ CARD PADDING â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const EdgeInsets cardPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 14);

  // â”€â”€ TEXT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get karigarName => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: KarigarDirectoryColors.textMain,
      );

  static TextStyle get karigarPhone => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: KarigarDirectoryColors.textBody,
      );

  static TextStyle get karigarDetail => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: KarigarDirectoryColors.textMuted,
      );

  static TextStyle get karigarSince => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: KarigarDirectoryColors.textHint,
        fontStyle: FontStyle.italic,
      );

  static TextStyle get statsValue => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: KarigarDirectoryColors.textMain,
      );

  static TextStyle get statsLabel => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: KarigarDirectoryColors.textMuted,
      );

  static TextStyle get chipActiveStyle => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: KarigarDirectoryColors.brandGold,
      );

  static TextStyle get chipInactiveStyle => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: KarigarDirectoryColors.textMuted,
      );

  static TextStyle get searchText => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: KarigarDirectoryColors.textMain,
      );

  static TextStyle get searchHint => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: KarigarDirectoryColors.textHint,
      );

  static TextStyle get emptyTitle => GoogleFonts.manrope(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: KarigarDirectoryColors.textBody,
      );

  static TextStyle get emptySubtitle => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: KarigarDirectoryColors.textMuted,
      );

  static TextStyle get shellTitle => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: KarigarDirectoryColors.shellTextTitle,
        letterSpacing: 0.3,
      );
}
