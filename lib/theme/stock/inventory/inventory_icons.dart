// =============================================================================
// FILE        : inventory_icons.dart
// MODULE      : Stock & Inventory
// LAYER       : Theme / Icons
// DESCRIPTION : Centralized icons for Inventory module. Fully extracted.
// =============================================================================

import 'package:flutter/material.dart';

class InvIcons {
  InvIcons._();

  // ── APP BAR ───────────────────────────────────────────────────────────────
  static const IconData backArrow = Icons.arrow_back_rounded;
  static const IconData moduleIcon = Icons.inventory_2_rounded;

  // ── PAGE HEADER ───────────────────────────────────────────────────────────
  static const IconData calendar = Icons.calendar_today_rounded;

  // ── SUMMARY CARDS ─────────────────────────────────────────────────────────
  static const IconData openingStock = Icons.lock_open_rounded;
  static const IconData closingStock = Icons.lock_rounded;
  static const IconData metalHoldings = Icons.account_balance_wallet_outlined;

  // ── SECTIONS & EMPTY STATE ────────────────────────────────────────────────
  static const IconData stockList = Icons.inventory_2_outlined;
  static const IconData emptyState = Icons.inventory_2_outlined;

  // ── CATEGORIES (METAL TYPES) ──────────────────────────────────────────────
  static const IconData catGold = Icons.circle_rounded;
  static const IconData catSilver = Icons.circle_outlined;
  static const IconData catDiamond = Icons.diamond_outlined;
  static const IconData catPlatinum = Icons.stars_rounded;
  static const IconData catAntique = Icons.auto_awesome_outlined;
  static const IconData catDefault = Icons.category_outlined;
}
