import 'package:flutter/material.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/metal_cards/diamond_customer_metal_purchase_card.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/metal_cards/gold_customer_metal_purchase_card.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/metal_cards/platinum_customer_metal_purchase_card.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/metal_cards/silver_customer_metal_purchase_card.dart';

class CustomerMetalPurchaseCardGrid extends StatelessWidget {
  final AnimationController animationController;
  final Map<CustomerMetalPurchaseMetal, CustomerMetalPurchaseMetalSummary>
      summaries;
  final ValueChanged<CustomerMetalPurchaseMetal>? onMetalSelected;

  const CustomerMetalPurchaseCardGrid({
    super.key,
    required this.animationController,
    required this.summaries,
    this.onMetalSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 960
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: GoldCustomerMetalPurchaseCard(
                animationController: animationController,
                delay: 0,
                summary: summaries[CustomerMetalPurchaseMetal.gold]!,
                onTap: () =>
                    onMetalSelected?.call(CustomerMetalPurchaseMetal.gold),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: SilverCustomerMetalPurchaseCard(
                animationController: animationController,
                delay: 0.10,
                summary: summaries[CustomerMetalPurchaseMetal.silver]!,
                onTap: () =>
                    onMetalSelected?.call(CustomerMetalPurchaseMetal.silver),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: DiamondCustomerMetalPurchaseCard(
                animationController: animationController,
                delay: 0.20,
                summary: summaries[CustomerMetalPurchaseMetal.diamond]!,
                onTap: () =>
                    onMetalSelected?.call(CustomerMetalPurchaseMetal.diamond),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: PlatinumCustomerMetalPurchaseCard(
                animationController: animationController,
                delay: 0.30,
                summary: summaries[CustomerMetalPurchaseMetal.platinum]!,
                onTap: () =>
                    onMetalSelected?.call(CustomerMetalPurchaseMetal.platinum),
              ),
            ),
          ],
        );
      },
    );
  }
}
