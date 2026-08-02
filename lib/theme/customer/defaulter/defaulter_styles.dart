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
  // SHELL / APP BAR TYPOGRAPHY (Updated to Premium Match)
  // ==========================================

  static TextStyle get shellModuleTitle => GoogleFonts.inter(
        fontSize: 18.0, // Match 18px
        fontWeight: FontWeight.w700, // Match w700
        color: DefaulterColors.shellTextTitle,
        letterSpacing: 1.2, // Match 1.2
      );

  static TextStyle get shellSubtitle => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: DefaulterColors.shellTextMuted,
        letterSpacing: 0.5,
      );

  static TextStyle get onlineBadgeText => const TextStyle(
        // Removed GoogleFonts to match exact style
        fontSize: 13, // Match 12px
        fontWeight: FontWeight.w700,
        color: DefaulterColors.onlineGreen,
        letterSpacing: 0.5,
      );

  // ==========================================
  // STATS PANEL
  // ==========================================

  static const TextStyle statLabel = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w800,
    color: DefaulterColors.bodyTextMuted,
    letterSpacing: 0.3,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: DefaulterColors.bodyTextMain,
    height: 1.0,
  );

  static const TextStyle statSuffix = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    color: DefaulterColors.bodyTextMuted,
  );

  static const TextStyle statAmountValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: DefaulterColors.statAmountText,
    height: 1.0,
  );

  static const TextStyle statCriticalValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: DefaulterColors.riskCriticalText,
    height: 1.0,
  );

  // ==========================================
  // TABLE HEADER
  // ==========================================

  static const TextStyle tableHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: DefaulterColors.bodyTextMain,
    letterSpacing: 0.8,
  );

  // ==========================================
  // TABLE ROW CONTENT
  // ==========================================

  static const TextStyle customerName = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w800,
    color: DefaulterColors.bodyTextMain,
  );

  static const TextStyle customerMobile = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: DefaulterColors.bodyTextMuted,
    letterSpacing: 0.3,
  );

  static const TextStyle customerCity = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    color: DefaulterColors.bodyTextHint,
  );

  static const TextStyle refNumber = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w800,
    color: DefaulterColors.bodyTextMain,
    letterSpacing: 0.5,
  );

  static const TextStyle amountText = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w900,
    color: DefaulterColors.bodyTextMain,
  );

  static const TextStyle amountTotalDue = TextStyle(
    fontSize: 16.5,
    fontWeight: FontWeight.w900,
    color: DefaulterColors.riskCriticalText,
  );

  static const TextStyle daysText = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w800,
    color: DefaulterColors.bodyTextMain,
  );

  static const TextStyle daysUnit = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: DefaulterColors.bodyTextMuted,
  );

  static const TextStyle interestRate = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: DefaulterColors.bodyTextHint,
  );

  // ==========================================
  // RISK BADGE
  // ==========================================

  static const TextStyle riskBadgeText = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.8,
  );

  // ==========================================
  // SEARCH & FILTER
  // ==========================================

  static const TextStyle searchInputText = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    color: DefaulterColors.bodyTextMain,
  );

  static const TextStyle filterChipText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.3,
  );

  // ==========================================
  // EMPTY STATE
  // ==========================================

  static const TextStyle emptyTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: DefaulterColors.bodyTextMain,
  );

  static const TextStyle emptySubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: DefaulterColors.bodyTextMain,
    height: 1.6,
  );

  // ==========================================
  // DECORATIONS
  // ==========================================

  // Updated to match the shellPanel style from other headers
  static const BoxDecoration shellHeaderDecoration = BoxDecoration(
    color: DefaulterColors.shellPanelBg,
    border: Border(
      bottom: BorderSide(color: DefaulterColors.shellBorder, width: 1),
    ),
    boxShadow: [
      BoxShadow(
        color: Color(0x26000000),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get bodyDecoration => const BoxDecoration(
        color: DefaulterColors.bodyBg,
      );

  static BoxDecoration get statCardDecoration => BoxDecoration(
        color: DefaulterColors.statCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DefaulterColors.statCardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: DefaulterColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get tableContainerDecoration => BoxDecoration(
        color: DefaulterColors.bodyPanelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DefaulterColors.bodyBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: DefaulterColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      );

  static BoxDecoration get searchBarDecoration => BoxDecoration(
        color: DefaulterColors.searchBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DefaulterColors.searchBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: DefaulterColors.shadowLight,
            blurRadius: 6,
            offset: Offset(0, 2),
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
