import 'package:flutter/material.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/metal_cards/customer_metal_purchase_card_shell.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/metal_cards/customer_metal_purchase_card_widgets.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class DiamondCustomerMetalPurchaseCard extends StatelessWidget {
  final AnimationController animationController;
  final double delay;
  final VoidCallback? onTap;

  const DiamondCustomerMetalPurchaseCard({
    super.key,
    required this.animationController,
    required this.delay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = PurchaseEntryColors.metalDiamond;

    return CustomerMetalPurchaseCardShell(
      animationController: animationController,
      delay: delay,
      accent: accent,
      surface: const Color(0xFFF1FAFF),
      onTap: onTap,
      child: const SizedBox(
        height: 212,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomerMetalPurchaseCardHeader(
              title: 'Diamond',
              caption: 'Customer purchase ledger',
              accent: accent,
              assetPath: 'lib/logo/diamond .jpeg',
            ),
            SizedBox(height: 16),
            CustomerMetalPurchaseInfoPanel(
              summary:
                  'Customer diamond purchases with carat and valuation focus.',
              accent: accent,
              tags: ['Carats', 'Stone value', 'Trade-in'],
            ),
            Spacer(),
            CustomerMetalPurchaseCardFooter(
              actionLabel: 'Open diamond purchases',
              accent: accent,
            ),
          ],
        ),
      ),
    );
  }
}
