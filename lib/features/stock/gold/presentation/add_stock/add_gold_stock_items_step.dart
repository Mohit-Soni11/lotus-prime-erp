import 'package:flutter/material.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_stock_controller.dart';
import 'package:lotus_erp/features/stock/gold/presentation/add_stock/gold_batch_overview_card.dart';
import 'package:lotus_erp/features/stock/gold/presentation/add_stock/gold_intake_workflow_card.dart';
import 'package:lotus_erp/features/stock/gold/presentation/add_stock/gold_invoice_card.dart';
import 'package:lotus_erp/features/stock/gold/presentation/add_stock/gold_items_table.dart';
import 'package:lotus_erp/features/stock/gold/presentation/add_stock/gold_purchase_valuation_card.dart';

class AddGoldStockItemsStep extends StatelessWidget {
  final GoldStockController ctrl;
  const AddGoldStockItemsStep({
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
          GoldIntakeWorkflowCard(ctrl: ctrl),
          const SizedBox(height: 16),
          _GoldTopCards(ctrl: ctrl),
          const SizedBox(height: 16),
          GoldItemsTable(ctrl: ctrl),
          const SizedBox(height: 16),
          GoldPurchaseValuationCard(ctrl: ctrl),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _GoldTopCards extends StatelessWidget {
  final GoldStockController ctrl;

  const _GoldTopCards({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth > 760;

        if (sideBySide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 42, child: GoldBatchOverviewCard(ctrl: ctrl)),
              const SizedBox(width: 16),
              Expanded(flex: 58, child: GoldInvoiceCard(ctrl: ctrl)),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GoldBatchOverviewCard(ctrl: ctrl),
            const SizedBox(height: 12),
            GoldInvoiceCard(ctrl: ctrl),
          ],
        );
      },
    );
  }
}
