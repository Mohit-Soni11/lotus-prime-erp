// =============================================================================
// FILE        : day_book_styles.dart
// MODULE      : Reports & Analytics → Day Book
// LAYER       : Theme / Styles
// DESCRIPTION : TextStyles & BoxDecorations — matches Cash Book pattern.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'day_book_colors.dart';

class DayBookStyles {
  DayBookStyles._();

  // ── AppBar ────────────────────────────────────────────────────────────────
  static TextStyle get appBarTitle => GoogleFonts.inter(
    fontSize: 18.0, fontWeight: FontWeight.w700,
    color: DayBookColors.shellTitle, letterSpacing: 1.2,
  );

  static TextStyle get appBarSub => GoogleFonts.inter(
    fontSize: 11.0, fontWeight: FontWeight.w500,
    color: DayBookColors.shellMuted, letterSpacing: 0.4,
  );

  // ── Section Header ────────────────────────────────────────────────────────
  static TextStyle get sectionTitle => GoogleFonts.inter(
    fontSize: 13.0, fontWeight: FontWeight.w800,
    color: DayBookColors.textDark, letterSpacing: 1.1,
  );

  static TextStyle get sectionSubtitle => GoogleFonts.inter(
    fontSize: 11.5, fontWeight: FontWeight.w500,
    color: DayBookColors.textSecondary,
  );

  // ── Amount Styles ─────────────────────────────────────────────────────────
  static TextStyle get amountHero => GoogleFonts.inter(
    fontSize: 28.0, fontWeight: FontWeight.w800,
    color: DayBookColors.textDark, letterSpacing: -0.5,
  );

  static TextStyle get amountLarge => GoogleFonts.inter(
    fontSize: 20.0, fontWeight: FontWeight.w800,
    color: DayBookColors.textDark,
  );

  static TextStyle get amountMedium => GoogleFonts.inter(
    fontSize: 16.0, fontWeight: FontWeight.w700,
    color: DayBookColors.textDark,
  );

  static TextStyle get amountSmall => GoogleFonts.inter(
    fontSize: 13.0, fontWeight: FontWeight.w700,
    color: DayBookColors.textDark,
  );

  static TextStyle get amountGold => GoogleFonts.inter(
    fontSize: 22.0, fontWeight: FontWeight.w800,
    color: DayBookColors.brandGold, letterSpacing: -0.3,
  );

  // ── Label Styles ──────────────────────────────────────────────────────────
  static TextStyle get labelPrimary => GoogleFonts.inter(
    fontSize: 13.5, fontWeight: FontWeight.w600,
    color: DayBookColors.textPrimary,
  );

  static TextStyle get labelSecondary => GoogleFonts.inter(
    fontSize: 11.5, fontWeight: FontWeight.w500,
    color: DayBookColors.textSecondary,
  );

  static TextStyle get labelMuted => GoogleFonts.inter(
    fontSize: 11.0, fontWeight: FontWeight.w400,
    color: DayBookColors.textMuted,
  );

  static TextStyle get labelBold => GoogleFonts.inter(
    fontSize: 13.0, fontWeight: FontWeight.w700,
    color: DayBookColors.textDark,
  );

  // ── Badge Styles ──────────────────────────────────────────────────────────
  static TextStyle get gstBadge => GoogleFonts.inter(
    fontSize: 10.0, fontWeight: FontWeight.w800,
    color: DayBookColors.gstBadge, letterSpacing: 0.5,
  );

  static TextStyle get nonGstBadge => GoogleFonts.inter(
    fontSize: 10.0, fontWeight: FontWeight.w800,
    color: DayBookColors.nonGstBadge, letterSpacing: 0.5,
  );

  static TextStyle get anomalyText => GoogleFonts.inter(
    fontSize: 12.5, fontWeight: FontWeight.w600,
    color: DayBookColors.anomalyText,
  );

  // ── Trend Badge ───────────────────────────────────────────────────────────
  static TextStyle get trendUp => GoogleFonts.inter(
    fontSize: 11.0, fontWeight: FontWeight.w700,
    color: DayBookColors.cashInText,
  );

  static TextStyle get trendDown => GoogleFonts.inter(
    fontSize: 11.0, fontWeight: FontWeight.w700,
    color: DayBookColors.cashOutText,
  );

  // ── EOD Denomination ─────────────────────────────────────────────────────
  static TextStyle get denomLabel => GoogleFonts.inter(
    fontSize: 14.0, fontWeight: FontWeight.w700,
    color: DayBookColors.textPrimary,
  );

  static TextStyle get denomTotal => GoogleFonts.inter(
    fontSize: 14.0, fontWeight: FontWeight.w700,
    color: DayBookColors.brandGold,
  );

  // ── Shell Panel ───────────────────────────────────────────────────────────
  static const BoxDecoration shellPanel = BoxDecoration(
    color: DayBookColors.shellPanel,
    border: Border(
      bottom: BorderSide(color: DayBookColors.shellBorder, width: 1.0),
    ),
  );

  // ── Section Card ─────────────────────────────────────────────────────────
  static BoxDecoration sectionCard({Color? borderColor}) => BoxDecoration(
    color: DayBookColors.bodyPanel,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: borderColor ?? DayBookColors.bodyBorder, width: 1.0,
    ),
    boxShadow: const [
      BoxShadow(color: DayBookColors.shadowLight, blurRadius: 6, offset: Offset(0, 2)),
    ],
  );

  // ── Section Header Row ────────────────────────────────────────────────────
  static BoxDecoration sectionHeaderBg({required Color color}) => BoxDecoration(
    color: color,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
  );

  // ── Sub-row Item ─────────────────────────────────────────────────────────
  static BoxDecoration subRowDecoration({Color? bg}) => BoxDecoration(
    color: bg ?? DayBookColors.bodyBg,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: DayBookColors.bodyBorder, width: 0.8),
  );

  // ── GST Badge Pill ────────────────────────────────────────────────────────
  static const BoxDecoration gstPill = BoxDecoration(
    color: DayBookColors.gstBg,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  static const BoxDecoration nonGstPill = BoxDecoration(
    color: DayBookColors.nonGstBg,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  // ── Anomaly Banner ────────────────────────────────────────────────────────
  static const BoxDecoration anomalyBanner = BoxDecoration(
    color: DayBookColors.anomalyBg,
    borderRadius: BorderRadius.all(Radius.circular(10)),
    border: Border.fromBorderSide(
      BorderSide(color: DayBookColors.anomalyBorder, width: 1.2),
    ),
  );

  // ── Opening Balance Card ──────────────────────────────────────────────────
  static const BoxDecoration openingBalCard = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF1F2937), Color(0xFF111827)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.all(Radius.circular(14)),
    boxShadow: [
      BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );

  // ── EOD Dialog Card ───────────────────────────────────────────────────────
  static const BoxDecoration eodCard = BoxDecoration(
    color: DayBookColors.bodyPanel,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    boxShadow: [
      BoxShadow(color: Color(0x26000000), blurRadius: 20, offset: Offset(0, 8)),
    ],
  );

  // ── Net Flow Card ─────────────────────────────────────────────────────────
  static BoxDecoration netFlowCard({required bool isPositive}) => BoxDecoration(
    color: isPositive ? DayBookColors.netPositiveBg : DayBookColors.netNegativeBg,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: isPositive ? DayBookColors.cashInBorder : DayBookColors.cashOutBorder,
      width: 1.0,
    ),
  );
}
