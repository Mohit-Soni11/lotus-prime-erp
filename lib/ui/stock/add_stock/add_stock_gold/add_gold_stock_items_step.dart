import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/logic/stock/add_stock_gold/gold_invoice_summary_logic.dart';
import 'package:lotus_erp/logic/stock/add_stock_gold/gold_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_gold/gold_stock_theme.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_gold/gold_batch_overview_card.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_gold/gold_invoice_card.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_gold/gold_invoice_summary_panel.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_gold/gold_items_table.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_gold/gold_payment_record_card.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_gold/gold_supplier_panel.dart';

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
              const SizedBox(height: 16),
              _GoldBatchActionsPanel(
                ctrl: ctrl,
                onSave: onSave,
                onResetBatch: onResetBatch,
              ),
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

class _GoldBatchActionsPanel extends StatelessWidget {
  final GoldStockController ctrl;
  final Future<void> Function() onSave;
  final VoidCallback onResetBatch;

  const _GoldBatchActionsPanel({
    required this.ctrl,
    required this.onSave,
    required this.onResetBatch,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ctrl, ctrl.payment]),
      builder: (context, _) {
        final summary = ctrl.invoiceSummary;
        final accent = ctrl.gstEnabled
            ? GoldStockColors.success
            : GoldStockColors.paymentPrimary;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GoldStockColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: GoldStockColors.cardBorder),
            boxShadow: const [
              BoxShadow(
                color: GoldStockColors.shadowLight,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 980;

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SummaryBand(ctrl: ctrl, summary: summary, accent: accent),
                    const SizedBox(height: 14),
                    _ActionColumn(
                      ctrl: ctrl,
                      onSave: onSave,
                      onResetBatch: onResetBatch,
                      accent: accent,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 58,
                    child: _SummaryBand(
                      ctrl: ctrl,
                      summary: summary,
                      accent: accent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 42,
                    child: _ActionColumn(
                      ctrl: ctrl,
                      onSave: onSave,
                      onResetBatch: onResetBatch,
                      accent: accent,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _SummaryBand extends StatelessWidget {
  final GoldStockController ctrl;
  final GoldInvoiceSummaryData summary;
  final Color accent;

  const _SummaryBand({
    required this.ctrl,
    required this.summary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final snapshot = ctrl.paymentSnapshot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          GoldStockStrings.readyToSave.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.9,
            color: GoldStockColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ActionMetric(
              label: GoldStockStrings.itemSnapshotTotalLabel,
              value: _money(summary.itemSnapshotAmount),
              tone: GoldStockColors.accentPricing,
            ),
            _ActionMetric(
              label: GoldStockStrings.finalBillAmountLabel,
              value: _money(snapshot.totalBillAmount),
              tone: accent,
            ),
            _ActionMetric(
              label: GoldStockStrings.totalReceivedLabel,
              value: _money(snapshot.totalPaidValue),
              tone: GoldStockColors.paymentFine,
            ),
            _ActionMetric(
              label: snapshot.hasReturn
                  ? GoldStockStrings.supplierReturnLabel
                  : GoldStockStrings.currentDueLabel,
              value: snapshot.hasReturn
                  ? _money(snapshot.returnAmount)
                  : _money(snapshot.dueAmount),
              tone: snapshot.hasReturn
                  ? GoldStockColors.paymentReturn
                  : snapshot.hasDue
                      ? GoldStockColors.paymentDue
                      : GoldStockColors.success,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionColumn extends StatelessWidget {
  final GoldStockController ctrl;
  final Future<void> Function() onSave;
  final VoidCallback onResetBatch;
  final Color accent;

  const _ActionColumn({
    required this.ctrl,
    required this.onSave,
    required this.onResetBatch,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: ctrl.rowsWithErrorsCount == 0
                ? accent.withValues(alpha: 0.08)
                : AddStockColors.dangerBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ctrl.rowsWithErrorsCount == 0
                  ? accent.withValues(alpha: 0.18)
                  : AddStockColors.danger.withValues(alpha: 0.20),
            ),
          ),
          child: Text(
            ctrl.rowsWithErrorsCount == 0
                ? 'Ready to save ${ctrl.enteredRowCount} Gold item${ctrl.enteredRowCount == 1 ? '' : 's'}'
                : '${ctrl.rowsWithErrorsCount} row${ctrl.rowsWithErrorsCount == 1 ? '' : 's'} need attention',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ctrl.rowsWithErrorsCount == 0
                  ? accent
                  : AddStockColors.danger,
            ),
          ),
        ),
        if (ctrl.errorMessage != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AddStockColors.danger.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AddStockColors.danger.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              ctrl.errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AddStockColors.danger,
                height: 1.45,
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _backButton()),
            const SizedBox(width: 10),
            Expanded(child: _resetButton()),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: ctrl.isSaving ? null : onSave,
            icon: ctrl.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    GoldStockIcons.save,
                    size: 18,
                    color: Colors.white,
                  ),
            label: Text(
              ctrl.isSaving ? AddStockStrings.btnSaving : 'SAVE Gold BATCH',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              disabledBackgroundColor: accent.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _backButton() {
    return OutlinedButton(
      onPressed: ctrl.prevStep,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: accent.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(
        AddStockStrings.btnBackPurity,
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: accent),
      ),
    );
  }

  Widget _resetButton() {
    return OutlinedButton(
      onPressed: onResetBatch,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AddStockColors.cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(
        AddStockStrings.btnResetBatch,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: AddStockColors.textBody,
        ),
      ),
    );
  }
}

class _ActionMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color tone;

  const _ActionMetric({
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
              color: tone,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: GoldStockColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

String _money(double amount) {
  return 'Rs ${amount.toStringAsFixed(2)}';
}
