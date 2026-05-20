// =============================================================================
// FILE        : add_stock_icons.dart
// MODULE      : Stock & Inventory
// LAYER       : Theme / Icons
// DESCRIPTION : Centralized icon library for Add Stock module.
// =============================================================================

import 'package:flutter/material.dart';

class AddStockIcons {
  AddStockIcons._();

  // ── NAVIGATION ───────────────────────────────────────────────
  static const IconData backArrow = Icons.arrow_back_rounded;
  static const IconData close = Icons.close_rounded;

  // ── MODULE HEADER ────────────────────────────────────────────
  static const IconData addStock = Icons.add_box_outlined;
  static const IconData inventory = Icons.inventory_2_outlined;
  static const IconData stockModule = Icons.diamond_outlined;

  // ── SECTION HEADERS ──────────────────────────────────────────
  static const IconData basicInfo = Icons.info_outline_rounded;
  static const IconData metalDetails = Icons.water_drop_outlined;
  static const IconData stoneDetails = Icons.auto_awesome_outlined;
  static const IconData pricing = Icons.currency_rupee_rounded;
  static const IconData compliance = Icons.verified_outlined;
  static const IconData inventoryMgmt = Icons.inventory_2_outlined;

  // ── FIELDS ───────────────────────────────────────────────────
  static const IconData itemName = Icons.label_outline_rounded;
  static const IconData sku = Icons.qr_code_rounded;
  static const IconData category = Icons.category_outlined;
  static const IconData subCategory = Icons.view_list_outlined;
  static const IconData description = Icons.notes_rounded;
  static const IconData metalType = Icons.hub_outlined;
  static const IconData purity = Icons.stars_outlined;
  static const IconData weight = Icons.scale_outlined;
  static const IconData stone = Icons.auto_awesome;
  static const IconData carats = Icons.grade_outlined;
  static const IconData makingCharges = Icons.build_outlined;
  static const IconData price = Icons.payments_outlined;
  static const IconData mrp = Icons.local_offer_outlined;
  static const IconData gstRate = Icons.percent_rounded;
  static const IconData hsn = Icons.receipt_long_outlined;
  static const IconData huid = Icons.verified_user_outlined;
  static const IconData quantity = Icons.format_list_numbered_rounded;
  static const IconData rack = Icons.warehouse_outlined;
  static const IconData supplier = Icons.store_outlined;
  static const IconData status = Icons.toggle_on_rounded;
  static const IconData refresh = Icons.refresh_rounded;

  // ── ACTIONS ──────────────────────────────────────────────────
  static const IconData save = Icons.save_alt_rounded;
  static const IconData reset = Icons.restart_alt_rounded;
  static const IconData addPhoto = Icons.add_photo_alternate_outlined;

  // ── STATUS ───────────────────────────────────────────────────
  static const IconData available = Icons.check_circle_outline_rounded;
  static const IconData sold = Icons.cancel_outlined;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData huidVerified = Icons.verified_rounded;
  static const IconData netWeight = Icons.calculate_outlined;
  static const IconData dropDown = Icons.keyboard_arrow_down_rounded;
}
