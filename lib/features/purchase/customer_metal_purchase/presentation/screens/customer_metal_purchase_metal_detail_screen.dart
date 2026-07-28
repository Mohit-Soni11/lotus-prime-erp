import 'package:flutter/material.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_controller.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_empty_state.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_entry_card.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_ledger_app_bar.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_summary_strip.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class CustomerMetalPurchaseMetalDetailScreen extends StatelessWidget {
  final CustomerMetalPurchaseMetal metal;
  final CustomerMetalPurchaseLedgerController controller;

  const CustomerMetalPurchaseMetalDetailScreen({
    super.key,
    required this.metal,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(metal);

    return Scaffold(
      backgroundColor: PurchaseEntryColors.bodyBg,
      appBar: CustomerMetalPurchaseLedgerAppBar(
        title: '${metal.label} Customer Purchase Details',
        onBack: () => Navigator.maybePop(context),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final summary = controller.summaryForMetal(metal);
            final entries = controller.entriesForMetal(
              metal,
              includeReturned: true,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                children: [
                  CustomerMetalPurchaseSummaryStrip(
                    summary: summary,
                    accent: accent,
                  ),
                  const SizedBox(height: 16),
                  if (entries.isEmpty)
                    CustomerMetalPurchaseEmptyState(
                      message:
                          'No ${metal.label.toLowerCase()} customer purchase records found.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return CustomerMetalPurchaseEntryCard(
                          entry: entries[index],
                          accent: accent,
                          onReturnPressed: () => _confirmReturn(
                            context,
                            entries[index],
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmReturn(
    BuildContext context,
    CustomerMetalPurchaseEntry entry,
  ) async {
    if (entry.isReturned) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Return Customer Metal'),
          content: Text(
            'Mark ${entry.referenceNo} as returned to ${entry.customerName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm Return'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await controller.markReturned(entry);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${entry.referenceNo} marked as returned.'),
      ),
    );
  }

  Color _accentFor(CustomerMetalPurchaseMetal metal) {
    switch (metal) {
      case CustomerMetalPurchaseMetal.gold:
        return PurchaseEntryColors.metalGold;
      case CustomerMetalPurchaseMetal.silver:
        return PurchaseEntryColors.metalSilver;
      case CustomerMetalPurchaseMetal.diamond:
        return PurchaseEntryColors.metalDiamond;
      case CustomerMetalPurchaseMetal.platinum:
        return PurchaseEntryColors.metalPlatinum;
    }
  }
}
