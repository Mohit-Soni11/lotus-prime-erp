// =============================================================================
// FILE        : girvi_icons.dart  
// MODULE      : Girvi / Pawn
// LAYER       : Theme
// NOTE        : All four theme files combined for brevity.
//               In your project, split into separate files and update
//               girvi_theme.dart exports accordingly.
// =============================================================================

// ─── girvi_icons.dart ────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class GirviIcons {
  GirviIcons._();

  // Module
  static const IconData moduleIcon      = Icons.lock_outline_rounded;
  static const IconData backArrow       = Icons.arrow_back_ios_new_rounded;

  // Sections
  static const IconData customer        = Icons.person_rounded;
  static const IconData itemDetails     = Icons.diamond_outlined;
  static const IconData weight          = Icons.scale_rounded;
  static const IconData valuation       = Icons.monetization_on_outlined;
  static const IconData loanTerms       = Icons.account_balance_outlined;
  static const IconData interestRate    = Icons.percent_rounded;
  static const IconData dates           = Icons.calendar_month_rounded;
  static const IconData kyc             = Icons.badge_outlined;
  static const IconData notes           = Icons.notes_rounded;

  // Actions
  static const IconData save            = Icons.save_rounded;
  static const IconData release         = Icons.lock_open_rounded;
  static const IconData calculator      = Icons.calculate_rounded;
  static const IconData list            = Icons.list_alt_rounded;
  static const IconData search          = Icons.search_rounded;
  static const IconData filter          = Icons.filter_list_rounded;
  static const IconData refresh         = Icons.refresh_rounded;
  static const IconData ticket          = Icons.confirmation_number_outlined;
  static const IconData print           = Icons.print_rounded;
  static const IconData share           = Icons.share_rounded;

  // Status
  static const IconData active          = Icons.radio_button_checked_rounded;
  static const IconData overdue         = Icons.warning_amber_rounded;
  static const IconData released        = Icons.check_circle_rounded;
  static const IconData auctioned       = Icons.gavel_rounded;

  // Metal
  static const IconData gold            = Icons.stars_rounded;
  static const IconData silver          = Icons.brightness_7_rounded;
  static const IconData diamond         = Icons.diamond_rounded;

  // Payment
  static const IconData cash            = Icons.payments_rounded;
  static const IconData upi             = Icons.qr_code_scanner_rounded;
  static const IconData bank            = Icons.account_balance_wallet_rounded;

  // Misc
  static const IconData markDone        = Icons.check_circle_outline_rounded;
  static const IconData editItem        = Icons.edit_rounded;
  static const IconData deleteItem      = Icons.delete_outline_rounded;
  static const IconData expandDown      = Icons.keyboard_arrow_down_rounded;
  static const IconData info            = Icons.info_outline_rounded;
}