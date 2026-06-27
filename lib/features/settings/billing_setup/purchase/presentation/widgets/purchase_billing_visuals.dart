import 'package:flutter/material.dart';

import '../../../../../../../models/setting/billing_setup/sales_billing_model.dart';

class PurchaseBillingVisuals {
  PurchaseBillingVisuals._();

  static Color accentFor(String metal) {
    switch (metal) {
      case BillingMetal.gold:
        return const Color(0xFFB8860B);
      case BillingMetal.silver:
        return const Color(0xFF64748B);
      case BillingMetal.diamond:
        return const Color(0xFF0EA5E9);
      case BillingMetal.platinum:
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF334155);
    }
  }

  static IconData iconFor(String metal) {
    switch (metal) {
      case BillingMetal.gold:
        return Icons.workspace_premium_rounded;
      case BillingMetal.silver:
        return Icons.toll_rounded;
      case BillingMetal.diamond:
        return Icons.diamond_outlined;
      case BillingMetal.platinum:
        return Icons.radio_button_checked_rounded;
      default:
        return Icons.shopping_bag_outlined;
    }
  }
}
