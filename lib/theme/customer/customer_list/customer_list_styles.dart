// -----------------------------------------------------------------------------
// FILE: customer_list_styles.dart
// MODULE: Customer -> Customer List
// DESCRIPTION: Typography, spacing, and decoration tokens.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'customer_list_colors.dart';

class CustomerListStyles {
  CustomerListStyles._();

  static const double appBarHeight = 70.0;
  static const double searchBarHeight = 52.0;
  static const double cardBorderRadius = 14.0;
  static const double chipBorderRadius = 22.0;
  static const double avatarSize = 54.0;

  static const EdgeInsets chipPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 9);

  static TextStyle get appBarTitle => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: CustomerListColors.shellTextTitle,
        letterSpacing: 1.2,
      );

  static TextStyle get pageTitle => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: CustomerListColors.bodyTextMain,
        height: 1.05,
      );

  static TextStyle get pageSubtitle => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: CustomerListColors.bodyTextMain,
      );

  static TextStyle get statsValue => GoogleFonts.manrope(
        fontSize: 25,
        fontWeight: FontWeight.w900,
        color: CustomerListColors.bodyTextMain,
        height: 1,
      );

  static TextStyle get statsLabel => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: CustomerListColors.bodyTextMain,
      );

  static TextStyle get statsCaption => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: CustomerListColors.bodyTextMain,
      );

  static TextStyle get searchText => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: CustomerListColors.bodyTextMain,
      );

  static TextStyle get searchHint => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: CustomerListColors.bodyTextMain,
      );

  static TextStyle get chipActive => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: CustomerListColors.bodyTextMain,
      );

  static TextStyle get chipInactive => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: CustomerListColors.bodyTextMain,
      );

  static TextStyle get toolbarButton => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: CustomerListColors.bodyTextMain,
      );

  static TextStyle get resultTitle => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: CustomerListColors.bodyTextMain,
      );

  static TextStyle get resultMeta => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: CustomerListColors.bodyTextMain,
      );

  static TextStyle get customerName => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: CustomerListColors.bodyTextMain,
      );

  static TextStyle get customerDetail => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: CustomerListColors.bodyTextMain,
      );

  static TextStyle get metricValue => GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: CustomerListColors.bodyTextMain,
      );

  static TextStyle get metricLabel => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: CustomerListColors.bodyTextMain,
      );

  static TextStyle get regularBadge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: CustomerListColors.bodyTextMain,
      );

  static TextStyle get emptyTitle => GoogleFonts.manrope(
        fontSize: 19,
        fontWeight: FontWeight.w900,
        color: CustomerListColors.bodyTextMain,
      );

  static TextStyle get emptySubtitle => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: CustomerListColors.bodyTextMain,
      );

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: CustomerListColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: CustomerListColors.bodyBorder),
        boxShadow: const [
          BoxShadow(
            color: CustomerListColors.shadowLight,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration get cardDecorationHover => BoxDecoration(
        color: CustomerListColors.cardHover,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: CustomerListColors.brandGold, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: CustomerListColors.brandGold.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      );

  static BoxDecoration get searchDecoration => BoxDecoration(
        color: CustomerListColors.searchBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomerListColors.searchBorder),
        boxShadow: const [
          BoxShadow(
            color: CustomerListColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get statsCardDecoration => BoxDecoration(
        color: CustomerListColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomerListColors.bodyBorder),
        boxShadow: const [
          BoxShadow(
            color: CustomerListColors.shadowLight,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      );
}
