// -----------------------------------------------------------------------------
// FILE: tax_gst_styles.dart
// TYPE: Theme / Presentation (Step C)
// AUTHOR: Senior System Architect
// DESCRIPTION: Centralized typography, dimensions, and decorations.
//              Eliminates all hardcoded UI styling and layout parameters.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- CORE IMPORTS ---
// NOTE: Adjust this import path according to your folder structure.
import 'tax_gst_colors.dart';

class TaxGstStyles {
  TaxGstStyles._(); // Locked to prevent instantiation

  // --- Text Sizes ---
  static const double szPageTitle = 24.0;
  static const double szDialogTitle = 32.0;
  static const double szSectionTitle = 16.0;
  static const double szSectionSub = 11.0;
  static const double szFieldLabel = 13.0;
  static const double szFieldText = 15.0;
  static const double szFieldHint = 13.0;

  // --- Radii ---
  static const double rCard = 12.0;
  static const double rInput = 8.0;
  static const double rHeaderIcon = 8.0;
  static const double rBtn = 6.0;
  static const double rStatusPill = 20.0;
  static const double rBottomSheet = 20.0;
  static const double rDialog = 28.0;

  // --- Spacing & Dimensions (Extracted from UI) ---
  static const double hInputField = 50.0;
  static const EdgeInsets padCardInternal = EdgeInsets.all(24.0);
  static const EdgeInsets padPageBottom = EdgeInsets.only(bottom: 50.0);
  static const double gapSection = 30.0; // Between header and first card
  static const double gapCard = 24.0;    // Between form cards
  static const double gapInput = 16.0;   // Between input fields inside card

  // --- Typography / Text Styles (Extracted from UI) ---
  static TextStyle get pageTitle => GoogleFonts.manrope(fontSize: szPageTitle, fontWeight: FontWeight.w800, color: TaxGstColors.textDark, letterSpacing: -0.5);
  static TextStyle get pageSubtitle => GoogleFonts.inter(fontSize: 14.0, color: TaxGstColors.textMuted);
  static TextStyle get sectionTitle => GoogleFonts.manrope(fontSize: szSectionTitle, fontWeight: FontWeight.w700, color: TaxGstColors.textDark);
  static TextStyle get sectionSub => GoogleFonts.inter(fontSize: szSectionSub, fontWeight: FontWeight.w800, color: TaxGstColors.textMuted, letterSpacing: 1.2);
  
  static TextStyle get fieldLabel => GoogleFonts.manrope(fontSize: szFieldLabel, fontWeight: FontWeight.w700, color: TaxGstColors.textBody);
  static TextStyle get fieldText => GoogleFonts.manrope(fontSize: szFieldText, fontWeight: FontWeight.w700, color: TaxGstColors.textDark);
  static TextStyle get fieldHint => GoogleFonts.inter(fontSize: szFieldHint, color: TaxGstColors.textHint);
  
  static TextStyle get statusPill => GoogleFonts.inter(fontSize: 11.0, fontWeight: FontWeight.w700, color: TaxGstColors.statusActiveText, letterSpacing: 0.5);
  static TextStyle get dialogTitle => GoogleFonts.manrope(fontSize: szDialogTitle, fontWeight: FontWeight.w800, color: TaxGstColors.cardBg);

  // --- Decorations ---
  static BoxDecoration cardDecoration = BoxDecoration(
    color: TaxGstColors.cardBg,
    borderRadius: BorderRadius.circular(rCard),
    border: Border.all(color: TaxGstColors.borderLight, width: 1),
    boxShadow: [
      BoxShadow(
        color: TaxGstColors.overlayDark03, // Replaced hardcoded opacity
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration inputDecoration(bool isLocked) {
    return BoxDecoration(
      color: isLocked ? TaxGstColors.lockedBg : TaxGstColors.inputBg,
      borderRadius: BorderRadius.circular(rInput),
      border: Border.all(color: TaxGstColors.borderLight, width: 1),
    );
  }
  
  static BoxDecoration activeInputDecoration = BoxDecoration(
    color: TaxGstColors.inputBg,
    borderRadius: BorderRadius.circular(rInput),
    border: Border.all(color: TaxGstColors.goldAccent, width: 1.5),
    boxShadow: [
      BoxShadow(
        color: TaxGstColors.goldAccent10, // Replaced hardcoded opacity
        blurRadius: 8,
        offset: const Offset(0, 2),
      )
    ]
  );
  
  static BoxDecoration hsnInputDecoration(bool isLocked) => BoxDecoration(
    color: isLocked ? TaxGstColors.lockedBg : TaxGstColors.cardBg,
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: TaxGstColors.borderLight),
  );

  static BoxDecoration uploadZoneDecoration = BoxDecoration(
    color: TaxGstColors.uploadZoneBg,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: TaxGstColors.borderLight, width: 1),
  );
}