// =============================================================================
// FILE        : delivery_icons.dart
// MODULE      : Sales → Delivery Management
// LAYER       : Theme / Icons
// =============================================================================

import 'package:flutter/material.dart';

class DeliveryIcons {
  DeliveryIcons._();

  // ── MODULE ────────────────────────────────────────────────────────────────
  static const IconData moduleIcon        = Icons.local_shipping_rounded;

  // ── NAVIGATION ────────────────────────────────────────────────────────────
  static const IconData backArrow         = Icons.arrow_back_ios_new_rounded;
  static const IconData close             = Icons.close_rounded;
  static const IconData filter            = Icons.filter_list_rounded;
  static const IconData sort              = Icons.sort_rounded;
  static const IconData search            = Icons.search_rounded;
  static const IconData refresh           = Icons.refresh_rounded;

  // ── STATUS PIPELINE ───────────────────────────────────────────────────────
  static const IconData statusBooked      = Icons.bookmark_added_rounded;
  static const IconData statusInMaking    = Icons.engineering_rounded;
  static const IconData statusReady       = Icons.inventory_2_rounded;
  static const IconData statusDelivered   = Icons.check_circle_rounded;
  static const IconData statusCancelled   = Icons.cancel_rounded;

  // ── TABS ──────────────────────────────────────────────────────────────────
  static const IconData tabActiveOrders   = Icons.pending_actions_rounded;
  static const IconData tabActionRequired = Icons.notification_important_rounded;
  static const IconData tabDueLedger      = Icons.account_balance_wallet_rounded;
  static const IconData tabCompleted      = Icons.task_alt_rounded;

  // ── ACTIONS ───────────────────────────────────────────────────────────────
  static const IconData deliver           = Icons.local_shipping_rounded;
  static const IconData markReady         = Icons.check_circle_outline_rounded;
  static const IconData assignKarigar     = Icons.engineering_rounded;
  static const IconData collectPayment    = Icons.payments_rounded;
  static const IconData printBill         = Icons.print_rounded;
  static const IconData whatsapp          = Icons.chat_rounded;
  static const IconData cancel            = Icons.cancel_outlined;
  static const IconData partialDeliver    = Icons.splitscreen_rounded;

  // ── ORDER DETAILS ─────────────────────────────────────────────────────────
  static const IconData customer          = Icons.person_rounded;
  static const IconData phone             = Icons.phone_iphone_rounded;
  static const IconData item              = Icons.diamond_rounded;
  static const IconData weight            = Icons.scale_rounded;
  static const IconData rate              = Icons.price_change_rounded;
  static const IconData calendar          = Icons.calendar_month_rounded;
  static const IconData notes             = Icons.edit_note_rounded;
  static const IconData image             = Icons.image_rounded;
  static const IconData karigar           = Icons.handyman_rounded;
  static const IconData billLink          = Icons.receipt_long_rounded;

  // ── FINANCIAL ────────────────────────────────────────────────────────────
  static const IconData advance           = Icons.payments_rounded;
  static const IconData totalAmount       = Icons.currency_rupee_rounded;
  static const IconData dueAmount         = Icons.warning_amber_rounded;
  static const IconData cash              = Icons.money_rounded;
  static const IconData upi               = Icons.account_balance_rounded;
  static const IconData card              = Icons.credit_card_rounded;

  // ── MISC ──────────────────────────────────────────────────────────────────
  static const IconData emptyState        = Icons.local_shipping_outlined;
  static const IconData urgencyOverdue    = Icons.error_rounded;
  static const IconData urgencyToday      = Icons.schedule_rounded;
  static const IconData arrowRight        = Icons.arrow_forward_ios_rounded;
  static const IconData checkBox          = Icons.check_box_rounded;
  static const IconData checkBoxEmpty     = Icons.check_box_outline_blank_rounded;
}
