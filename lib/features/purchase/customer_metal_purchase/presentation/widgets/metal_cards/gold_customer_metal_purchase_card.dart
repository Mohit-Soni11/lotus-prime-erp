import 'package:flutter/material.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/metal_cards/customer_metal_purchase_card_shell.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/metal_cards/customer_metal_purchase_card_widgets.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class GoldCustomerMetalPurchaseCard extends StatelessWidget {
  final AnimationController animationController;
  final double delay;
  final VoidCallback? onTap;

  const GoldCustomerMetalPurchaseCard({
    super.key,
    required this.animationController,
    required this.delay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = PurchaseEntryColors.metalGold;

    return CustomerMetalPurchaseCardShell(
      animationController: animationController,
      delay: delay,
      accent: accent,
      surface: const Color(0xFFFFFBF2),
      onTap: onTap,
      child: const SizedBox(
        height: 212,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomerMetalPurchaseCardHeader(
              title: 'Gold',
              caption: 'Customer purchase ledger',
              accent: accent,
              assetPath: 'lib/logo/gold.jpeg',
            ),
            SizedBox(height: 16),
            CustomerMetalPurchaseInfoPanel(
              summary:
                  'Direct customer purchases and sales trade-in gold records.',
              accent: accent,
              tags: ['Gross weight', 'Fine weight', '22K / 18K / 24K'],
            ),
            Spacer(),
            CustomerMetalPurchaseCardFooter(
              actionLabel: 'Open gold purchases',
              accent: accent,
            ),
          ],
        ),
      ),
    );
  }
}
