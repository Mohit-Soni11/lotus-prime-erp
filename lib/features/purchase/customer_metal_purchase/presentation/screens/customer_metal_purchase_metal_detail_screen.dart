import 'package:flutter/material.dart';

import 'package:lotus_erp/features/purchase/customer_metal_purchase/application/customer_metal_purchase_ledger_models.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/domain/entities/customer_metal_purchase_entry.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_empty_state.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_entry_card.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_ledger_app_bar.dart';
import 'package:lotus_erp/features/purchase/customer_metal_purchase/presentation/widgets/customer_metal_purchase_summary_strip.dart';
import 'package:lotus_erp/theme/purchase/purchase_entry/purchase_entry_theme.dart';

class CustomerMetalPurchaseMetalDetailScreen extends StatelessWidget {
  final CustomerMetalPurchaseMetal metal;
  final CustomerMetalPurchaseMetalSummary summary;
  final List<CustomerMetalPurchaseEntry> entries;

  const CustomerMetalPurchaseMetalDetailScreen({
    super.key,
    required this.metal,
    required this.summary,
    required this.entries,
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
        child: SingleChildScrollView(
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
                    );
                  },
                ),
            ],
          ),
        ),
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
