import 'package:flutter/material.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/report_metal_cards/customer_metal_purchase_report_metal_card.dart';

class CustomerMetalPurchaseMetalCardGrid extends StatelessWidget {
  final String periodLabel;
  final Map<CustomerMetalPurchaseMetal, CustomerMetalPurchaseMetalSummary>
      summaries;
  final CustomerMetalPurchaseMetal? selectedMetal;
  final AnimationController animationController;
  final ValueChanged<CustomerMetalPurchaseMetal?> onMetalSelected;

  const CustomerMetalPurchaseMetalCardGrid({
    super.key,
    required this.periodLabel,
    required this.summaries,
    required this.selectedMetal,
    required this.animationController,
    required this.onMetalSelected,
  });

  @override
  Widget build(BuildContext context) {
    final entries = summaries.entries.toList(growable: false)
      ..sort((left, right) => left.key.index.compareTo(right.key.index));

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;
        final columns = constraints.maxWidth >= 900 ? 2 : 1;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final entry in entries)
              SizedBox(
                width: width,
                child: CustomerMetalPurchaseReportMetalCard(
                  periodLabel: periodLabel,
                  summary: entry.value,
                  selected: selectedMetal == entry.key,
                  onTap: () => onMetalSelected(
                    selectedMetal == entry.key ? null : entry.key,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
