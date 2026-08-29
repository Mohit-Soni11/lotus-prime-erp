import 'package:flutter/material.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class CustomerMetalPurchaseMetalVisuals {
  final Color accent;
  final Color softSurface;
  final Color softTint;
  final IconData fallbackIcon;
  final String assetPath;

  const CustomerMetalPurchaseMetalVisuals({
    required this.accent,
    required this.softSurface,
    required this.softTint,
    required this.fallbackIcon,
    required this.assetPath,
  });
}

CustomerMetalPurchaseMetalVisuals visualsForCustomerPurchaseMetal(
  CustomerMetalPurchaseMetal metal,
) {
  switch (metal) {
    case CustomerMetalPurchaseMetal.gold:
      return const CustomerMetalPurchaseMetalVisuals(
        accent: PurchaseEntryColors.metalGold,
        softSurface: Color(0xFFFFFBF2),
        softTint: Color(0xFFFFF2C6),
        fallbackIcon: Icons.workspace_premium_rounded,
        assetPath: 'lib/logo/gold.jpeg',
      );
    case CustomerMetalPurchaseMetal.silver:
      return const CustomerMetalPurchaseMetalVisuals(
        accent: PurchaseEntryColors.metalSilver,
        softSurface: Color(0xFFF5F8FA),
        softTint: Color(0xFFD8E4EB),
        fallbackIcon: Icons.toll_rounded,
        assetPath: 'lib/logo/silver and platinum .jpeg',
      );
    case CustomerMetalPurchaseMetal.diamond:
      return const CustomerMetalPurchaseMetalVisuals(
        accent: PurchaseEntryColors.metalDiamond,
        softSurface: Color(0xFFF1FAFF),
        softTint: Color(0xFFCAEEFF),
        fallbackIcon: Icons.auto_awesome_rounded,
        assetPath: 'lib/logo/diamond .jpeg',
      );
    case CustomerMetalPurchaseMetal.platinum:
      return const CustomerMetalPurchaseMetalVisuals(
        accent: PurchaseEntryColors.metalPlatinum,
        softSurface: Color(0xFFF4F6F8),
        softTint: Color(0xFFD9E1E6),
        fallbackIcon: Icons.radio_button_checked_rounded,
        assetPath: 'lib/logo/silver and platinum .jpeg',
      );
  }
}
