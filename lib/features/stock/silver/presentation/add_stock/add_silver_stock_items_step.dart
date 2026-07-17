import 'package:flutter/material.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_stock_controller.dart';
import 'package:lotus_erp/features/stock/silver/presentation/add_stock/silver_batch_overview_card.dart';
import 'package:lotus_erp/features/stock/silver/presentation/add_stock/silver_intake_workflow_card.dart';
import 'package:lotus_erp/features/stock/silver/presentation/add_stock/silver_invoice_card.dart';
import 'package:lotus_erp/features/stock/silver/presentation/add_stock/silver_items_table.dart';
import 'package:lotus_erp/features/stock/silver/presentation/add_stock/silver_payment_record_card.dart';
import 'package:lotus_erp/features/stock/silver/presentation/add_stock/silver_purchase_valuation_card.dart';

class AddSilverStockItemsStep extends StatelessWidget {
  final SilverStockController ctrl;
  final Future<void> Function() onSave;
  final VoidCallback onResetBatch;

  const AddSilverStockItemsStep({
    super.key,
    required this.ctrl,
    required this.onSave,
    required this.onResetBatch,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktopShell = constraints.maxWidth >= 1180;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SilverIntakeWorkflowCard(ctrl: ctrl),
              const SizedBox(height: 16),
              if (desktopShell)
                _SilverDesktopWorkspace(ctrl: ctrl)
              else
                _SilverTopCards(ctrl: ctrl),
              const SizedBox(height: 16),
              SilverItemsTable(ctrl: ctrl),
              const SizedBox(height: 16),
              _SilverSettlementWorkspace(ctrl: ctrl, desktop: desktopShell),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _SilverDesktopWorkspace extends StatelessWidget {
  final SilverStockController ctrl;

  const _SilverDesktopWorkspace({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return _SilverTopCards(ctrl: ctrl);
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

class _SilverSettlementWorkspace extends StatelessWidget {
  final SilverStockController ctrl;
  final bool desktop;

  const _SilverSettlementWorkspace({required this.ctrl, required this.desktop});

  @override
  Widget build(BuildContext context) {
    if (!desktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SilverPurchaseValuationCard(ctrl: ctrl),
          const SizedBox(height: 16),
          SilverPaymentRecordCard(ctrl: ctrl),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 1340;

        if (!sideBySide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SilverPurchaseValuationCard(ctrl: ctrl),
              const SizedBox(height: 16),
              SilverPaymentRecordCard(ctrl: ctrl),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 42,
              child: SilverPurchaseValuationCard(ctrl: ctrl),
            ),
            const SizedBox(width: 16),
            Expanded(flex: 58, child: SilverPaymentRecordCard(ctrl: ctrl)),
          ],
        );
      },
    );
  }
}
