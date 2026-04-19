// =============================================================================
// FILE        : karigar_directory_styles.dart
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'karigar_directory_colors.dart';

class KarigarDirectoryStyles {
  KarigarDirectoryStyles._();

  // ── CARD ──────────────────────────────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: KarigarDirectoryColors.cardBg,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: KarigarDirectoryColors.cardBorder),
    boxShadow: [
      BoxShadow(
        color: KarigarDirectoryColors.shadowLight,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration get cardDecorationHover => BoxDecoration(
    color: KarigarDirectoryColors.cardBg,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: KarigarDirectoryColors.brandGold.withOpacity(0.5),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: KarigarDirectoryColors.brandGold.withOpacity(0.12),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // ── STATS CARD ─────────────────────────────────────────────────────────────
  static BoxDecoration get statsCardDecoration => BoxDecoration(
    color: KarigarDirectoryColors.cardBg,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: KarigarDirectoryColors.cardBorder),
    boxShadow: [
      BoxShadow(
        color: KarigarDirectoryColors.shadowLight,
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // ── SEARCH ─────────────────────────────────────────────────────────────────
  static BoxDecoration get searchDecoration => BoxDecoration(
    color: KarigarDirectoryColors.cardBg,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: KarigarDirectoryColors.cardBorder),
    boxShadow: [
      BoxShadow(
        color: KarigarDirectoryColors.shadowLight,
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ],
  );

  // ── SHELL ─────────────────────────────────────────────────────────────────
  static BoxDecoration get shellDecoration => BoxDecoration(
    color: KarigarDirectoryColors.shellBg,
    border: Border(
      bottom: BorderSide(color: KarigarDirectoryColors.shellBorder, width: 1),
    ),
  );

  // ── FILTER CHIPS ──────────────────────────────────────────────────────────
  static const double filterBarHeight = 38;
  static const EdgeInsets chipPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const double chipBorderRadius = 20;

  // ── AVATAR ─────────────────────────────────────────────────────────────────
  static const double avatarSize = 56;

  // ── CARD PADDING ──────────────────────────────────────────────────────────
  static const EdgeInsets cardPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 14);

  // ── TEXT ───────────────────────────────────────────────────────────────────
  static TextStyle get karigarName => GoogleFonts.manrope(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: KarigarDirectoryColors.textMain,
  );

  static TextStyle get karigarPhone => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: KarigarDirectoryColors.textBody,
  );

  static TextStyle get karigarDetail => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: KarigarDirectoryColors.textMuted,
  );

  static TextStyle get karigarSince => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: KarigarDirectoryColors.textHint,
    fontStyle: FontStyle.italic,
  );

  static TextStyle get statsValue => GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: KarigarDirectoryColors.textMain,
  );

  static TextStyle get statsLabel => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: KarigarDirectoryColors.textMuted,
  );

  static TextStyle get chipActiveStyle => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: KarigarDirectoryColors.brandGold,
  );

  static TextStyle get chipInactiveStyle => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: KarigarDirectoryColors.textMuted,
  );

  static TextStyle get searchText => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: KarigarDirectoryColors.textMain,
  );

  static TextStyle get searchHint => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: KarigarDirectoryColors.textHint,
  );

  static TextStyle get emptyTitle => GoogleFonts.manrope(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: KarigarDirectoryColors.textBody,
  );

  static TextStyle get emptySubtitle => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: KarigarDirectoryColors.textMuted,
  );

  static TextStyle get shellTitle => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: KarigarDirectoryColors.shellTextTitle,
    letterSpacing: 0.3,
  );
}
