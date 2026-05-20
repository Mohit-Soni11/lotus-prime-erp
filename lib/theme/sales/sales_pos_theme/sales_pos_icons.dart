// ==========================================
// FILE: sales_pos_icons.dart
// TYPE: Theme Core (UPGRADED)
// AUTHOR: Senior System Architect
// DESCRIPTION: Centralized icon library for the POS system.
//              ✅ 100% extracted hardcoded UI icons integrated.
// ==========================================

import 'package:flutter/material.dart';

class SalesPosIcons {
  SalesPosIcons._();

  // --- NAVIGATION & HEADER ---
  static const IconData menu = Icons.menu_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData backArrow = Icons.arrow_back_ios_new_rounded;
  static const IconData syncData = Icons.sync_rounded;
  static const IconData networkWifi = Icons.wifi_rounded;

  // --- POS ACTIONS ---
  static const IconData cart = Icons.shopping_cart_outlined;
  static const IconData searchItem = Icons.search_rounded;
  static const IconData barcodeScanner = Icons.qr_code_scanner_rounded;
  static const IconData holdOrder = Icons.pause_circle_outline_rounded;
  static const IconData holdFilled =
      Icons.pause_circle_filled_rounded; // Extracted
  static const IconData printReceipt = Icons.print_rounded;

  // --- NEW SALE & BILLING ---
  static const IconData gstToggleOn = Icons.toggle_on;
  static const IconData gstToggleOff = Icons.toggle_off;
  static const IconData calendarDate = Icons.calendar_today_outlined;
  static const IconData clockTime = Icons.access_time_outlined;
  static const IconData newCustomerBadge = Icons.star;
  static const IconData addNewItem = Icons.add_circle_outline;
  static const IconData discountDropdown = Icons.arrow_drop_down;
  static const IconData promiseDateCalendar = Icons.calendar_month;

  // --- 🚀 NEW: CUSTOMER DETAILS PANEL ---
  static const IconData mobilePhone = Icons.phone_iphone_rounded;
  static const IconData customerName = Icons.person_outline_rounded;
  static const IconData cityLocation = Icons.location_city_rounded;
  static const IconData panCard = Icons.badge_outlined;
  static const IconData gstNumber = Icons.receipt_long_rounded;
  static const IconData newCustomerAdd = Icons.person_add_rounded;

  // --- 🚀 NEW: TABLES & ITEMS SECTION ---
  static const IconData invoiceItemsHeader =
      Icons.shopping_cart_checkout_rounded;
  static const IconData addItemToCart = Icons.add_shopping_cart_rounded;
  static const IconData deleteItem = Icons.delete_outline_rounded;
  static const IconData oldGoldHeader = Icons.recycling_rounded;
  static const IconData itemsCountBag = Icons.shopping_bag_outlined;
  static const IconData emptyStateSync = Icons.sync_alt_rounded;
  static const IconData addOldGold = Icons.add_circle_outline_rounded;

  // --- PAYMENT MODES & HUB ---
  static const IconData paymentHubWallet =
      Icons.account_balance_wallet_rounded; // Extracted
  static const IconData cash = Icons.payments_outlined;
  static const IconData cashFilled = Icons.payments_rounded; // Extracted
  static const IconData card = Icons.credit_card_rounded;
  static const IconData bankUpi = Icons.qr_code_scanner_rounded; // Extracted
  static const IconData advancePayment =
      Icons.account_balance_rounded; // Extracted

  // --- 🚀 NEW: STATUS & FEEDBACK ---
  static const IconData invoiceOutline = Icons.receipt_long_outlined;
  static const IconData settledVerified = Icons.verified_rounded;
  static const IconData dueWarning = Icons.warning_rounded;
  static const IconData promiseDate = Icons.event_available_rounded;
  static const IconData returnChange = Icons.published_with_changes_rounded;

  // --- USER BADGE & DROPDOWNS ---
  static const IconData profile = Icons.person_rounded;
  static const IconData logout = Icons.power_settings_new_rounded;
  static const IconData dropdownArrow = Icons.keyboard_arrow_down_rounded;
  static const IconData arrowUp = Icons.keyboard_arrow_up_rounded; // Extracted
  static const IconData arrowDown =
      Icons.keyboard_arrow_down_rounded; // Extracted
}
