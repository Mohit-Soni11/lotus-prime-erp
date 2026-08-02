// =============================================================================
// FILE        : karigar_styles.dart
// MODULE      : Karigar
// LAYER       : Theme / Styles
// DESCRIPTION : Master typography, decoration, and dimension constants
//               for the Karigar module. Mirrors AddStockStyles pattern exactly.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'karigar_colors.dart';

class KarigarStyles {
  KarigarStyles._();

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // TYPOGRAPHY
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  static TextStyle get shellTitle => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: KarigarColors.shellTextTitle,
        letterSpacing: 0.8,
      );

  static TextStyle get shellMuted => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: KarigarColors.shellTextMuted,
        letterSpacing: 0.3,
      );

  static TextStyle get sectionTitle => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: KarigarColors.textDark,
        letterSpacing: 0.2,
      );

  static TextStyle get sectionSubtitle => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: KarigarColors.textMuted,
      );

  static TextStyle get fieldLabel => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: KarigarColors.textBody,
        letterSpacing: 0.1,
      );

  static TextStyle get fieldInput => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: KarigarColors.textDark,
      );

  static TextStyle get fieldHint => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: KarigarColors.textHint,
      );

  static TextStyle get readOnlyValue => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: KarigarColors.success,
      );

  static TextStyle get readOnlyLabel => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: KarigarColors.textMuted,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: KarigarColors.textMuted,
      );

  static TextStyle get issueNumber => GoogleFonts.robotoMono(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: KarigarColors.brandGold,
        letterSpacing: 0.5,
      );

  static TextStyle get saveButtonText => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: KarigarColors.shellBg,
        letterSpacing: 0.3,
      );

  static TextStyle get resetButtonText => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: KarigarColors.textMuted,
      );

  // Pending Jobs card styles
  static TextStyle get jobTitle => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: KarigarColors.textDark,
      );

  static TextStyle get jobSubtitle => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: KarigarColors.textMuted,
      );

  static TextStyle get statValue => GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: KarigarColors.textDark,
      );

  static TextStyle get statLabel => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: KarigarColors.textMuted,
        letterSpacing: 0.3,
      );

  // Karigar list tile â€” left panel
  static TextStyle get karigarName => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: KarigarColors.shellTextTitle,
      );

  static TextStyle get karigarSub => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: KarigarColors.shellTextMuted,
      );

  // Ledger entry
  static TextStyle get ledgerTitle => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: KarigarColors.textDark,
      );

  static TextStyle get ledgerAmount => GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: KarigarColors.textDark,
      );

  static TextStyle get ledgerSub => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: KarigarColors.textMuted,
      );

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // DECORATIONS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: KarigarColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KarigarColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
              color: KarigarColors.shadowLight,
              blurRadius: 12,
              offset: Offset(0, 4)),
          BoxShadow(
              color: KarigarColors.shadowMedium,
              blurRadius: 4,
              offset: Offset(0, 1)),
        ],
      );

  static BoxDecoration cardWithAccent(Color accent) => BoxDecoration(
        color: KarigarColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4)),
          const BoxShadow(
              color: KarigarColors.shadowMedium,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      );

  static BoxDecoration get inputNormal => BoxDecoration(
        color: KarigarColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KarigarColors.cardBorder, width: 1),
      );

  static BoxDecoration get inputFocused => BoxDecoration(
        color: KarigarColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KarigarColors.brandGold, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: KarigarColors.brandGold.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      );

  static BoxDecoration get inputDisabled => BoxDecoration(
        color: KarigarColors.inputBgLocked,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: KarigarColors.cardBorder.withValues(alpha: 0.5), width: 1),
      );

  static BoxDecoration readOnlyBox(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      );

  static BoxDecoration sectionIconBox(Color accent) => BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      );

  static const BoxDecoration shellDecoration = BoxDecoration(
    color: KarigarColors.shellPanelBg,
    border:
        Border(bottom: BorderSide(color: KarigarColors.shellBorder, width: 1)),
  );

  // Stat card
  static BoxDecoration statCard(Color accent) => BoxDecoration(
        color: KarigarColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      );

  // Status pill
  static BoxDecoration statusPill(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      );

  // Left panel (dark)
  static const BoxDecoration leftPanelDecoration = BoxDecoration(
    color: KarigarColors.leftPanelBg,
    border: Border(
        right: BorderSide(color: KarigarColors.leftPanelBorder, width: 1)),
  );

  // Selected karigar row
  static BoxDecoration get selectedRow => BoxDecoration(
        color: KarigarColors.selectedRowBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KarigarColors.selectedRowBorder, width: 1),
      );

  // Job card hover
  static BoxDecoration get jobCard => BoxDecoration(
        color: KarigarColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KarigarColors.cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
              color: KarigarColors.shadowLight,
              blurRadius: 10,
              offset: Offset(0, 3)),
        ],
      );

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // DIMENSIONS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  static const double inputHeight = 52.0;
  static const double dropdownHeight = 52.0;
  static const EdgeInsets cardPadding = EdgeInsets.all(24);
  static const EdgeInsets pagePadding = EdgeInsets.all(20);
  static const double leftPanelWidth = 300.0;
}
