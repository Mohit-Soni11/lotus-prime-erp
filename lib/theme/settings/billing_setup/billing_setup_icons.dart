// =============================================================================
// FILE        : lib/theme/settings/billing_setup/billing_setup_icons.dart
// MODULE      : Billing Setup
// LAYER       : Theme / Icons
// DESCRIPTION : All IconData constants — zero hardcoded icons in UI.
//               Mirrors KarigarIcons pattern exactly.
// =============================================================================

import 'package:flutter/material.dart';

class BillingSetupIcons {
  BillingSetupIcons._();

  // ── APP BAR ───────────────────────────────────────────────────────────────
  static const IconData backArrow = Icons.arrow_back_rounded;
  static const IconData moduleIcon = Icons.receipt_long_rounded;

  // ── HUB CARDS ─────────────────────────────────────────────────────────────
  static const IconData salesCard = Icons.diamond_rounded;
  static const IconData purchaseCard = Icons.inventory_2_rounded;
  static const IconData girviCard = Icons.lock_rounded;
  static const IconData returnCard = Icons.sync_alt_rounded;
  static const IconData navArrow = Icons.arrow_forward_ios_rounded;

  // ── SECTION — SALES ───────────────────────────────────────────────────────
  static const IconData invoiceNo = Icons.tag_rounded;
  static const IconData estimate = Icons.description_outlined;
  static const IconData payment = Icons.payments_rounded;
  static const IconData upi = Icons.qr_code_rounded;
  static const IconData creditDays = Icons.calendar_today_rounded;
  static const IconData advance = Icons.trending_up_rounded;
  static const IconData discount = Icons.local_offer_rounded;
  static const IconData rounding = Icons.tune_rounded;
  static const IconData makingCharge = Icons.construction_rounded;
  static const IconData huid = Icons.verified_rounded;
  static const IconData oldGold = Icons.brightness_3_rounded;
  static const IconData terms = Icons.article_rounded;
  static const IconData footer = Icons.format_quote_rounded;

  // ── SECTION — PURCHASE ────────────────────────────────────────────────────
  static const IconData payDays = Icons.event_available_rounded;
  static const IconData weight = Icons.scale_rounded;
  static const IconData karat = Icons.circle_outlined;
  static const IconData autoPrint = Icons.print_rounded;

  // ── SECTION — GIRVI ───────────────────────────────────────────────────────
  static const IconData girviTicket = Icons.confirmation_number_rounded;
  static const IconData interestRate = Icons.percent_rounded;
  static const IconData interestType = Icons.swap_vert_rounded;
  static const IconData gracePeriod = Icons.hourglass_top_rounded;
  static const IconData duration = Icons.timelapse_rounded;
  static const IconData reminder = Icons.notifications_rounded;
  static const IconData notice = Icons.warning_amber_rounded;

  // ── SECTION — RETURN ──────────────────────────────────────────────────────
  static const IconData returnWindow = Icons.event_repeat_rounded;
  static const IconData handling = Icons.price_change_rounded;
  static const IconData returnMode = Icons.compare_arrows_rounded;
  static const IconData voucherPrefix = Icons.receipt_rounded;
  static const IconData buybackRate = Icons.currency_rupee_rounded;
  static const IconData purity = Icons.science_rounded;

  // ── SECTION CARD ACTIONS ──────────────────────────────────────────────────
  static const IconData lock = Icons.lock_outline_rounded;
  static const IconData save = Icons.check_rounded;
  static const IconData statusActive = Icons.circle;
  static const IconData dropDown = Icons.keyboard_arrow_down_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData error = Icons.error_outline_rounded;
  static const IconData infoIcon = Icons.info_outline_rounded;
}
