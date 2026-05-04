// -----------------------------------------------------------------------------
// FILE: supplier_list_styles.dart
// MODULE: Supplier → Supplier List
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'supplier_list_colors.dart';

class SupplierListStyles {
  SupplierListStyles._();

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
        color: SupplierListColors.shellTextTitle,
        letterSpacing: 1.2, // Changed to 1.2
      );

  static const TextStyle systemOnlineText = TextStyle(
    color: SupplierListColors.onlineGreen, // Using theme color
    fontSize: 12.0, // Changed to 12.0
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5, // Changed to 0.5
  );

  static TextStyle get statsValue => GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: SupplierListColors.bodyTextMain,
        height: 1.0,
      );

  static TextStyle get statsLabel => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: SupplierListColors.bodyTextMuted,
        letterSpacing: 0.5,
      );

  static TextStyle get searchText => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: SupplierListColors.bodyTextMain,
      );

  static TextStyle get searchHint => GoogleFonts.inter(
        fontSize: 14,
        color: SupplierListColors.bodyTextMuted,
      );

  static TextStyle get chipActive => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: SupplierListColors.chipActive,
      );

  static TextStyle get chipInactive => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: SupplierListColors.chipInactive,
      );

  static TextStyle get supplierName => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: SupplierListColors.bodyTextMain,
      );

  static TextStyle get supplierMobile => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: SupplierListColors.bodyTextMain,
        letterSpacing: 0.5,
      );

  static TextStyle get supplierDetail => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: SupplierListColors.bodyTextMuted,
      );

  static TextStyle get supplierGst => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: SupplierListColors.bodyTextMuted,
      );

  static TextStyle get typeBadge => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: SupplierListColors.manufacturerText,
        letterSpacing: 0.8,
      );

  static TextStyle get emptyTitle => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: SupplierListColors.bodyTextMain,
      );

  static TextStyle get emptySubtitle => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: SupplierListColors.bodyTextMuted,
      );

  // ── DECORATIONS ──────────────────────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: SupplierListColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border:
            Border.all(color: SupplierListColors.bodyBorder.withOpacity(0.5)),
        boxShadow: const [
          BoxShadow(
              color: SupplierListColors.shadowLight,
              blurRadius: 12,
              offset: Offset(0, 4))
        ],
      );

  static BoxDecoration get cardDecorationHover => BoxDecoration(
        color: SupplierListColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: SupplierListColors.brandGold, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: SupplierListColors.brandGold.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      );

  static BoxDecoration get searchDecoration => BoxDecoration(
        color: SupplierListColors.searchBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SupplierListColors.searchBorder),
        boxShadow: const [
          BoxShadow(
              color: SupplierListColors.shadowLight,
              blurRadius: 10,
              offset: Offset(0, 2))
        ],
      );

  static BoxDecoration get statsCardDecoration => BoxDecoration(
        color: SupplierListColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: SupplierListColors.bodyBorder.withOpacity(0.5)),
        boxShadow: const [
          BoxShadow(
              color: SupplierListColors.shadowLight,
              blurRadius: 15,
              offset: Offset(0, 6))
        ],
      );
}
