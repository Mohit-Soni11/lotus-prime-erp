// =============================================================================
// FILE        : inventory_styles.dart
// MODULE      : Stock & Inventory
// LAYER       : Theme / Styles
// DESCRIPTION : Typography and decorations for Inventory Ledger screen.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'inventory_colors.dart';

class InvStyles {
  InvStyles._();

  // ── SHELL / APP BAR ───────────────────────────────────────────
  static TextStyle get shellTitle => GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: InvColors.shellTextTitle,
    letterSpacing: 0.8,
  );

  // ── PAGE TITLE ────────────────────────────────────────────────
  static TextStyle get pageTitle => GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: InvColors.textDark,
    letterSpacing: 0.3,
  );

  static TextStyle get pageSubtitle => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: InvColors.textMuted,
  );

  // ── SUMMARY CARD ─────────────────────────────────────────────
  static TextStyle get cardLabel => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: InvColors.textMuted,
    letterSpacing: 0.3,
  );

  static TextStyle get cardBigNumber => GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: InvColors.textDark,
    height: 1.0,
  );

  static TextStyle get cardMediumNumber => GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: InvColors.textDark,
  );

  static TextStyle get cardSubValue => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: InvColors.textBody,
  );

  static TextStyle get cardNote => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: InvColors.textMuted,
  );

  // ── SECTION TITLE ─────────────────────────────────────────────
  static TextStyle get sectionTitle => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: InvColors.textDark,
    letterSpacing: 0.2,
  );

  // ── ITEM CARD ────────────────────────────────────────────────
  static TextStyle get itemName => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: InvColors.textDark,
  );

  static TextStyle get itemSku => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: InvColors.textMuted,
    letterSpacing: 0.3,
  );

  static TextStyle get itemFieldLabel => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: InvColors.textMuted,
    letterSpacing: 0.2,
  );

  static TextStyle get itemFieldValue => GoogleFonts.manrope(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: InvColors.textDark,
  );

  static TextStyle get itemMrp => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: InvColors.brandGold,
  );

  // ── FILTER CHIP TEXT STYLES ───────────────────────────────────
  static TextStyle get chipActiveText => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: InvColors.shellTextTitle,
    letterSpacing: 0.2,
  );

  static TextStyle get chipInactiveText => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: InvColors.textMuted,
  );

  // ── METAL CHIP ───────────────────────────────────────────────
  static TextStyle metalChipText(Color color) => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: 0.3,
  );

  // ── STATUS BADGE ─────────────────────────────────────────────
  static TextStyle statusBadgeText(Color color) => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: 0.3,
  );

  // ══════════════════════════════════════════════════════════════
  // DECORATIONS
  // ══════════════════════════════════════════════════════════════

  static const BoxDecoration shellDecoration = BoxDecoration(
    color: InvColors.shellPanelBg,
    border: Border(
      bottom: BorderSide(color: InvColors.shellBorder, width: 1),
    ),
  );

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: InvColors.cardBg,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: InvColors.cardBorder, width: 1),
    boxShadow: const [
      BoxShadow(color: InvColors.shadowLight,  blurRadius: 12, offset: Offset(0, 4)),
      BoxShadow(color: InvColors.shadowMedium, blurRadius: 4,  offset: Offset(0, 1)),
    ],
  );

  static BoxDecoration summaryCard(Color accent, Color bg, Color border) =>
    BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: border, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: accent.withOpacity(0.08),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
        const BoxShadow(
          color: InvColors.shadowLight,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );

  static BoxDecoration chipActive(Color accent) => BoxDecoration(
    color: accent,
    borderRadius: BorderRadius.circular(20),
  );

  static BoxDecoration get chipInactive => BoxDecoration(
    color: InvColors.cardBg,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: InvColors.cardBorder),
  );

  static BoxDecoration statusBadge(Color bg, Color border) => BoxDecoration(
    color: bg,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: border.withOpacity(0.4)),
  );

  static BoxDecoration metalChip(Color bg, Color border) => BoxDecoration(
    color: bg,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: border, width: 1),
  );
}