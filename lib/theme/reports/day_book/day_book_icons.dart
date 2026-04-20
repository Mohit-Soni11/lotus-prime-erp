// =============================================================================
// FILE        : day_book_icons.dart
// MODULE      : Reports & Analytics → Day Book
// LAYER       : Theme / Icons
// =============================================================================

import 'package:flutter/material.dart';

class DayBookIcons {
  DayBookIcons._();

  // ── Navigation ────────────────────────────────────────────────────────────
  static const IconData backArrow = Icons.arrow_back_ios_new_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData expand = Icons.keyboard_arrow_down_rounded;
  static const IconData collapse = Icons.keyboard_arrow_up_rounded;

  // ── Module ────────────────────────────────────────────────────────────────
  static const IconData moduleIcon = Icons.menu_book_rounded;

  // ── AppBar Actions ────────────────────────────────────────────────────────
  static const IconData exportPdf = Icons.picture_as_pdf_rounded;
  static const IconData exportExcel = Icons.table_chart_rounded;
  static const IconData shareWa = Icons.share_rounded;
  static const IconData calendarNav = Icons.calendar_today_rounded;
  static const IconData prevDay = Icons.chevron_left_rounded;
  static const IconData nextDay = Icons.chevron_right_rounded;
  static const IconData today = Icons.today_rounded;

  // ── Cash Flow — Inward ────────────────────────────────────────────────────
  static const IconData cashIn = Icons.south_west_rounded;
  static const IconData retailSales = Icons.point_of_sale_rounded;
  static const IconData dueReceipts = Icons.account_balance_wallet_rounded;
  static const IconData bookingAdv = Icons.bookmark_added_rounded;
  static const IconData vendorRefund = Icons.assignment_return_rounded;
  static const IconData girviReceipt = Icons.lock_open_rounded;

  // ── Cash Flow — Outward ───────────────────────────────────────────────────
  static const IconData cashOut = Icons.north_east_rounded;
  static const IconData expenses = Icons.receipt_long_rounded;
  static const IconData girviGiven = Icons.lock_rounded;
  static const IconData karigarPay = Icons.handyman_rounded;
  static const IconData vendorPay = Icons.local_shipping_rounded;
  static const IconData salesReturn = Icons.undo_rounded;

  // ── Bill Type ─────────────────────────────────────────────────────────────
  static const IconData gstBill = Icons.verified_rounded;
  static const IconData nonGstBill = Icons.receipt_rounded;
  static const IconData taxTag = Icons.percent_rounded;

  // ── Metal ─────────────────────────────────────────────────────────────────
  static const IconData metalIn = Icons.add_circle_outline_rounded;
  static const IconData metalOut = Icons.remove_circle_outline_rounded;
  static const IconData goldMetal = Icons.circle_rounded;
  static const IconData silverMetal = Icons.circle_outlined;
  static const IconData vaultIcon = Icons.lock_rounded;
  static const IconData scaleIcon = Icons.scale_rounded;
  static const IconData urdPurchase = Icons.recycling_rounded;
  static const IconData karigarFinish = Icons.checkroom_rounded;
  static const IconData girviSecurity = Icons.security_rounded;
  static const IconData returnAsset = Icons.keyboard_return_rounded;
  // ✅ ADDED — used in MetalOutwardSection
  static const IconData retailDispatch = Icons.local_shipping_rounded;
  static const IconData karigarIssue = Icons.construction_rounded;

  // ── Payment Mode ─────────────────────────────────────────────────────────
  static const IconData cashMode = Icons.money_rounded;
  static const IconData upiMode = Icons.account_balance_rounded;
  static const IconData cardMode = Icons.credit_card_rounded;
  static const IconData bankMode = Icons.account_balance_wallet_outlined;

  // ── Summary / EOD ─────────────────────────────────────────────────────────
  static const IconData openingBal = Icons.play_circle_outline_rounded;
  static const IconData closingBal = Icons.stop_circle_outlined;
  static const IconData netFlow = Icons.swap_vert_rounded;
  static const IconData gstCollected = Icons.receipt_long_rounded;
  static const IconData eodSettle = Icons.fact_check_rounded;
  static const IconData denomCalc = Icons.calculate_rounded;
  static const IconData lockDay = Icons.lock_clock_rounded;
  static const IconData anomaly = Icons.warning_amber_rounded;
  static const IconData trendUp = Icons.trending_up_rounded;
  static const IconData trendDown = Icons.trending_down_rounded;
  static const IconData predict = Icons.auto_graph_rounded;
}
