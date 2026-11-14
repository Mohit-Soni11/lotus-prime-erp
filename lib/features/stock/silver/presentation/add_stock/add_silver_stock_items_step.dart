import 'package:flutter/material.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_stock_controller.dart';
import 'package:lotus_erp/features/stock/silver/presentation/add_stock/silver_batch_overview_card.dart';
import 'package:lotus_erp/features/stock/silver/presentation/add_stock/silver_intake_workflow_card.dart';
import 'package:lotus_erp/features/stock/silver/presentation/add_stock/silver_invoice_card.dart';
import 'package:lotus_erp/features/stock/silver/presentation/add_stock/silver_items_table.dart';
import 'package:lotus_erp/features/stock/silver/presentation/add_stock/silver_purchase_valuation_card.dart';

class AddSilverStockItemsStep extends StatelessWidget {
  final SilverStockController ctrl;
  const AddSilverStockItemsStep({
    super.key,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SilverIntakeWorkflowCard(ctrl: ctrl),
          const SizedBox(height: 16),
          _SilverTopCards(ctrl: ctrl),
          const SizedBox(height: 16),
          SilverItemsTable(ctrl: ctrl),
          const SizedBox(height: 16),
          SilverPurchaseValuationCard(ctrl: ctrl),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SilverTopCards extends StatelessWidget {
  final SilverStockController ctrl;

  const _SilverTopCards({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth > 760;

        if (sideBySide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 42, child: SilverBatchOverviewCard(ctrl: ctrl)),
              const SizedBox(width: 16),
              Expanded(flex: 58, child: SilverInvoiceCard(ctrl: ctrl)),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SilverBatchOverviewCard(ctrl: ctrl),
            const SizedBox(height: 12),
            SilverInvoiceCard(ctrl: ctrl),
          ],
        );
      },
    );
  }
}
