// ==========================================
// FILE: defaulter_styles.dart
// MODULE: Customer → Defaulter List
// DESCRIPTION: Typography and decoration constants.
// ==========================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'defaulter_colors.dart';

class DefaulterStyles {
  DefaulterStyles._();

  // ==========================================
  // SHELL / APP BAR TYPOGRAPHY
  // ==========================================

  static TextStyle get shellModuleTitle => GoogleFonts.inter(
    fontSize: 18.0,
    fontWeight: FontWeight.w800,
    color: DefaulterColors.shellTextTitle,
    letterSpacing: 1.8,
  );

  static TextStyle get shellSubtitle => GoogleFonts.inter(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    color: DefaulterColors.shellTextMuted,
    letterSpacing: 0.5,
  );

  static TextStyle get onlineBadgeText => GoogleFonts.inter(
    fontSize: 9.5,
    fontWeight: FontWeight.w700,
    color: DefaulterColors.onlineGreen,
    letterSpacing: 1.0,
  );

  // ==========================================
  // STATS PANEL
  // ==========================================

  static const TextStyle statLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: DefaulterColors.bodyTextMuted,
    letterSpacing: 0.3,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: DefaulterColors.bodyTextMain,
    height: 1.0,
  );

  static const TextStyle statSuffix = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: DefaulterColors.bodyTextMuted,
  );

  static const TextStyle statAmountValue = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    color: DefaulterColors.statAmountText,
    height: 1.0,
  );

  static const TextStyle statCriticalValue = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: DefaulterColors.riskCriticalText,
    height: 1.0,
  );

  // ==========================================
  // TABLE HEADER
  // ==========================================

  static const TextStyle tableHeader = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: DefaulterColors.bodyTextMain,
    letterSpacing: 0.8,
  );

  // ==========================================
  // TABLE ROW CONTENT
  // ==========================================

  static const TextStyle customerName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: DefaulterColors.bodyTextMain,
  );

  static const TextStyle customerMobile = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: DefaulterColors.bodyTextMuted,
    letterSpacing: 0.3,
  );

  static const TextStyle customerCity = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: DefaulterColors.bodyTextHint,
  );

  static const TextStyle refNumber = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: DefaulterColors.bodyTextMain,
    letterSpacing: 0.5,
  );

  static const TextStyle amountText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w900,
    color: DefaulterColors.bodyTextMain,
  );

  static const TextStyle amountTotalDue = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w900,
    color: DefaulterColors.riskCriticalText,
  );

  static const TextStyle daysText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: DefaulterColors.bodyTextMain,
  );

  static const TextStyle daysUnit = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: DefaulterColors.bodyTextMuted,
  );

  static const TextStyle interestRate = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: DefaulterColors.bodyTextHint,
  );

  // ==========================================
  // RISK BADGE
  // ==========================================

  static const TextStyle riskBadgeText = TextStyle(
    fontSize: 9.5,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.8,
  );

  // ==========================================
  // SEARCH & FILTER
  // ==========================================

  static const TextStyle searchInputText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: DefaulterColors.bodyTextMain,
  );

  static const TextStyle filterChipText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  // ==========================================
  // EMPTY STATE
  // ==========================================

  static const TextStyle emptyTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: DefaulterColors.bodyTextMuted,
  );

  static const TextStyle emptySubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: DefaulterColors.bodyTextHint,
    height: 1.6,
  );

  // ==========================================
  // DECORATIONS
  // ==========================================

  static const BoxDecoration shellHeaderDecoration = BoxDecoration(
    color: DefaulterColors.shellBg,
    border: Border(
      bottom: BorderSide(color: DefaulterColors.shellBorder, width: 1),
    ),
  );

  static BoxDecoration get bodyDecoration => const BoxDecoration(
    color: DefaulterColors.bodyBg,
  );

  static BoxDecoration get statCardDecoration => BoxDecoration(
    color: DefaulterColors.statCardBg,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: DefaulterColors.statCardBorder, width: 1),
    boxShadow: [
      BoxShadow(
        color: DefaulterColors.shadowLight,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration get tableContainerDecoration => BoxDecoration(
    color: DefaulterColors.bodyPanelBg,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: DefaulterColors.bodyBorder, width: 1),
    boxShadow: [
      BoxShadow(
        color: DefaulterColors.shadowLight,
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static BoxDecoration get searchBarDecoration => BoxDecoration(
    color: DefaulterColors.searchBg,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: DefaulterColors.searchBorder, width: 1),
    boxShadow: [
      BoxShadow(
        color: DefaulterColors.shadowLight,
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration get tableHeaderDecoration => const BoxDecoration(
    color: DefaulterColors.tableHeaderBg,
    border: Border(
      bottom: BorderSide(color: DefaulterColors.tableDivider, width: 1.5),
    ),
  );
}