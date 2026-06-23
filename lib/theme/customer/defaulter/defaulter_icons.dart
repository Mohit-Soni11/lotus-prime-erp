// ==========================================
// FILE: defaulter_icons.dart
// MODULE: Customer → Defaulter List
// DESCRIPTION: Centralized icon constants. No hardcoded icons in UI files.
// ==========================================

import 'package:flutter/material.dart';

class DefaulterIcons {
  DefaulterIcons._();

  // --- NAVIGATION ---
  static const IconData backArrow = Icons.arrow_back_ios_new_rounded;
  static const IconData closeScreen = Icons.close_rounded;

  // --- SCREEN IDENTITY ---
  static const IconData defaulterShield = Icons.shield_outlined;
  static const IconData defaulterAlert = Icons.warning_amber_rounded;
  static const IconData listIcon = Icons.format_list_bulleted_rounded;

  // --- STATS PANEL ---
  static const IconData totalCount = Icons.people_alt_outlined;
  static const IconData totalAmount = Icons.currency_rupee_rounded;
  static const IconData criticalCount = Icons.local_fire_department_rounded;
  static const IconData principal = Icons.account_balance_wallet_outlined;
  static const IconData collected = Icons.payments_outlined;

  // --- RISK LEVELS ---
  static const IconData riskCritical = Icons.crisis_alert_rounded;
  static const IconData riskHigh = Icons.warning_rounded;
  static const IconData riskMedium = Icons.error_outline_rounded;
  static const IconData riskLow = Icons.info_outline_rounded;

  // --- CUSTOMER / ROW ---
  static const IconData personAvatar = Icons.person_rounded;
  static const IconData phoneCall = Icons.phone_rounded;
  static const IconData whatsapp = Icons.chat_rounded;
  static const IconData notify = Icons.notifications_outlined;
  static const IconData viewProfile = Icons.open_in_new_rounded;
  static const IconData cityPin = Icons.location_on_outlined;
  static const IconData loanTag = Icons.sell_outlined;
  static const IconData openAccount = Icons.receipt_long_outlined;
  static const IconData collectInterest = Icons.percent_rounded;

  // --- FILTER & SEARCH ---
  static const IconData search = Icons.search_rounded;
  static const IconData filter = Icons.tune_rounded;
  static const IconData sortAsc = Icons.arrow_upward_rounded;
  static const IconData sortDesc = Icons.arrow_downward_rounded;
  static const IconData clearFilter = Icons.clear_rounded;
  static const IconData refreshData = Icons.refresh_rounded;

  // --- STATUS ---
  static const IconData overdue = Icons.timer_off_rounded;
  static const IconData calendar = Icons.calendar_today_outlined;
  static const IconData interest = Icons.percent_rounded;
  static const IconData trending = Icons.trending_up_rounded;
  static const IconData emptyState = Icons.inbox_outlined;

  // --- EXPORT ---
  static const IconData exportReport = Icons.download_rounded;
  static const IconData share = Icons.share_rounded;
  static const IconData print = Icons.print_rounded;
}
