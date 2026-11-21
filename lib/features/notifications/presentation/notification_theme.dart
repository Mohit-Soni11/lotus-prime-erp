import 'package:flutter/material.dart';

abstract final class NotificationTheme {
  static const background = Color(0xFF111827);
  static const shell = Color(0xFF111827);
  static const ink = Color(0xFFF9FAFB);
  static const muted = Color(0xFF9CA3AF);
  static const border = Color(0xFF374151);
  static const gold = Color(0xFFD4AF37);
  static const red = Color(0xFFEF4444);
  static Color accent(String category) => switch (category) {
        'Inventory' => gold,
        'Orders' => const Color(0xFF60A5FA),
        'Collections' => red,
        'Girvi' => const Color(0xFFC084FC),
        'Day Book' => const Color(0xFF34D399),
        'Metal Rates' => gold,
        _ => muted,
      };
  static IconData icon(String category) => switch (category) {
        'Inventory' => Icons.inventory_2_outlined,
        'Orders' => Icons.local_shipping_outlined,
        'Collections' => Icons.payments_outlined,
        'Girvi' => Icons.account_balance_outlined,
        'Day Book' => Icons.fact_check_outlined,
        'Metal Rates' => Icons.currency_exchange_rounded,
        _ => Icons.notifications_outlined,
      };
}
