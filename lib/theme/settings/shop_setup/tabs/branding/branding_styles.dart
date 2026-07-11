// -----------------------------------------------------------------------------
// FILE: branding_styles.dart
// TYPE: Theme Layer / Styles & Dimensions
// AUTHOR: Senior System Architect
// DESCRIPTION: 100% Centralized typography, spacing, sizing, and decorations.
//              Keeps the UI layer completely free of hardcoded styling logic.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // 🚀 UPGRADE: Moved from UI
import 'branding_colors.dart';

class BrandingStyles {
  // Private constructor
  BrandingStyles._();

  // --- Dimensions & Spacing (Extracted from UI) ---
  static const double spacePageTitle = 30.0;
  static const double spaceCardGap = 24.0;
  static const double spaceFieldGap = 16.0;
  static const double spaceIconText = 12.0;
  static const double spaceBtnIconText = 6.0;

  static const double dividerHeight = 40.0;
  static const double dividerThickness = 1.0;
  static const double desktopBreakpoint = 1000.0;

  // --- Sizes (Extracted from UI) ---
  static const double iconHeaderSize = 22.0;
  static const double iconInputSize = 20.0;
  static const double iconBtnSize = 16.0;
  static const double strokeLoader = 2.0;
  static const double hInputField = 50.0;

  // --- Paddings (Extracted from UI) ---
  static const EdgeInsets padPageBottom = EdgeInsets.only(bottom: 50.0);
  static const EdgeInsets padIconBg = EdgeInsets.all(8.0);
  static const EdgeInsets padBtnPill =
      EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0);
  static const EdgeInsets padInputInner =
      EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets padCardInternal = EdgeInsets.all(24.0);

  // --- Text Sizes ---
  static const double szPageTitle = 24.0;
  static const double szPageSub = 14.0;
  static const double szSectionTitle = 16.0;
  static const double szSectionSub = 11.0;
  static const double szFieldLabel = 13.0;
  static const double szFieldText = 15.0;
  static const double szFieldHint = 13.0;
  static const double szBtnText = 12.0;

  // --- Radii ---
  static const double rCard = 12.0;
  static const double rInput = 8.0;
  static const double rInputRadius = 8.0;
  static const double rHeaderIcon = 8.0;
  static const double rBtn = 6.0;
  static const double rStatusPill = 20.0;

  // --- 🚀 UPGRADE: Pre-Compiled TextStyles (Extracted GoogleFonts from UI) ---
  static TextStyle get textPageTitle => GoogleFonts.manrope(
        fontSize: szPageTitle,
        fontWeight: FontWeight.w800,
        color: BrandingColors.textWhite,
        letterSpacing: -0.5,
      );

  static TextStyle get textPageSub => GoogleFonts.inter(
        fontSize: szPageSub,
        color: BrandingColors.textWhite70,
      );

  static TextStyle get textSectionTitle => GoogleFonts.manrope(
        fontSize: szSectionTitle,
        fontWeight: FontWeight.w700,
        color: BrandingColors.textDark,
      );

  static TextStyle get textBtnStatusLocked => GoogleFonts.inter(
        fontSize: szBtnText,
        fontWeight: FontWeight.w700,
        color: BrandingColors.textMuted,
      );

  static TextStyle get textBtnStatusActive => GoogleFonts.inter(
        fontSize: szBtnText,
        fontWeight: FontWeight.w700,
        color: BrandingColors.statusActiveText,
      );

  static TextStyle get textLabel => GoogleFonts.manrope(
        fontSize: szFieldLabel,
        fontWeight: FontWeight.w700,
        color: BrandingColors.textBody,
      );

  static TextStyle textInput(bool isLink, Color? brandColor) =>
      GoogleFonts.manrope(
        fontSize: szFieldText,
        fontWeight: FontWeight.w700,
        color: isLink
            ? (brandColor ?? BrandingColors.textDark)
            : BrandingColors.textDark,
        decoration: isLink ? TextDecoration.underline : TextDecoration.none,
      );

  static TextStyle get textHint => GoogleFonts.inter(
        color: BrandingColors.textHint,
        fontSize: szFieldHint,
      );

  // --- Decorations ---
  static BoxDecoration cardDecoration = BoxDecoration(
    color: BrandingColors.cardBg,
    borderRadius: BorderRadius.circular(rCard),
    border: Border.all(color: BrandingColors.borderLight, width: 1),
    boxShadow: const [
      BoxShadow(
        color: BrandingColors.shadowSubtle,
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration inputDecoration(bool isLocked) {
    return BoxDecoration(
      color: isLocked ? BrandingColors.inputBgLocked : BrandingColors.inputBg,
      borderRadius: BorderRadius.circular(rInput),
      border: Border.all(
        color: BrandingColors.borderLight,
        width: 1,
      ),
    );
  }

  static BoxDecoration activeInputDecoration = BoxDecoration(
      color: BrandingColors.inputBg,
      borderRadius: BorderRadius.circular(rInput),
      border: Border.all(
        color: BrandingColors.goldAccent,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: BrandingColors
              .goldAccentLight, // Fixed: Using pre-calculated opacity from colors
          blurRadius: 8,
          offset: const Offset(0, 2),
        )
      ]);
}
