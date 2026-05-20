// -----------------------------------------------------------------------------
// FILE: customer_list_icons.dart
// MODULE: Customer → Customer List
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class CustomerListIcons {
  CustomerListIcons._();

  // ── APP BAR ───────────────────────────────────────────────────────────────
  static const IconData backArrow = Icons.arrow_back_rounded;
  static const IconData moduleIcon = Icons.people_alt_rounded;

  // ── ACTIONS ───────────────────────────────────────────────────────────────
  static const IconData addCustomer = Icons.person_add_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData filter = Icons.filter_list_rounded;
  static const IconData sort = Icons.sort_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData export = Icons.file_download_outlined;
  static const IconData clearSearch = Icons.close_rounded;

  // ── CUSTOMER CARD ─────────────────────────────────────────────────────────
  static const IconData phone = Icons.phone_android_rounded;
  static const IconData city = Icons.location_city_rounded;
  static const IconData calendar = Icons.calendar_today_outlined;
  static const IconData invoice = Icons.receipt_long_rounded;
  static const IconData arrowRight = Icons.arrow_forward_ios_rounded;
  static const IconData defaultAvatar = Icons.person_rounded;

  // ── BADGES ────────────────────────────────────────────────────────────────
  static const IconData vipBadge = Icons.workspace_premium_rounded;
  static const IconData verifiedBadge = Icons.verified_rounded;

  // ── EMPTY STATE ───────────────────────────────────────────────────────────
  static const IconData emptyState = Icons.people_outline_rounded;
  static const IconData noResult = Icons.search_off_rounded;

  // ── STATUS ────────────────────────────────────────────────────────────────
  static const IconData systemOnline = Icons.circle;
  static const IconData stats = Icons.bar_chart_rounded;
}
