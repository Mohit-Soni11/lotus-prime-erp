// -----------------------------------------------------------------------------
// FILE: customer_profile_styles.dart
// MODULE: Customer -> Customer Profile
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'customer_profile_colors.dart';

class CustomerProfileStyles {
  CustomerProfileStyles._();

  // Dimensions
  static const double appBarHeight = 70.0;
  static const double avatarSize = 80.0;
  static const double actionBtnH = 56.0;
  static const double cardRadius = 16.0;
  static const double sectionIconBox = 38.0;

  // Spacing
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 20, 20, 40);
  static const EdgeInsets cardPadding = EdgeInsets.all(20);

  // App bar
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

  // Avatar and name
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

  // Section header
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

  // Information rows
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

  // Account snapshot metrics
  static TextStyle get snapshotAmount => GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: CustomerProfileColors.bodyTextMain,
        height: 1.0,
      );

  static TextStyle get snapshotLabel => GoogleFonts.inter(
        fontSize: 11,
        color: CustomerProfileColors.bodyTextMuted,
      );

  static TextStyle get snapshotMeta => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: CustomerProfileColors.bodyTextMuted,
      );

  // Action button
  static TextStyle get actionBtnText => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
      );

  // Bill card
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

  // Decorations
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: CustomerProfileColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: CustomerProfileColors.bodyBorder),
        boxShadow: const [
          BoxShadow(
            color: CustomerProfileColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      );

  static BoxDecoration get avatarDecoration => BoxDecoration(
        color: CustomerProfileColors.brandGoldBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: CustomerProfileColors.brandGold.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: CustomerProfileColors.brandGold.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );
}
