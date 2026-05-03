// =============================================================================
// FILE        : lib/theme/settings/metal_costing/metal_costing_styles.dart
// MODULE      : Metal Costing Analysis
// LAYER       : Theme / Styles
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'metal_costing_colors.dart';

class MetalCostingStyles {
  MetalCostingStyles._();

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY
  // ═══════════════════════════════════════════════════════════════════════════

  static TextStyle get shellTitle => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: MetalCostingColors.shellTextTitle,
        letterSpacing: 0.8,
      );

  static TextStyle get sectionLabel => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: MetalCostingColors.textMuted,
        letterSpacing: 1.2,
      );

  static TextStyle get cardTitle => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: MetalCostingColors.textDark,
      );

  static TextStyle get cardSubtitle => GoogleFonts.inter(
        fontSize: 11,
        color: MetalCostingColors.textMuted,
        height: 1.3,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      );

  static TextStyle get amountLarge => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get calcRow => GoogleFonts.inter(
        fontSize: 11,
        color: MetalCostingColors.textMuted,
      );

  static TextStyle get calcRowTotal => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: MetalCostingColors.profitGreen,
      );

  static TextStyle get itemName => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: MetalCostingColors.textDark,
      );

  static TextStyle get itemMeta => GoogleFonts.inter(
        fontSize: 10,
        color: MetalCostingColors.textHint,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // DIMENSIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const double rCard = 16.0;
  static const double rInner = 10.0;
  static const double rPill = 20.0;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 0, 20, 50);
  static const EdgeInsets cardPadding = EdgeInsets.all(18);

  // ═══════════════════════════════════════════════════════════════════════════
  // DECORATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  static const BoxDecoration shellDecoration = BoxDecoration(
    color: MetalCostingColors.shellPanelBg,
    border: Border(
      bottom: BorderSide(color: MetalCostingColors.shellBorder, width: 1),
    ),
  );

  static BoxDecoration get sectionCard => BoxDecoration(
        color: MetalCostingColors.cardBg,
        borderRadius: BorderRadius.circular(rCard),
        border: Border.all(color: MetalCostingColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: MetalCostingColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration metalCard({
    required Color accent,
    required bool hovered,
  }) =>
      BoxDecoration(
        color: MetalCostingColors.cardBg,
        borderRadius: BorderRadius.circular(rCard),
        border: Border.all(
          color:
              hovered ? accent.withOpacity(0.7) : MetalCostingColors.cardBorder,
          width: hovered ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: hovered
                ? accent.withOpacity(0.15)
                : MetalCostingColors.shadowLight,
            blurRadius: hovered ? 20 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration purityCard(Color accent) => BoxDecoration(
        color: MetalCostingColors.cardBg,
        borderRadius: BorderRadius.circular(rCard),
        border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      );

  static BoxDecoration priceBox(Color bg, Color border) => BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(rInner),
        border: Border.all(color: border, width: 1),
      );

  static BoxDecoration profitBox(bool isProfit, {bool isWarn = false}) =>
      BoxDecoration(
        color: isWarn
            ? MetalCostingColors.warnAmberBg
            : isProfit
                ? MetalCostingColors.profitGreenBg
                : MetalCostingColors.lossRedBg,
        borderRadius: BorderRadius.circular(rInner),
        border: Border.all(
          color: isWarn
              ? MetalCostingColors.warnAmberBorder
              : isProfit
                  ? MetalCostingColors.profitGreenBorder
                  : MetalCostingColors.lossRedBorder,
          width: 1,
        ),
      );

  static BoxDecoration calcBox() => BoxDecoration(
        color: MetalCostingColors.inputBg,
        borderRadius: BorderRadius.circular(rInner),
        border: Border.all(color: MetalCostingColors.cardBorder, width: 0.5),
      );
}
