// =============================================================================
// FILE        : lib/theme/settings/billing_setup/billing_setup_styles.dart
// MODULE      : Billing Setup
// LAYER       : Theme / Styles
// DESCRIPTION : Typography, decorations, dimensions â€” mirrors KarigarStyles.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'billing_setup_colors.dart';

class BillingSetupStyles {
  BillingSetupStyles._();

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // TYPOGRAPHY
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  static TextStyle get shellTitle => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: BillingSetupColors.shellTextTitle,
        letterSpacing: 0.8,
      );

  static TextStyle get sectionTitle => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: BillingSetupColors.textDark,
        letterSpacing: 0.2,
      );

  static TextStyle get fieldLabel => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: BillingSetupColors.textBody,
        letterSpacing: 0.1,
      );

  static TextStyle get fieldInput => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: BillingSetupColors.textDark,
      );

  static TextStyle get fieldHint => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: BillingSetupColors.textHint,
      );

  static TextStyle get sectionLabel => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        color: BillingSetupColors.textMuted,
        letterSpacing: 1.2,
      );

  // â”€â”€ APP BAR TYPOGRAPHY â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static TextStyle get appBarTitle => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: BillingSetupColors.shellTextTitle,
        letterSpacing: 1.2,
      );

  static TextStyle get appBarSubtitle => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: BillingSetupColors.shellTextMuted,
        letterSpacing: 0.2,
      );

  static TextStyle get systemOnlineText => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: BillingSetupColors.onlineGreen,
        letterSpacing: 0.5,
      );

  static TextStyle get moduleBadgeTitle => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: BillingSetupColors.brandGold,
        letterSpacing: 0.6,
      );

  static TextStyle get moduleBadgeSub => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: BillingSetupColors.shellTextMuted,
      );

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // DIMENSIONS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  static const double appBarHeight = 70.0;
  static const double inputHeight = 52.0;
  static const double dropdownHeight = 52.0;
  static const double rCard = 16.0;
  static const double rInput = 10.0;
  static const double rBtn = 8.0;
  static const double rStatusPill = 20.0;
  static const double rHeaderIcon = 8.0;

  static const EdgeInsets cardPadding = EdgeInsets.all(24);
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 0, 20, 50);

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // DECORATIONS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  // Dark shell â€” exact KarigarStyles.shellDecoration
  static const BoxDecoration shellDecoration = BoxDecoration(
    color: BillingSetupColors.shellPanelBg,
    border: Border(
      bottom: BorderSide(color: BillingSetupColors.shellBorder, width: 1),
    ),
  );

  // Section card
  static BoxDecoration get sectionCard => BoxDecoration(
        color: BillingSetupColors.cardBg,
        borderRadius: BorderRadius.circular(rCard),
        border: Border.all(color: BillingSetupColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: BillingSetupColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      );

  // Hub card (4 module cards)
  static BoxDecoration hubCard({
    required Color accent,
    required bool hovered,
  }) =>
      BoxDecoration(
        color: BillingSetupColors.cardBg,
        borderRadius: BorderRadius.circular(rCard),
        border: Border.all(
          color: hovered
              ? accent.withValues(alpha: 0.7)
              : BillingSetupColors.cardBorder,
          width: hovered ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: hovered
                ? accent.withValues(alpha: 0.15)
                : BillingSetupColors.shadowLight,
            blurRadius: hovered ? 20 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // Input normal/locked
  static BoxDecoration inputDecoration(bool isLocked) => BoxDecoration(
        color: isLocked
            ? BillingSetupColors.inputBgLocked
            : BillingSetupColors.inputBg,
        borderRadius: BorderRadius.circular(rInput),
        border: Border.all(
          color: BillingSetupColors.cardBorder,
          width: 1,
        ),
      );

  // Input focused â€” gold glow
  static BoxDecoration get inputActive => BoxDecoration(
        color: BillingSetupColors.inputBg,
        borderRadius: BorderRadius.circular(rInput),
        border: Border.all(
          color: BillingSetupColors.goldAccent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: BillingSetupColors.goldAccent.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // Section icon box
  static BoxDecoration sectionIconBox(Color accent) => BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(rHeaderIcon),
      );

  // Status pill
  static BoxDecoration statusPill(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(rStatusPill),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      );
}
