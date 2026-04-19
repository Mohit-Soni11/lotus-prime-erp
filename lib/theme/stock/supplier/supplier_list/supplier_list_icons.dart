// -----------------------------------------------------------------------------
// FILE: supplier_list_icons.dart
// MODULE: Supplier → Supplier List
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class SupplierListIcons {
  SupplierListIcons._();

  // ── APP BAR ───────────────────────────────────────────────────────────────
  static const IconData backArrow     = Icons.arrow_back_rounded;
  static const IconData moduleIcon    = Icons.store_rounded;

  // ── ACTIONS ───────────────────────────────────────────────────────────────
  static const IconData addSupplier   = Icons.add_business_rounded;
  static const IconData search        = Icons.search_rounded;
  static const IconData filter        = Icons.filter_list_rounded;
  static const IconData refresh       = Icons.refresh_rounded;
  static const IconData clearSearch   = Icons.close_rounded;

  // ── SUPPLIER CARD ─────────────────────────────────────────────────────────
  static const IconData phone         = Icons.phone_android_rounded;
  static const IconData gst           = Icons.receipt_long_rounded;
  static const IconData location      = Icons.location_city_rounded;
  static const IconData arrowRight    = Icons.arrow_forward_ios_rounded;
  static const IconData edit          = Icons.edit_rounded;
  static const IconData deactivate    = Icons.block_rounded;

  // ── STATS ─────────────────────────────────────────────────────────────────
  static const IconData totalSupplier = Icons.store_mall_directory_rounded;
  static const IconData manufacturer  = Icons.factory_rounded;
  static const IconData todayNew      = Icons.fiber_new_rounded;

  // ── TYPE BADGES ───────────────────────────────────────────────────────────
  static const IconData typeBadge     = Icons.verified_rounded;
  static const IconData systemOnline  = Icons.circle;

  // ── EMPTY STATE ───────────────────────────────────────────────────────────
  static const IconData emptyState    = Icons.store_outlined;
  static const IconData noResult      = Icons.search_off_rounded;
}