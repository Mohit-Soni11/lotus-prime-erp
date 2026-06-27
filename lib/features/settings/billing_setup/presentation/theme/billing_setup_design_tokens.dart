import 'package:flutter/material.dart';

import '../../domain/entities/billing_setup_module.dart';

class BillingSetupDesignTokens {
  BillingSetupDesignTokens._();

  static const Color canvas = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color header = Color(0xFF111827);
  static const Color headerBorder = Color(0xFF253247);
  static const Color textStrong = Color(0xFF111827);
  static const Color textBody = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color gold = Color(0xFFD4AF37);
  static const Color sales = Color(0xFF0EA5E9);
  static const Color purchase = Color(0xFF16A34A);
  static const Color girvi = Color(0xFF7C3AED);
  static const Color print = Color(0xFFE06B3F);

  static Color accentFor(BillingSetupModuleId id) {
    switch (id) {
      case BillingSetupModuleId.sales:
        return sales;
      case BillingSetupModuleId.purchase:
        return purchase;
      case BillingSetupModuleId.girvi:
        return girvi;
      case BillingSetupModuleId.printTemplates:
        return print;
    }
  }

  static IconData iconFor(BillingSetupModuleId id) {
    switch (id) {
      case BillingSetupModuleId.sales:
        return Icons.point_of_sale_rounded;
      case BillingSetupModuleId.purchase:
        return Icons.shopping_bag_outlined;
      case BillingSetupModuleId.girvi:
        return Icons.account_balance_wallet_outlined;
      case BillingSetupModuleId.printTemplates:
        return Icons.description_outlined;
    }
  }
}
