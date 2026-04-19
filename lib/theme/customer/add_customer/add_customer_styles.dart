// -----------------------------------------------------------------------------
// FILE: add_customer_styles.dart
// MODULE: Customer → Add New Customer
// -----------------------------------------------------------------------------
 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_customer_colors.dart';
 
class AddCustomerStyles {
  AddCustomerStyles._();
 
  // ── DIMENSIONS ───────────────────────────────────────────────────────────
  static const double appBarHeight     = 70.0;
  static const double inputHeight      = 52.0;
  static const double cardRadius       = 16.0;
  static const double inputRadius      = 10.0;
  static const double sectionIconSize  = 20.0;
  static const double sectionIconBox   = 38.0;
 
  // ── SPACING ──────────────────────────────────────────────────────────────
  static const EdgeInsets pagePadding    = EdgeInsets.fromLTRB(20, 20, 20, 100);
  static const EdgeInsets cardPadding    = EdgeInsets.all(20.0);
  static const EdgeInsets fieldGap       = EdgeInsets.only(bottom: 16.0);
  static const EdgeInsets sectionGap     = EdgeInsets.only(bottom: 20.0);
 
  // ── APP BAR TYPOGRAPHY ───────────────────────────────────────────────────
  static TextStyle get appBarTitle => GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AddCustomerColors.shellTextTitle,
    letterSpacing: 0.8,
  );
 
  static TextStyle get appBarSubtitle => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AddCustomerColors.brandGold,
    letterSpacing: 1.5,
  );
 
  static const TextStyle systemOnlineText = TextStyle(
    color: Color(0xFF10B981),
    fontSize: 9.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );
 
  // ── SECTION HEADER ───────────────────────────────────────────────────────
  static TextStyle get sectionTitle => GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AddCustomerColors.bodyTextMain,
  );
 
  static TextStyle get sectionSubtitle => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: AddCustomerColors.bodyTextMuted,
    letterSpacing: 1.2,
  );
 
  // ── FIELD LABEL ──────────────────────────────────────────────────────────
  static TextStyle get fieldLabel => GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AddCustomerColors.inputLabel,
  );
 
  static TextStyle get fieldLabelRequired => GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AddCustomerColors.inputLabel,
  );
 
  // ── FIELD INPUT ──────────────────────────────────────────────────────────
  static TextStyle get fieldText => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AddCustomerColors.inputText,
  );
 
  static TextStyle get fieldHint => GoogleFonts.inter(
    fontSize: 14,
    color: AddCustomerColors.inputHint,
  );
 
  // ── ERROR TEXT ───────────────────────────────────────────────────────────
  static TextStyle get errorText => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AddCustomerColors.error,
  );
 
  // ── CUSTOMER TYPE ─────────────────────────────────────────────────────────
  static TextStyle get typeTitle => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AddCustomerColors.bodyTextMain,
  );
 
  static TextStyle get typeSubtitle => GoogleFonts.inter(
    fontSize: 12,
    color: AddCustomerColors.bodyTextMuted,
  );
 
  // ── SAVE BUTTON ──────────────────────────────────────────────────────────
  static TextStyle get saveBtnText => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AddCustomerColors.saveBtnText,
    letterSpacing: 0.5,
  );
 
  // ── REQUIRED NOTE ────────────────────────────────────────────────────────
  static TextStyle get requiredNote => GoogleFonts.inter(
    fontSize: 12,
    color: AddCustomerColors.bodyTextMuted,
  );
 
  // ── DECORATIONS ──────────────────────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AddCustomerColors.bodyPanelBg,
    borderRadius: BorderRadius.circular(cardRadius),
    border: Border.all(color: AddCustomerColors.bodyBorder, width: 1),
    boxShadow: const [
      BoxShadow(
        color: AddCustomerColors.shadowLight,
        blurRadius: 10,
        offset: Offset(0, 3),
      ),
    ],
  );
 
  static BoxDecoration inputDecoration({bool isFocused = false, bool hasError = false}) {
    return BoxDecoration(
      color: isFocused ? AddCustomerColors.inputBgFocus : AddCustomerColors.inputBg,
      borderRadius: BorderRadius.circular(inputRadius),
      border: Border.all(
        color: hasError
            ? AddCustomerColors.error
            : isFocused
                ? AddCustomerColors.inputBorderFocus
                : AddCustomerColors.inputBorder,
        width: isFocused || hasError ? 1.5 : 1,
      ),
      boxShadow: isFocused
          ? [
              BoxShadow(
                color: AddCustomerColors.brandGold.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : hasError
              ? [
                  BoxShadow(
                    color: AddCustomerColors.error.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
    );
  }
 
  static BoxDecoration get typeActiveRegular => BoxDecoration(
    color: AddCustomerColors.regularActiveBg,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AddCustomerColors.regularActiveBorder, width: 1.5),
  );
 
  static BoxDecoration get typeActiveVip => BoxDecoration(
    color: AddCustomerColors.vipActiveBg,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AddCustomerColors.vipActiveBorder, width: 1.5),
  );
 
  static BoxDecoration get typeInactive => BoxDecoration(
    color: AddCustomerColors.inactiveToggleBg,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AddCustomerColors.bodyBorder, width: 1),
  );
}