import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_invoice_summary_logic.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_gold/gold_stock_theme.dart';

class GoldBatchActionBar extends StatelessWidget {
  final GoldStockController ctrl;
  final Future<void> Function() onSave;
  final VoidCallback onDoneExit;
  final VoidCallback onResetBatch;

  const GoldBatchActionBar({
    super.key,
    required this.ctrl,
    required this.onSave,
    required this.onDoneExit,
    required this.onResetBatch,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ctrl, ctrl.payment]),
      builder: (context, _) {
        final summary = ctrl.invoiceSummary;
        final snapshot = ctrl.paymentSnapshot;
        final accent = ctrl.gstEnabled
            ? GoldStockColors.success
            : GoldStockColors.paymentPrimary;

        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
            decoration: const BoxDecoration(
              color: GoldStockColors.cardBg,
              border: Border(
                top: BorderSide(color: GoldStockColors.cardBorder),
              ),
              boxShadow: [
                BoxShadow(
                  color: GoldStockColors.shadowMedium,
                  blurRadius: 18,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 1080;

                if (compact) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _metricTiles(summary, snapshot),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ActionButtons(
                        ctrl: ctrl,
                        onSave: onSave,
                        onDoneExit: onDoneExit,
                        onResetBatch: onResetBatch,
                        accent: accent,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _metricTiles(summary, snapshot),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 650,
                      child: _ActionButtons(
                        ctrl: ctrl,
                        onSave: onSave,
                        onDoneExit: onDoneExit,
                        onResetBatch: onResetBatch,
                        accent: accent,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  List<Widget> _metricTiles(
    GoldInvoiceSummaryData summary,
    GoldPaymentSnapshot snapshot,
  ) {
    final balanceIcon = snapshot.hasFineReturn
        ? GoldStockIcons.fineWeight
        : snapshot.hasSupplierCredit
            ? Icons.savings_rounded
            : snapshot.hasReturn
                ? GoldStockIcons.returnBalance
                : GoldStockIcons.dueBalance;
    final balanceLabel = snapshot.hasFineReturn
        ? 'Fine Return'
        : snapshot.hasSupplierCredit
            ? 'Supplier Credit'
            : snapshot.hasReturn
                ? GoldStockStrings.supplierReturnLabel
                : snapshot.hasFineDue
                    ? 'Cash Due'
                    : GoldStockStrings.currentDueLabel;
    final balanceValue = snapshot.hasFineReturn
        ? '${snapshot.fineReturnWeight.toStringAsFixed(3)} g'
        : snapshot.hasSupplierCredit
            ? '${snapshot.supplierCreditFineWeight.toStringAsFixed(3)} g'
            : snapshot.hasReturn
                ? _money(snapshot.returnAmount)
                : _money(snapshot.dueAmount);
    final balanceTone = snapshot.hasReturn
        ? GoldStockColors.paymentReturn
        : snapshot.hasDue
            ? GoldStockColors.paymentDue
            : GoldStockColors.success;

    return [
      _FooterMetric(
        icon: GoldStockIcons.lineSnapshot,
        label: GoldStockStrings.itemSnapshotTotalLabel,
        value: _money(summary.itemSnapshotAmount),
        tone: GoldStockColors.paymentPrimary,
      ),
      const SizedBox(width: 12),
      _FooterMetric(
        icon: GoldStockIcons.invoiceSummary,
        label: GoldStockStrings.finalBillAmountLabel,
        value: _money(snapshot.totalBillAmount),
        tone: summary.gstEnabled
            ? GoldStockColors.success
            : GoldStockColors.paymentPrimary,
      ),
      const SizedBox(width: 12),
      _FooterMetric(
        icon: GoldStockIcons.amountReceived,
        label: GoldStockStrings.totalReceivedLabel,
        value: _money(snapshot.totalPaidValue),
        tone: GoldStockColors.success,
      ),
      const SizedBox(width: 12),
      _FooterMetric(
        icon: balanceIcon,
        label: balanceLabel,
        value: balanceValue,
        tone: balanceTone,
      ),
      if (snapshot.hasFineDue) ...[
        const SizedBox(width: 12),
        _FooterMetric(
          icon: GoldStockIcons.fineWeight,
          label: 'Fine Due',
          value: '${snapshot.fineDueWeight.toStringAsFixed(3)} g',
          tone: GoldStockColors.paymentDue,
        ),
      ],
    ];
  }
}

class _FooterMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tone;

  const _FooterMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 188,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tone, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: GoldStockColors.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: GoldStockColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final GoldStockController ctrl;
  final Future<void> Function() onSave;
  final VoidCallback onDoneExit;
  final VoidCallback onResetBatch;
  final Color accent;

  const _ActionButtons({
    required this.ctrl,
    required this.onSave,
    required this.onDoneExit,
    required this.onResetBatch,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final posted = ctrl.isCurrentBatchPosted;
    return Row(
      children: [
        Expanded(
          child: _SecondaryButton(
            icon: Icons.arrow_back_rounded,
            label: AddStockStrings.btnBackPurity,
            onTap: ctrl.prevStep,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SecondaryButton(
            icon: GoldStockIcons.reset,
            label: AddStockStrings.btnResetBatch,
            onTap: onResetBatch,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: ctrl.isSaving ? null : (posted ? onDoneExit : onSave),
              icon: ctrl.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      posted ? Icons.done_all_rounded : GoldStockIcons.save,
                      size: 18,
                    ),
              label: Text(
                ctrl.isSaving
                    ? AddStockStrings.btnSaving
                    : posted
                        ? AddStockStrings.btnDone
                        : 'Save Gold Batch',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: accent,
                disabledBackgroundColor: accent.withValues(alpha: 0.48),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: GoldStockColors.textBody,
          side: const BorderSide(color: GoldStockColors.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

String _money(double amount) {
  return 'Rs ${amount.toStringAsFixed(2)}';
}
