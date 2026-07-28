import 'package:flutter/material.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/metal_cards/customer_metal_purchase_card_shell.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/metal_cards/customer_metal_purchase_card_widgets.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class DiamondCustomerMetalPurchaseCard extends StatelessWidget {
  final AnimationController animationController;
  final double delay;
  final CustomerMetalPurchaseMetalSummary summary;
  final VoidCallback? onTap;

  const DiamondCustomerMetalPurchaseCard({
    super.key,
    required this.animationController,
    required this.delay,
    required this.summary,
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
      child: SizedBox(
        height: 292,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomerMetalPurchaseCardHeader(
              title: 'Diamond',
              caption: 'Customer Metal Purchase',
              accent: accent,
              assetPath: 'lib/logo/diamond .jpeg',
            ),
            const SizedBox(height: 16),
            CustomerMetalPurchaseSummaryPanel(
              summary: summary,
              accent: accent,
            ),
            const Spacer(),
            CustomerMetalPurchaseCardFooter(
              actionLabel: 'Open diamond ledger',
              accent: accent,
              summary: summary,
            ),
          ],
        ),
      ),
    );
  }
}
