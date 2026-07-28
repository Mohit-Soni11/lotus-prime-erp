import 'package:flutter/material.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/metal_cards/customer_metal_purchase_card_shell.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/metal_cards/customer_metal_purchase_card_widgets.dart';

class SilverCustomerMetalPurchaseCard extends StatelessWidget {
  final AnimationController animationController;
  final double delay;
  final VoidCallback? onTap;

  const SilverCustomerMetalPurchaseCard({
    super.key,
    required this.animationController,
    required this.delay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF748A98);

    return CustomerMetalPurchaseCardShell(
      animationController: animationController,
      delay: delay,
      accent: accent,
      surface: const Color(0xFFF5F8FA),
      onTap: onTap,
      child: const SizedBox(
        height: 212,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomerMetalPurchaseCardHeader(
              title: 'Silver',
              caption: 'Customer purchase ledger',
              accent: accent,
              assetPath: 'lib/logo/silver and platinum .jpeg',
            ),
            SizedBox(height: 16),
            CustomerMetalPurchaseInfoPanel(
              summary:
                  'Direct customer purchases and sales trade-in silver records.',
              accent: accent,
              tags: ['Gross weight', 'Fine weight', '999 / 925 / 800'],
            ),
            Spacer(),
            CustomerMetalPurchaseCardFooter(
              actionLabel: 'Open silver purchases',
              accent: accent,
            ),
          ],
        ),
      ),
    );
  }
}
