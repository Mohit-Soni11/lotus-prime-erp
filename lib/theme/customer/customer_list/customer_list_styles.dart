// -----------------------------------------------------------------------------
// FILE: customer_list_styles.dart
// MODULE: Customer → Customer List
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'customer_list_colors.dart';

class CustomerListStyles {
  CustomerListStyles._();

  static const double appBarHeight = 70.0;
  static const double searchBarHeight = 52.0;
  static const double filterBarHeight = 48.0;
  static const double cardBorderRadius = 16.0;
  static const double chipBorderRadius = 20.0;
  static const double avatarSize = 52.0;

  static const EdgeInsets cardPaddingH =
      EdgeInsets.symmetric(horizontal: 20, vertical: 18);
  static const EdgeInsets chipPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  // ── TYPOGRAPHY (Updated to Premium Style) ────────────────────────────────
  static TextStyle get appBarTitle => GoogleFonts.inter(
        fontSize: 18, // Changed to 18
        fontWeight: FontWeight.w700,
        color: CustomerListColors.shellTextTitle,
        letterSpacing: 1.2, // Changed to 1.2
      );

  static const TextStyle systemOnlineText = TextStyle(
    color: CustomerListColors.onlineGreen,
    fontSize: 12.0, // Changed to 12.0
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static TextStyle get statsValue => GoogleFonts.manrope(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: CustomerListColors.bodyTextMain,
      height: 1.0);
  static TextStyle get statsLabel => GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: CustomerListColors.bodyTextMuted,
      letterSpacing: 0.5);

  static TextStyle get searchText => GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: CustomerListColors.bodyTextMain);
  static TextStyle get searchHint =>
      GoogleFonts.inter(fontSize: 14, color: CustomerListColors.bodyTextMuted);

  static TextStyle get chipActive => GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: CustomerListColors.chipActive);
  static TextStyle get chipInactive => GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: CustomerListColors.chipInactive);

  static TextStyle get customerName => GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: CustomerListColors.bodyTextMain);
  static TextStyle get customerMobile => GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: CustomerListColors.bodyTextMain,
      letterSpacing: 0.5);
  static TextStyle get customerDetail => GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: CustomerListColors.bodyTextMuted);
  static TextStyle get customerSince => GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: CustomerListColors.bodyTextMuted);

  static TextStyle get invoiceCount => GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: CustomerListColors.bodyTextMain);
  static TextStyle get invoiceLabel => GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: CustomerListColors.bodyTextMuted);

  static TextStyle get vipBadge => GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: CustomerListColors.vipBadgeText,
      letterSpacing: 0.8);
  static TextStyle get regularBadge => GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: CustomerListColors.regularBadgeText,
      letterSpacing: 0.5);

  static TextStyle get emptyTitle => GoogleFonts.manrope(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: CustomerListColors.bodyTextMain);
  static TextStyle get emptySubtitle => GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: CustomerListColors.bodyTextMuted);

  // ── DECORATIONS ──────────────────────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: CustomerListColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(
            color: CustomerListColors.bodyBorder.withOpacity(0.5), width: 1),
        boxShadow: const [
          BoxShadow(
              color: CustomerListColors.shadowLight,
              blurRadius: 12,
              offset: Offset(0, 4))
        ],
      );

  static BoxDecoration get cardDecorationHover => BoxDecoration(
        color: CustomerListColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: CustomerListColors.brandGold, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: CustomerListColors.brandGold.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      );

  static BoxDecoration get searchDecoration => BoxDecoration(
        color: CustomerListColors.searchBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomerListColors.searchBorder, width: 1),
        boxShadow: const [
          BoxShadow(
              color: CustomerListColors.shadowLight,
              blurRadius: 10,
              offset: Offset(0, 2))
        ],
      );

  static BoxDecoration get statsCardDecoration => BoxDecoration(
        color: CustomerListColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: CustomerListColors.bodyBorder.withOpacity(0.5), width: 1),
        boxShadow: const [
          BoxShadow(
              color: CustomerListColors.shadowLight,
              blurRadius: 15,
              offset: Offset(0, 6))
        ],
      );
}
