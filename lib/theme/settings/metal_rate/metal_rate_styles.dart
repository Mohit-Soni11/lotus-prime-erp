// =============================================================================
// FILE        : lib/theme/settings/metal_rate/metal_rate_styles.dart
// MODULE      : Metal Rate Setting
// LAYER       : Theme / Styles
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'metal_rate_colors.dart';

class MetalRateStyles {
  MetalRateStyles._();

  static const double appBarHeight = 72.0;
  static const double rCard = 14.0;
  static const double rInner = 9.0;
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 26, 20, 50);

  static TextStyle get appBarTitle => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: MetalRateColors.shellTextTitle,
        letterSpacing: 0.5,
      );

  static TextStyle get appBarSubtitle => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: MetalRateColors.shellTextMuted,
      );

  static TextStyle get systemOnline => GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: MetalRateColors.onlineGreen,
        letterSpacing: 1.0,
      );

  static TextStyle get sectionLabel => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: MetalRateColors.textMuted,
        letterSpacing: 1.15,
      );

  static TextStyle get cardTitle => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: MetalRateColors.textDark,
      );

  static TextStyle get cardSubtitle => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: MetalRateColors.textBody,
        height: 1.35,
      );

  static TextStyle get smallLabel => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: MetalRateColors.textMuted,
        letterSpacing: 0.3,
      );

  static TextStyle get metricValue => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: MetalRateColors.textDark,
      );

  static BoxDecoration get shellDecoration => const BoxDecoration(
        color: MetalRateColors.shellPanelBg,
        border: Border(
          bottom: BorderSide(color: MetalRateColors.shellBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration panel({Color? borderColor}) => BoxDecoration(
        color: MetalRateColors.cardBg,
        borderRadius: BorderRadius.circular(rCard),
        border: Border.all(color: borderColor ?? MetalRateColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: MetalRateColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration softPanel(Color accent) => BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(rInner),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      );

  static BoxDecoration get fieldBox => BoxDecoration(
        color: MetalRateColors.inputBg,
        borderRadius: BorderRadius.circular(rInner),
        border: Border.all(color: MetalRateColors.cardBorder),
      );

  static BoxDecoration metalCard({
    required Color accent,
    required bool hovered,
  }) =>
      BoxDecoration(
        color: MetalRateColors.cardBg,
        borderRadius: BorderRadius.circular(rCard),
        border: Border.all(
          color: hovered
              ? accent.withValues(alpha: 0.65)
              : MetalRateColors.cardBorder,
          width: hovered ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: hovered
                ? accent.withValues(alpha: 0.16)
                : MetalRateColors.shadowLight,
            blurRadius: hovered ? 22 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      );
}
