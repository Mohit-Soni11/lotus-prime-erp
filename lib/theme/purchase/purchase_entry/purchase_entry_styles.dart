// =============================================================================
// FILE        : purchase_entry_styles.dart
// MODULE      : Purchase Entry
// LAYER       : Theme
// DESCRIPTION : Typography & visual decorations for Purchase Entry.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'purchase_entry_colors.dart';

class PurchaseEntryStyles {
  PurchaseEntryStyles._();

  static TextStyle get headerTitle => GoogleFonts.inter(
        fontSize: 18.0,
        fontWeight: FontWeight.w700,
        color: PurchaseEntryColors.shellTitle,
        letterSpacing: 1.2,
      );

  static const TextStyle highVisHeader = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
    color: PurchaseEntryColors.textDark,
  );

  static TextStyle get subTitleMuted => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: PurchaseEntryColors.textMuted.withValues(alpha: 0.70),
      );

  static const TextStyle grandTotalText = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: PurchaseEntryColors.purchaseAccent,
    height: 1.0,
  );

  static const TextStyle inputText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w900,
    color: PurchaseEntryColors.textDark,
  );

  static const TextStyle tableColumnHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w900,
    color: PurchaseEntryColors.textDark,
    letterSpacing: 0.8,
  );

  static const TextStyle systemOnlineText = TextStyle(
    color: PurchaseEntryColors.onlineGreen, // <-- Updated to proper onlineGreen
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
}
