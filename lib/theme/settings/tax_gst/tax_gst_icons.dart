// ============================================================
// FILE    : lib/theme/settings/tax_gst/tax_gst_icons.dart
// MODULE  : Tax & GST Configuration
// AUTHOR  : Lotus Prime ERP
// VERSION : 1.0.0
// ============================================================

import 'package:flutter/material.dart';

/// All icon constants for the Tax & GST Settings module.
/// No icons are hardcoded in UI files — all sourced from here.
abstract final class TaxGstIcons {
  TaxGstIcons._();

  // ── AppBar ──────────────────────────────────────────────────
  static const IconData moduleHeader     = Icons.receipt_long_rounded;
  static const IconData backArrow        = Icons.arrow_back_ios_new_rounded;
  static const IconData livePulse        = Icons.circle;

  // ── Hub Cards ───────────────────────────────────────────────
  static const IconData card01           = Icons.verified_rounded;           // GST Registration
  static const IconData card02           = Icons.percent_rounded;            // GST Slabs
  static const IconData card03           = Icons.qr_code_2_rounded;         // HSN Codes
  static const IconData card04           = Icons.tune_rounded;               // Tax Preferences
  static const IconData card05           = Icons.account_balance_rounded;   // TCS / TDS
  static const IconData card06           = Icons.receipt_rounded;            // E-Invoice
  static const IconData card07           = Icons.workspace_premium_rounded;  // BIS Hallmark

  // ── Section Fields ───────────────────────────────────────────
  static const IconData fieldGstin       = Icons.fingerprint_rounded;
  static const IconData fieldLegalName   = Icons.business_rounded;
  static const IconData fieldPan         = Icons.credit_card_rounded;
  static const IconData fieldTan         = Icons.badge_rounded;
  static const IconData fieldDate        = Icons.calendar_today_rounded;
  static const IconData fieldTaxType     = Icons.category_rounded;
  static const IconData fieldState       = Icons.location_on_rounded;
  static const IconData fieldRate        = Icons.percent_rounded;
  static const IconData fieldHsn         = Icons.tag_rounded;
  static const IconData fieldCategory    = Icons.sell_rounded;
  static const IconData fieldBisLicense  = Icons.verified_user_rounded;
  static const IconData fieldHuid        = Icons.local_offer_rounded;
  static const IconData fieldThreshold   = Icons.monetization_on_rounded;
  static const IconData fieldApiUser     = Icons.person_rounded;
  static const IconData fieldApiPass     = Icons.lock_outline_rounded;

  // ── Actions ──────────────────────────────────────────────────
  static const IconData actionEdit       = Icons.edit_rounded;
  static const IconData actionSave       = Icons.check_circle_rounded;
  static const IconData actionCancel     = Icons.cancel_rounded;
  static const IconData actionAdd        = Icons.add_circle_rounded;
  static const IconData actionDelete     = Icons.delete_outline_rounded;
  static const IconData actionSearch     = Icons.search_rounded;
  static const IconData actionRefresh    = Icons.refresh_rounded;

  // ── Status / Indicators ─────────────────────────────────────
  static const IconData statusInfo       = Icons.info_outline_rounded;
  static const IconData statusSuccess    = Icons.check_circle_rounded;
  static const IconData statusWarning    = Icons.warning_amber_rounded;
  static const IconData statusError      = Icons.error_outline_rounded;

  // ── Navigation ───────────────────────────────────────────────
  static const IconData chevronRight     = Icons.chevron_right_rounded;
  static const IconData chevronDown      = Icons.keyboard_arrow_down_rounded;
  static const IconData expandMore       = Icons.expand_more_rounded;
  static const IconData expandLess       = Icons.expand_less_rounded;

  // ── Misc ─────────────────────────────────────────────────────
  static const IconData linkSync         = Icons.sync_rounded;
  static const IconData linkedChain      = Icons.link_rounded;
  static const IconData toggleOn         = Icons.toggle_on_rounded;
  static const IconData toggleOff        = Icons.toggle_off_rounded;
  static const IconData dropdownArrow    = Icons.arrow_drop_down_rounded;
  static const IconData passwordVisible  = Icons.visibility_rounded;
  static const IconData passwordHidden   = Icons.visibility_off_rounded;
  static const IconData copyClipboard    = Icons.copy_rounded;
  static const IconData calendarPick     = Icons.date_range_rounded;
  static const IconData uploadFile       = Icons.upload_file_rounded;
}
