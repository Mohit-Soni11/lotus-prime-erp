// -----------------------------------------------------------------------------
// FILE: customer_profile_styles.dart
// MODULE: Customer â†’ Customer Profile
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'customer_profile_colors.dart';

class CustomerProfileStyles {
  CustomerProfileStyles._();

  // â”€â”€ DIMENSIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const double appBarHeight = 70.0;
  static const double avatarSize = 80.0;
  static const double actionBtnH = 56.0;
  static const double cardRadius = 16.0;
  static const double sectionIconBox = 38.0;

  // â”€â”€ SPACING â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 20, 20, 40);
  static const EdgeInsets cardPadding = EdgeInsets.all(20);

  // â”€â”€ APP BAR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get appBarTitle => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: CustomerProfileColors.shellTextTitle,
        letterSpacing: 0.8,
      );

  static TextStyle get appBarSubtitle => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: CustomerProfileColors.brandGold,
        letterSpacing: 1.5,
      );

  static const TextStyle systemOnlineText = TextStyle(
    color: Color(0xFF10B981),
    fontSize: 9.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  // â”€â”€ AVATAR & NAME â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get avatarInitials => GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: CustomerProfileColors.brandGold,
      );

  static TextStyle get customerName => GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: CustomerProfileColors.bodyTextMain,
        letterSpacing: -0.3,
      );

  static TextStyle get customerMobile => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: CustomerProfileColors.bodyTextMuted,
      );

  // â”€â”€ SECTION HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get sectionTitle => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: CustomerProfileColors.bodyTextMain,
      );

  static TextStyle get sectionSubtitle => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: CustomerProfileColors.bodyTextMuted,
        letterSpacing: 1.2,
      );

  // â”€â”€ INFO ROWS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get infoLabel => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: CustomerProfileColors.bodyTextMuted,
      );

  static TextStyle get infoValue => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: CustomerProfileColors.bodyTextMain,
      );

  // â”€â”€ CREDIT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get creditAmount => GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: CustomerProfileColors.bodyTextMain,
        height: 1.0,
      );

  static TextStyle get creditLabel => GoogleFonts.inter(
        fontSize: 11,
        color: CustomerProfileColors.bodyTextMuted,
      );

  static TextStyle get creditPct => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: CustomerProfileColors.bodyTextMuted,
      );

  // â”€â”€ ACTION BUTTON â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get actionBtnText => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
      );

  // â”€â”€ BILL CARD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get billNo => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: CustomerProfileColors.bodyTextMain,
        letterSpacing: 0.3,
      );

  static TextStyle get billAmount => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: CustomerProfileColors.brandGold,
      );

  static TextStyle get billDate => GoogleFonts.inter(
        fontSize: 11,
        color: CustomerProfileColors.bodyTextMuted,
      );

  // â”€â”€ DECORATIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: CustomerProfileColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: CustomerProfileColors.bodyBorder),
        boxShadow: const [
          BoxShadow(
              color: CustomerProfileColors.shadowLight,
              blurRadius: 10,
              offset: Offset(0, 3)),
        ],
      );

  static BoxDecoration get avatarDecoration => BoxDecoration(
        color: CustomerProfileColors.brandGoldBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: CustomerProfileColors.brandGold.withValues(alpha: 0.4),
            width: 2),
        boxShadow: [
          BoxShadow(
            color: CustomerProfileColors.brandGold.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );
}
