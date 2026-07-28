import 'package:flutter/material.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/metal_cards/customer_metal_purchase_card_shell.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/metal_cards/customer_metal_purchase_card_widgets.dart';

class PlatinumCustomerMetalPurchaseCard extends StatelessWidget {
  final AnimationController animationController;
  final double delay;
  final VoidCallback? onTap;

  const PlatinumCustomerMetalPurchaseCard({
    super.key,
    required this.animationController,
    required this.delay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF586E7C);

    return CustomerMetalPurchaseCardShell(
      animationController: animationController,
      delay: delay,
      accent: accent,
      surface: const Color(0xFFF4F6F8),
      onTap: onTap,
      child: const SizedBox(
        height: 212,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomerMetalPurchaseCardHeader(
              title: 'Platinum',
              caption: 'Customer purchase ledger',
              accent: accent,
              assetPath: 'lib/logo/silver and platinum .jpeg',
            ),
            SizedBox(height: 16),
            CustomerMetalPurchaseInfoPanel(
              summary:
                  'High-value platinum purchases with precise fine weight records.',
              accent: accent,
              tags: ['Fine weight', '950 / 900 / 850', 'Trade-in'],
            ),
            Spacer(),
            CustomerMetalPurchaseCardFooter(
              actionLabel: 'Open platinum purchases',
              accent: accent,
            ),
          ],
        ),
      ),
    );
  }
}
