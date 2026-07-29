import 'package:flutter/material.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/metal_cards/customer_metal_purchase_card_shell.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/metal_cards/customer_metal_purchase_card_widgets.dart';

class PlatinumCustomerMetalPurchaseCard extends StatelessWidget {
  final AnimationController animationController;
  final double delay;
  final CustomerMetalPurchaseMetalSummary summary;
  final VoidCallback? onTap;

  const PlatinumCustomerMetalPurchaseCard({
    super.key,
    required this.animationController,
    required this.delay,
    required this.summary,
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
      child: SizedBox(
        height: 292,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomerMetalPurchaseCardHeader(
              title: 'Platinum',
              caption: 'Customer Metal Settlement',
              accent: accent,
              assetPath: 'lib/logo/silver and platinum .jpeg',
            ),
            const SizedBox(height: 16),
            CustomerMetalPurchaseSummaryPanel(
              summary: summary,
              accent: accent,
            ),
            const Spacer(),
            CustomerMetalPurchaseCardFooter(
              actionLabel: 'Open platinum settlement',
              accent: accent,
              summary: summary,
            ),
          ],
        ),
      ),
    );
  }
}
