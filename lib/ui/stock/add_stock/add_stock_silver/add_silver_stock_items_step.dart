import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_silver/silver_batch_overview_card.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_silver/silver_invoice_card.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_silver/silver_items_table.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_silver/silver_supplier_panel.dart';
import 'package:lotus_erp/ui/stock/add_stock/stock_metal_ui.dart';

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

        if (desktopShell) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SilverDesktopWorkspace(ctrl: ctrl),
                const SizedBox(height: 16),
                SilverItemsTable(ctrl: ctrl),
                const SizedBox(height: 16),
                _SilverSummaryPanel(
                  ctrl: ctrl,
                  onSave: onSave,
                  onResetBatch: onResetBatch,
                  docked: true,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SilverTopCards(ctrl: ctrl),
              const SizedBox(height: 16),
              AddSilverStockSupplierPanel(ctrl: ctrl),
              const SizedBox(height: 16),
              SilverItemsTable(ctrl: ctrl),
              const SizedBox(height: 18),
              _SilverSummaryPanel(
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

class _SilverDesktopWorkspace extends StatelessWidget {
  final SilverStockController ctrl;

  const _SilverDesktopWorkspace({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _SilverTopCards(ctrl: ctrl)),
        const SizedBox(width: 16),
        SizedBox(width: 360, child: AddSilverStockSupplierPanel(ctrl: ctrl)),
      ],
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
              Expanded(
                flex: 42,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 270),
                  child: SilverBatchOverviewCard(ctrl: ctrl),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 58,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 270),
                  child: SilverInvoiceCard(ctrl: ctrl),
                ),
              ),
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

class _SilverSummaryPanel extends StatelessWidget {
  final SilverStockController ctrl;
  final Future<void> Function() onSave;
  final VoidCallback onResetBatch;
  final bool docked;

  const _SilverSummaryPanel({
    required this.ctrl,
    required this.onSave,
    required this.onResetBatch,
    this.docked = false,
  });

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(ctrl.selectedMetal);
    final accent = ctrl.gstEnabled ? AddStockColors.success : ui.accent;

    return Container(
      decoration: BoxDecoration(
        color: AddStockColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AddStockColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AddStockColors.shadowLight,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: accent.withOpacity(0.25)),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 17,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INVOICE SUMMARY',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AddStockColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        docked
                            ? 'Full-width batch totals and save controls'
                            : 'Silver batch totals and save controls',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AddStockColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AddStockColors.cardBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final splitActions = docked && constraints.maxWidth >= 960;

                if (splitActions) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 62, child: _buildMetricsSection(accent)),
                      const SizedBox(width: 16),
                      Expanded(flex: 38, child: _buildActionsSection(accent)),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMetricsSection(accent),
                    const SizedBox(height: 14),
                    _buildActionsSection(accent),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(Color accent) {
    if (!docked) {
      return Column(
        children: [
          _summaryRow(
            'Gross Value',
            _money(ctrl.totalEstimatedCost),
            valueBold: true,
          ),
          const SizedBox(height: 10),
          _summaryRow('Estimated Sale', _money(ctrl.totalEstimatedSelling)),
          const SizedBox(height: 10),
          _summaryRow('Taxable Amount', _money(ctrl.totalTaxableAmount)),
          const SizedBox(height: 10),
          _summaryRow(
            'Entered Rows',
            '${ctrl.enteredRowCount} row${ctrl.enteredRowCount == 1 ? '' : 's'}',
          ),
          const SizedBox(height: 12),
          _buildGstCard(),
          const SizedBox(height: 12),
          _buildTotalBand(accent),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 880
                ? 4
                : constraints.maxWidth >= 520
                    ? 2
                    : 1;
            final gap = 12.0;
            final tileWidth =
                (constraints.maxWidth - ((columns - 1) * gap)) / columns;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: tileWidth,
                  child: _summaryMetricTile(
                    'Gross Value',
                    _money(ctrl.totalEstimatedCost),
                    tone: AddStockColors.accentPricing,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _summaryMetricTile(
                    'Estimated Sale',
                    _money(ctrl.totalEstimatedSelling),
                    tone: AddStockColors.accentInventory,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _summaryMetricTile(
                    'Taxable Amount',
                    _money(ctrl.totalTaxableAmount),
                    tone: accent,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _summaryMetricTile(
                    'Entered Rows',
                    '${ctrl.enteredRowCount}',
                    caption: ctrl.enteredRowCount == 1
                        ? 'silver row'
                        : 'silver rows',
                    tone: AddStockColors.textBody,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _buildGstCard(),
        const SizedBox(height: 12),
        _buildTotalBand(accent),
      ],
    );
  }

  Widget _buildGstCard() {
    if (ctrl.gstEnabled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AddStockColors.success.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AddStockColors.success.withOpacity(0.20)),
        ),
        child: Column(
          children: [
            _summaryRow('GST Rate', '${ctrl.gstRate.toStringAsFixed(1)}%'),
            const SizedBox(height: 8),
            _summaryRow(
              'CGST',
              _money(ctrl.cgstAmount),
              labelColor: AddStockColors.success,
              valueColor: AddStockColors.success,
            ),
            const SizedBox(height: 4),
            _summaryRow(
              'SGST',
              _money(ctrl.sgstAmount),
              labelColor: AddStockColors.success,
              valueColor: AddStockColors.success,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AddStockColors.inputBgLocked,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AddStockColors.cardBorder),
      ),
      alignment: Alignment.center,
      child: Text(
        'NORMAL BATCH - NO GST APPLIED',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
          color: AddStockColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildTotalBand(Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'BATCH TOTAL',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
              color: accent,
            ),
          ),
          Text(
            _money(ctrl.totalBatchAmount),
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: accent,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: docked ? AddStockColors.bodyBg : accent.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AddStockColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: ctrl.rowsWithErrorsCount == 0
                  ? accent.withOpacity(0.08)
                  : AddStockColors.dangerBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ctrl.rowsWithErrorsCount == 0
                    ? accent.withOpacity(0.18)
                    : AddStockColors.danger.withOpacity(0.20),
              ),
            ),
            child: Text(
              ctrl.rowsWithErrorsCount == 0
                  ? 'Ready to save - ${ctrl.enteredRowCount} entered row${ctrl.enteredRowCount == 1 ? '' : 's'}'
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
                color: AddStockColors.danger.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AddStockColors.danger.withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 14,
                    color: AddStockColors.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ctrl.errorMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AddStockColors.danger,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackButtons = constraints.maxWidth < 280;

              if (stackButtons) {
                return Column(
                  children: [
                    _backButton(accent),
                    const SizedBox(height: 10),
                    _resetButton(),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: _backButton(accent)),
                  const SizedBox(width: 10),
                  Expanded(child: _resetButton()),
                ],
              );
            },
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
                      Icons.inventory_2_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
              label: Text(
                ctrl.isSaving ? AddStockStrings.btnSaving : 'SAVE SILVER BATCH',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                disabledBackgroundColor: accent.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton(Color accent) {
    return OutlinedButton(
      onPressed: ctrl.prevStep,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: accent.withOpacity(0.35)),
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

  Widget _summaryMetricTile(
    String title,
    String value, {
    required Color tone,
    String? caption,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
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
              color: AddStockColors.textDark,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AddStockColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool valueBold = false,
    Color? labelColor,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: labelColor ?? AddStockColors.textBody,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: valueBold ? 15 : 13,
            fontWeight: valueBold ? FontWeight.w800 : FontWeight.w700,
            color: valueColor ?? AddStockColors.textDark,
          ),
        ),
      ],
    );
  }
}

String _money(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}
