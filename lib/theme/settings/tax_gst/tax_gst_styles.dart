// ============================================================
// FILE    : lib/theme/settings/tax_gst/tax_gst_styles.dart
// MODULE  : Tax & GST Configuration
// AUTHOR  : Lotus Prime ERP
// VERSION : 1.0.0
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tax_gst_colors.dart';

/// All TextStyles, InputDecorations, BoxDecorations & layout
/// constants for the Tax & GST module. Zero styling hardcoded in UI.
abstract final class TaxGstStyles {
  TaxGstStyles._();

  // ── Animation Durations ──────────────────────────────────────
  static const Duration animFast        = Duration(milliseconds: 180);
  static const Duration animNormal      = Duration(milliseconds: 280);
  static const Duration animSlow        = Duration(milliseconds: 420);
  static const Duration animPulse       = Duration(seconds: 2);

  // ── Border Radii ─────────────────────────────────────────────
  static const double radiusCard        = 18.0;
  static const double radiusSection     = 16.0;
  static const double radiusInput       = 11.0;
  static const double radiusButton      = 10.0;
  static const double radiusTag         = 24.0;
  static const double radiusBadge       = 7.0;
  static const double radiusBanner      = 13.0;
  static const double radiusIconBox     = 12.0;
  static const double radiusChip        = 8.0;
  static const double radiusAppBar      = 0.0;

  // ── Dimensions ───────────────────────────────────────────────
  static const double appBarHeight      = 70.0;
  static const double iconBoxSize       = 44.0;
  static const double iconBoxSizeSmall  = 34.0;
  static const double moduleIconSize    = 30.0;
  static const double cardIconSize      = 22.0;
  static const double sectionIconSize   = 18.0;
  static const double fieldIconSize     = 17.0;

  // ── Spacing ───────────────────────────────────────────────────
  static const double spaceXS           = 4.0;
  static const double spaceSM           = 8.0;
  static const double spaceMD           = 12.0;
  static const double spaceLG           = 16.0;
  static const double spaceXL           = 20.0;
  static const double space2XL          = 24.0;
  static const double space3XL          = 32.0;
  static const double fieldGapV         = 14.0;
  static const double fieldGapH         = 12.0;
  static const double cardGap           = 12.0;
  static const double sectionGap        = 20.0;

  // ── Padding ──────────────────────────────────────────────────
  static const EdgeInsets pageInsets    = EdgeInsets.symmetric(horizontal: 20, vertical: 24);
  static const EdgeInsets cardPadding   = EdgeInsets.all(20);
  static const EdgeInsets sectionPad    = EdgeInsets.all(20);
  static const EdgeInsets fieldPadding  = EdgeInsets.symmetric(horizontal: 14, vertical: 14);
  static const EdgeInsets chipPadding   = EdgeInsets.symmetric(horizontal: 10, vertical: 4);
  static const EdgeInsets bannerPadding = EdgeInsets.all(14);
  static const EdgeInsets btnPadding    = EdgeInsets.symmetric(horizontal: 14, vertical: 8);

  // ── AppBar Text ──────────────────────────────────────────────
  static TextStyle appBarTitle(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w700,
    color: TaxGstColors.shellTitleText, letterSpacing: -0.3,
  );

  static TextStyle appBarSubtitle(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 10, fontWeight: FontWeight.w600,
    color: TaxGstColors.onlinePulse, letterSpacing: 0.8,
  );

  // ── Hub Screen Labels ────────────────────────────────────────
  static TextStyle sectionLabel(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w700,
    color: TaxGstColors.textMuted, letterSpacing: 1.2,
  );

  // ── Card ─────────────────────────────────────────────────────
  static TextStyle cardTitle(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w700,
    color: TaxGstColors.textPrimary, letterSpacing: -0.2,
  );

  static TextStyle cardSubtitle(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 11.5, fontWeight: FontWeight.w400,
    color: TaxGstColors.textMuted, height: 1.5,
  );

