import 'package:flutter/material.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_stock_controller.dart';
import 'package:lotus_erp/features/stock/gold/presentation/add_stock/gold_batch_overview_card.dart';
import 'package:lotus_erp/features/stock/gold/presentation/add_stock/gold_invoice_card.dart';
import 'package:lotus_erp/features/stock/gold/presentation/add_stock/gold_invoice_summary_panel.dart';
import 'package:lotus_erp/features/stock/gold/presentation/add_stock/gold_items_table.dart';
import 'package:lotus_erp/features/stock/gold/presentation/add_stock/gold_payment_record_card.dart';
import 'package:lotus_erp/features/stock/gold/presentation/add_stock/gold_supplier_panel.dart';

class AddGoldStockItemsStep extends StatelessWidget {
  final GoldStockController ctrl;
  final Future<void> Function() onSave;
  final VoidCallback onResetBatch;

  const AddGoldStockItemsStep({
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
              if (desktopShell)
                _GoldDesktopWorkspace(ctrl: ctrl)
              else ...[
                _GoldTopCards(ctrl: ctrl),
                const SizedBox(height: 16),
                AddGoldStockSupplierPanel(ctrl: ctrl),
              ],
              const SizedBox(height: 16),
              GoldItemsTable(ctrl: ctrl),
              const SizedBox(height: 16),
              _GoldSettlementWorkspace(ctrl: ctrl, desktop: desktopShell),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _GoldDesktopWorkspace extends StatelessWidget {
  final GoldStockController ctrl;

  const _GoldDesktopWorkspace({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _GoldTopCards(ctrl: ctrl)),
        const SizedBox(width: 16),
        SizedBox(width: 360, child: AddGoldStockSupplierPanel(ctrl: ctrl)),
      ],
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

class _GoldSettlementWorkspace extends StatelessWidget {
  final GoldStockController ctrl;
  final bool desktop;

  const _GoldSettlementWorkspace({required this.ctrl, required this.desktop});

  @override
  Widget build(BuildContext context) {
    if (!desktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ✨ FIXED: Updated Constructor Parameter
          GoldPaymentRecordCard(ctrl: ctrl),
          const SizedBox(height: 16),
          GoldInvoiceSummaryPanel(ctrl: ctrl),
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
              // ✨ FIXED: Updated Constructor Parameter
              GoldPaymentRecordCard(ctrl: ctrl),
              const SizedBox(height: 16),
              GoldInvoiceSummaryPanel(ctrl: ctrl),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 58,
              // ✨ FIXED: Updated Constructor Parameter
              child: GoldPaymentRecordCard(ctrl: ctrl),
            ),
            const SizedBox(width: 16),
            Expanded(flex: 42, child: GoldInvoiceSummaryPanel(ctrl: ctrl)),
          ],
        );
      },
    );
  }
}
