// ==========================================
// FILE: sales_pos_styles.dart
// TYPE: Theme Core (UPGRADED)
// AUTHOR: Senior System Architect
// DESCRIPTION: Master typography and visual decorations.
//              âœ… Extracted UI hardcoded text styles integrated.
// ==========================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sales_pos_colors.dart';

class SalesPosStyles {
  SalesPosStyles._();

  static const double fontCaption = 12;
  static const double fontLabel = 13;
  static const double fontBody = 14;
  static const double fontInput = 15;
  static const double fontValue = 16;
  static const double fontTitle = 18;
  static const double fontSection = 20;
  static const double fontAmount = 22;
  static const double fontHero = 26;

  static const TextStyle caption = TextStyle(
    fontSize: fontCaption,
    fontWeight: FontWeight.w700,
    color: SalesPosColors.bodyTextMuted,
    letterSpacing: 0,
  );

  static const TextStyle captionStrong = TextStyle(
    fontSize: fontCaption,
    fontWeight: FontWeight.w900,
    color: SalesPosColors.textDark,
    letterSpacing: 0,
  );

  static const TextStyle label = TextStyle(
    fontSize: fontLabel,
    fontWeight: FontWeight.w800,
    color: SalesPosColors.bodyTextMuted,
    letterSpacing: 0,
  );

  static const TextStyle labelStrong = TextStyle(
    fontSize: fontLabel,
    fontWeight: FontWeight.w900,
    color: SalesPosColors.textDark,
    letterSpacing: 0,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: fontBody,
    fontWeight: FontWeight.w800,
    color: SalesPosColors.bodyTextMain,
    letterSpacing: 0,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: fontBody,
    fontWeight: FontWeight.w900,
    color: SalesPosColors.textDark,
    letterSpacing: 0,
  );

  static const TextStyle valueText = TextStyle(
    fontSize: fontValue,
    fontWeight: FontWeight.w900,
    color: SalesPosColors.textDark,
    letterSpacing: 0,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: fontBody,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static TextStyle get headerTitle => GoogleFonts.inter(
        fontSize: fontTitle,
        fontWeight: FontWeight.w700,
        color: SalesPosColors.shellTextTitle,
        letterSpacing: 0,
      );

  // --- ðŸš€ NEW: EXTRACTED SEMANTIC UI STYLES ---

  // High Visibility Headers (e.g. CUSTOMER DETAILS, INVOICE PREFERENCES)
  static const TextStyle highVisHeader = TextStyle(
    fontSize: fontBody,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
    color: SalesPosColors.textDark,
  );

  // Subtitles & Muted Descriptions
  static TextStyle subTitleMuted = TextStyle(
    fontSize: fontLabel,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    color: SalesPosColors.bodyTextMuted.withValues(alpha: 0.70),
  );

  // Big Numbers & Grand Totals (e.g. â‚¹ 50,000.00 in Right Panel)
  static const TextStyle grandTotalText = TextStyle(
    fontSize: fontHero,
    fontWeight: FontWeight.w900,
    color: SalesPosColors.brandGold,
    height: 1.0,
    letterSpacing: 0,
  );

  // Form Input Fields Text
  static const TextStyle inputText = TextStyle(
    fontSize: fontInput,
    fontWeight: FontWeight.w900,
    color: SalesPosColors.textDark,
    letterSpacing: 0,
  );

  // --- EXISTING BODY TYPOGRAPHY ---

  static const TextStyle sectionHeader = TextStyle(
    fontSize: fontSection,
    fontWeight: FontWeight.w900,
    color: SalesPosColors.textDark,
    letterSpacing: 0,
  );

  static const TextStyle tableColumnHeader = TextStyle(
    fontSize: fontLabel,
    fontWeight: FontWeight.w900,
    color: SalesPosColors.textDark,
    letterSpacing: 0,
  );

  static const TextStyle standardRowText = TextStyle(
    fontSize: fontInput,
    fontWeight: FontWeight.w800,
    color: SalesPosColors.textDark,
    letterSpacing: 0,
  );

  static const TextStyle summaryLabelText = TextStyle(
    fontSize: fontBody,
    fontWeight: FontWeight.w800,
    color: SalesPosColors.textDark,
    letterSpacing: 0,
  );

  static const TextStyle summaryValueText = TextStyle(
    fontSize: fontValue,
    fontWeight: FontWeight.w900,
    color: SalesPosColors.textDark,
    letterSpacing: 0,
  );

  // --- LOGIN BADGE TYPOGRAPHY ---
  static const TextStyle badgeNameText = TextStyle(
    color: SalesPosColors.shellTextTitle,
    fontSize: fontBody,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    height: 1.0,
  );

  static const TextStyle badgeRoleText = TextStyle(
    color: SalesPosColors.textDark,
    fontSize: fontCaption,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
    height: 1.0,
  );

  static const TextStyle badgeMenuItemText = TextStyle(
    color: SalesPosColors.shellTextTitle,
    fontWeight: FontWeight.w600,
    fontSize: fontInput,
    letterSpacing: 0,
  );

  // --- GLOBAL DECORATIONS ---
  static const BoxDecoration shellSolidPanel = BoxDecoration(
    color: SalesPosColors.shellPanelBg,
    border: Border(
      bottom: BorderSide(color: SalesPosColors.shellBorder, width: 1),
    ),
  );

  static final BoxDecoration badgeMenuDecoration = BoxDecoration(
    color: SalesPosColors.badgeMenuBg,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: SalesPosColors.badgeBorder),
  );
}