  static TextStyle cardTagText(BuildContext ctx, {required Color color}) =>
      GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w600,
        color: color, letterSpacing: 0.3,
      );

  // ── Section Panel ─────────────────────────────────────────────
  static TextStyle sectionTitle(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w700,
    color: TaxGstColors.textPrimary, letterSpacing: -0.3,
  );

  static TextStyle sectionSubtitle(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 11.5, fontWeight: FontWeight.w400,
    color: TaxGstColors.textMuted, height: 1.5,
  );

  // ── Fields ───────────────────────────────────────────────────
  static TextStyle fieldLabel(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 11.5, fontWeight: FontWeight.w600,
    color: TaxGstColors.textSecondary, letterSpacing: 0.1,
  );

  static TextStyle inputText(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 13.5, fontWeight: FontWeight.w500,
    color: TaxGstColors.textPrimary,
  );

  static TextStyle inputHintText(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: TaxGstColors.textHint,
  );

  static TextStyle inputErrorText(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: TaxGstColors.statusDanger,
  );

  // ── Toggle Row ───────────────────────────────────────────────
  static TextStyle toggleTitle(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: TaxGstColors.textPrimary,
  );

  static TextStyle toggleSubtitle(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w400,
    color: TaxGstColors.textMuted, height: 1.4,
  );

  // ── HSN Table ─────────────────────────────────────────────────
  static TextStyle hsnTableHeader(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 10, fontWeight: FontWeight.w700,
    color: TaxGstColors.textMuted, letterSpacing: 0.9,
  );

  static TextStyle hsnCategory(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 12.5, fontWeight: FontWeight.w600,
    color: TaxGstColors.textPrimary,
  );

  static TextStyle hsnCode(BuildContext ctx) => GoogleFonts.sourceCodePro(
    fontSize: 12, fontWeight: FontWeight.w500,
    color: TaxGstColors.textSecondary,
  );

  static TextStyle hsnRate(BuildContext ctx, {required Color color}) =>
      GoogleFonts.inter(
        fontSize: 11.5, fontWeight: FontWeight.w700, color: color,
      );

  // ── Info Banner ───────────────────────────────────────────────
  static TextStyle infoBannerText(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w400,
    color: TaxGstColors.textSecondary, height: 1.6,
  );

  // ── Sync Banner ───────────────────────────────────────────────
  static TextStyle syncBannerTitle(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 12.5, fontWeight: FontWeight.w700,
    color: TaxGstColors.accentPrimary,
  );

  static TextStyle syncBannerBody(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 11.5, fontWeight: FontWeight.w400,
    color: TaxGstColors.textSecondary, height: 1.5,
  );

  static TextStyle syncBannerTag(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 9.5, fontWeight: FontWeight.w700,
    color: TaxGstColors.accentPrimary, letterSpacing: 0.8,
  );

  // ── Button Text ──────────────────────────────────────────────
  static TextStyle btnText(BuildContext ctx, {required Color color}) =>
      GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w700, color: color,
      );

  static TextStyle badgeText(BuildContext ctx) => GoogleFonts.inter(
    fontSize: 10, fontWeight: FontWeight.w700,
    color: TaxGstColors.shellBadgeText, letterSpacing: 0.8,
  );

  // ── InputDecoration factory ───────────────────────────────────
  static InputDecoration inputDecoration(
    BuildContext ctx, {
    required String labelText,
    required String hintText,
    IconData? prefixIcon,
    required Color accentColor,
    bool isLocked = false,
    bool hasError = false,
    String? errorText,
    Widget? suffixWidget,
  }) {
    final borderColor = hasError
        ? TaxGstColors.statusDanger
        : isLocked
            ? TaxGstColors.inputBorder
            : accentColor;

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      labelStyle: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: isLocked ? TaxGstColors.textDisabled : TaxGstColors.textMuted,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w400,
        color: TaxGstColors.textHint,
      ),
      errorStyle: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: TaxGstColors.statusDanger,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              size: fieldIconSize,
              color: isLocked ? TaxGstColors.textDisabled : accentColor,
            )
          : null,
      suffixIcon: suffixWidget,
      filled: true,
      fillColor: isLocked ? TaxGstColors.inputSurfaceLocked : TaxGstColors.inputSurface,
      contentPadding: fieldPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: BorderSide(color: TaxGstColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: BorderSide(color: TaxGstColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: BorderSide(color: borderColor, width: 1.8),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: BorderSide(color: TaxGstColors.inputBorder.withOpacity(0.6)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: BorderSide(color: TaxGstColors.statusDanger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInput),
        borderSide: BorderSide(color: TaxGstColors.statusDanger, width: 2),
      ),
    );
  }

  // ── BoxDecoration factories ───────────────────────────────────

  static BoxDecoration cardDecoration({
    required Color accentColor,
    bool isHovered = false,
    bool isExpanded = false,
  }) {
    final active = isHovered || isExpanded;
    return BoxDecoration(
      color: TaxGstColors.cardSurface,
      borderRadius: BorderRadius.circular(radiusCard),
      border: Border.all(
        color: active ? accentColor.withOpacity(0.4) : TaxGstColors.cardBorder,
        width: active ? 1.6 : 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: active ? accentColor.withOpacity(0.10) : Colors.black.withOpacity(0.05),
          blurRadius: active ? 24 : 8,
          spreadRadius: active ? 0 : 0,
          offset: const Offset(0, 4),
        ),
        if (active)
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: 48,
            offset: const Offset(0, 8),
          ),
      ],
    );
  }

  static BoxDecoration sectionPanelDecoration(Color accentColor) => BoxDecoration(
    color: TaxGstColors.cardSurface,
    borderRadius: BorderRadius.circular(radiusSection),
    border: Border.all(color: accentColor.withOpacity(0.22), width: 1),
    boxShadow: [
      BoxShadow(
        color: accentColor.withOpacity(0.07),
        blurRadius: 16,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static BoxDecoration iconBoxDecoration(Color accentColor) => BoxDecoration(
    color: accentColor.withOpacity(0.12),
    borderRadius: BorderRadius.circular(radiusIconBox),
    border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
  );

  static BoxDecoration tagDecoration(Color accentColor) => BoxDecoration(
    color: accentColor.withOpacity(0.10),
    borderRadius: BorderRadius.circular(radiusTag),
    border: Border.all(color: accentColor.withOpacity(0.22), width: 1),
  );

  static BoxDecoration syncBannerDecoration() => BoxDecoration(
    color: TaxGstColors.accentPrimary.withOpacity(0.08),
    borderRadius: BorderRadius.circular(radiusBanner),
    border: Border.all(color: TaxGstColors.accentPrimaryBorder),
    boxShadow: [
      BoxShadow(
        color: TaxGstColors.accentPrimary.withOpacity(0.06),
        blurRadius: 12,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration infoBannerDecoration(Color accentColor) => BoxDecoration(
    color: accentColor.withOpacity(0.06),
    borderRadius: BorderRadius.circular(radiusBanner),
    border: Border.all(color: accentColor.withOpacity(0.20)),
  );

  static BoxDecoration ratePillDecoration(Color accentColor) => BoxDecoration(
    color: accentColor.withOpacity(0.12),
    borderRadius: BorderRadius.circular(radiusTag),
    border: Border.all(color: accentColor.withOpacity(0.30)),
  );

  static BoxDecoration hsnRowDecoration(bool isEven) => BoxDecoration(
    color: isEven ? TaxGstColors.inputSurface : TaxGstColors.cardSurface,
    borderRadius: BorderRadius.circular(radiusChip),
    border: Border.all(color: TaxGstColors.cardBorder.withOpacity(0.6)),
  );

  static BoxDecoration btnDecoration({
    required Color color,
    bool isFilled = false,
    bool isHovered = false,
  }) =>
      BoxDecoration(
        color: isFilled
            ? color
            : isHovered
                ? color.withOpacity(0.14)
                : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(radiusButton),
        border: Border.all(color: color.withOpacity(isFilled ? 0 : 0.35)),
      );
}
