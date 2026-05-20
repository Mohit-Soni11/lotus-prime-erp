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

  // --- APP BAR & SHELL TYPOGRAPHY ---
  static TextStyle get headerTitle => GoogleFonts.inter(
        fontSize: 18.0,
        fontWeight: FontWeight.w700,
        color: SalesPosColors.shellTextTitle,
        letterSpacing: 1.2,
      );

  // --- ðŸš€ NEW: EXTRACTED SEMANTIC UI STYLES ---

  // High Visibility Headers (e.g. CUSTOMER DETAILS, INVOICE PREFERENCES)
  static const TextStyle highVisHeader = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
    color: SalesPosColors.textDark,
  );

  // Subtitles & Muted Descriptions
  static TextStyle subTitleMuted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: SalesPosColors.bodyTextMuted.withValues(alpha: 0.70),
  );

  // Big Numbers & Grand Totals (e.g. â‚¹ 50,000.00 in Right Panel)
  static const TextStyle grandTotalText = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: SalesPosColors.brandGold,
    height: 1.0,
  );

  // Form Input Fields Text
  static const TextStyle inputText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w900,
    color: SalesPosColors.textDark,
  );

  // --- EXISTING BODY TYPOGRAPHY ---

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    color: SalesPosColors.textDark,
  );

  static const TextStyle tableColumnHeader = TextStyle(
    fontSize: 13, // Upgraded to match extracted UI scale
    fontWeight: FontWeight.w900,
    color: SalesPosColors.textDark,
    letterSpacing: 0.8,
  );

  static const TextStyle standardRowText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: SalesPosColors.textDark,
  );

  static const TextStyle summaryLabelText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: SalesPosColors.textDark,
  );

  static const TextStyle summaryValueText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: SalesPosColors.textDark,
  );

  // --- LOGIN BADGE TYPOGRAPHY ---
  static const TextStyle badgeNameText = TextStyle(
    color: SalesPosColors.shellTextTitle,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    height: 1.0,
  );

  static const TextStyle badgeRoleText = TextStyle(
    color: SalesPosColors.textDark,
    fontSize: 10,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.5,
    height: 1.0,
  );

  static const TextStyle badgeMenuItemText = TextStyle(
    color: SalesPosColors.shellTextTitle,
    fontWeight: FontWeight.w600,
    fontSize: 15,
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
