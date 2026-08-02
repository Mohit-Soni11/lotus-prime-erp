import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'supplier_profile_colors.dart';

class SupplierProfileStyles {
  SupplierProfileStyles._();

  static const double appBarHeight = 70.0;
  static const double avatarSize = 80.0;
  static const double cardRadius = 16.0;
  static const double actionButtonHeight = 56.0;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 20, 20, 40);
  static const EdgeInsets cardPadding = EdgeInsets.all(20);

  static TextStyle get appBarTitle => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: SupplierProfileColors.shellTextTitle,
        letterSpacing: 0,
      );

  static TextStyle get appBarSubtitle => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: SupplierProfileColors.brandGold,
        letterSpacing: 0,
      );

  static const TextStyle systemOnlineText = TextStyle(
    color: SupplierProfileColors.onlineGreen,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );

  static TextStyle get supplierName => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: SupplierProfileColors.bodyTextMain,
        letterSpacing: 0,
      );

  static TextStyle get supplierMeta => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: SupplierProfileColors.bodyTextMuted,
        letterSpacing: 0,
      );

  static TextStyle get sectionTitle => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: SupplierProfileColors.bodyTextMain,
        letterSpacing: 0,
      );

  static TextStyle get sectionSubtitle => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: SupplierProfileColors.bodyTextMuted,
        letterSpacing: 0,
      );

  static TextStyle get infoLabel => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: SupplierProfileColors.bodyTextMuted,
        letterSpacing: 0,
      );

  static TextStyle get infoValue => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: SupplierProfileColors.bodyTextMain,
        letterSpacing: 0,
      );

  static TextStyle get statValue => GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: SupplierProfileColors.bodyTextMain,
        height: 1.0,
        letterSpacing: 0,
      );

  static TextStyle get statLabel => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: SupplierProfileColors.bodyTextMuted,
        letterSpacing: 0,
      );

  static TextStyle get chipText => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      );

  static TextStyle get historyTitle => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: SupplierProfileColors.bodyTextMain,
        letterSpacing: 0,
      );

  static TextStyle get historyMeta => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: SupplierProfileColors.bodyTextMuted,
        letterSpacing: 0,
      );

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: SupplierProfileColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: SupplierProfileColors.bodyBorder),
        boxShadow: const [
          BoxShadow(
            color: SupplierProfileColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get softPanelDecoration => BoxDecoration(
        color: SupplierProfileColors.purchaseBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SupplierProfileColors.purchaseBorder),
      );

  static BoxDecoration tintedPanel(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      );
}
