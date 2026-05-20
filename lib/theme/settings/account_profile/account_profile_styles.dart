// -----------------------------------------------------------------------------
// FILE: lib/theme/settings/account_profile/account_profile_styles.dart
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'account_profile_colors.dart';

class AccountProfileStyles {
  AccountProfileStyles._();

  static const double appBarHeight = 70.0;
  static const double cardRadius = 16.0;
  static const double sectionRadius = 12.0;
  static const double avatarSize = 110.0;
  static const double cameraIconSize = 36.0;

  // â”€â”€ APP BAR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get appBarTitle => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AccountProfileColors.shellTextTitle,
        letterSpacing: 0.8,
      );

  static const TextStyle systemOnlineText = TextStyle(
    color: Color(0xFF10B981),
    fontSize: 9.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  // â”€â”€ SECTION HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get sectionTitle => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AccountProfileColors.brandGold,
        letterSpacing: 1.2,
      );

  // â”€â”€ FIELD LABEL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get fieldLabel => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AccountProfileColors.bodyTextMuted,
        letterSpacing: 0.3,
      );

  static TextStyle get fieldValue => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AccountProfileColors.bodyTextMain,
      );

  // â”€â”€ NAME BELOW AVATAR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get avatarName => GoogleFonts.manrope(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AccountProfileColors.bodyTextMain,
      );

  static TextStyle get avatarEmail => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AccountProfileColors.bodyTextMuted,
      );

  // â”€â”€ INFO ROW â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get infoLabel => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AccountProfileColors.bodyTextMuted,
      );

  static TextStyle get infoValue => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AccountProfileColors.bodyTextMain,
      );

  // â”€â”€ BUTTON â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.3,
      );

  static TextStyle get buttonTextDark => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1E293B),
        letterSpacing: 0.3,
      );

  // â”€â”€ DECORATIONS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AccountProfileColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
            color: AccountProfileColors.bodyBorder.withValues(alpha: 0.6),
            width: 1),
        boxShadow: const [
          BoxShadow(
              color: AccountProfileColors.shadowLight,
              blurRadius: 12,
              offset: Offset(0, 4)),
        ],
      );

  static BoxDecoration get sectionDecoration => BoxDecoration(
        color: AccountProfileColors.brandGoldBg,
        borderRadius: BorderRadius.circular(sectionRadius),
        border: Border.all(color: AccountProfileColors.brandGoldBorder),
      );
}
