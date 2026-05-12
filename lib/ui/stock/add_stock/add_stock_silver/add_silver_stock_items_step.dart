import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_item_row_card.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_supplier_autocomplete.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_silver/silver_batch_overview_card.dart';
import 'package:lotus_erp/ui/stock/add_stock/add_stock_silver/silver_invoice_card.dart';
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
        final desktopShell = constraints.maxWidth >= 1100;

        if (desktopShell) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 70,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _LeftSilverPane(ctrl: ctrl),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 30,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _SilverSummaryPanel(
                      ctrl: ctrl,
                      onSave: onSave,
                      onResetBatch: onResetBatch,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _LeftSilverPane(ctrl: ctrl),
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

class _LeftSilverPane extends StatelessWidget {
  final SilverStockController ctrl;

  const _LeftSilverPane({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final sideBySide = constraints.maxWidth > 720;

            if (sideBySide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 45,
                    child: SilverBatchOverviewCard(ctrl: ctrl),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 55,
                    child: SilverInvoiceCard(ctrl: ctrl),
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
        ),
        const SizedBox(height: 16),
        _SilverSupplierSessionCard(ctrl: ctrl),
        const SizedBox(height: 16),
        _SilverItemsEntryCard(ctrl: ctrl),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SilverSupplierSessionCard extends StatelessWidget {
  final SilverStockController ctrl;

  const _SilverSupplierSessionCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(ctrl.selectedMetal);
    final infoChips = <Widget>[
      if (ctrl.supplierMobileCtrl.text.trim().isNotEmpty)
        _miniInfoChip(
          icon: Icons.phone_iphone_rounded,
          label: ctrl.supplierMobileCtrl.text.trim(),
          color: AddStockColors.accentBasicInfo,
        ),
      if (ctrl.supplierGstCtrl.text.trim().isNotEmpty)
        _miniInfoChip(
          icon: Icons.receipt_long_rounded,
          label: ctrl.supplierGstCtrl.text.trim(),
          color: AddStockColors.success,
        ),
      if (ctrl.supplierRegionCtrl.text.trim().isNotEmpty)
        _miniInfoChip(
          icon: Icons.location_on_outlined,
          label: ctrl.supplierRegionCtrl.text.trim(),
          color: ui.accent,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AddStockColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AddStockColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AddStockColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AddStockColors.accentBasicInfo.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AddStockColors.accentBasicInfo.withOpacity(0.22),
                  ),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  size: 18,
                  color: AddStockColors.accentBasicInfo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SUPPLIER SESSION',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: AddStockColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Choose one supplier for the whole silver batch or unlock item-wise override.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        height: 1.45,
                        color: AddStockColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'SAME FOR ALL',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                      color: AddStockColors.textMuted,
                    ),
                  ),
                  Switch.adaptive(
                    value: ctrl.sameForAll,
                    onChanged: ctrl.setSameForAll,
                    activeColor: ui.accent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          AddStockSupplierAutocomplete(
            label: AddStockStrings.supplierSession,
            suppliers: ctrl.suppliers,
            initialName: ctrl.sessionSupplierName,
            onSelected: ctrl.setSessionSupplier,
            onTextChanged: ctrl.setSessionSupplierText,
          ),
          if (infoChips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: infoChips,
            ),
          ],
          if (ctrl.suppliers.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              AddStockStrings.noSupplierSaved,
              style: AddStockStyles.caption,
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SilverItemsEntryCard extends StatelessWidget {
  final SilverStockController ctrl;

  const _SilverItemsEntryCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(ctrl.selectedMetal);

    return Container(
      decoration: BoxDecoration(
        color: AddStockColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AddStockColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AddStockColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: ui.accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ui.accent.withOpacity(0.22)),
                  ),
                  child: Icon(
                    Icons.table_rows_rounded,
                    size: 18,
                    color: ui.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INVOICE ITEMS',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AddStockColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Add silver articles row by row with pricing, HUID and rack details.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          height: 1.45,
                          color: AddStockColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AddStockColors.inputBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AddStockColors.cardBorder),
                  ),
                  child: Text(
                    'ROWS : ${ctrl.rows.length}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: ui.accent,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AddStockColors.cardBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              children: [
                ...ctrl.rows.asMap().entries.map(
                      (entry) => AddStockItemRowCard(
                        index: entry.key + 1,
                        row: entry.value,
                        ctrl: ctrl,
                      ),
                    ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: ctrl.addRow,
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      color: ui.accent,
                    ),
                    label: Text(
                      'ADD NEW ITEM',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: ui.accent,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ui.accent.withOpacity(0.45)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

class _SilverSummaryPanel extends StatelessWidget {
  final SilverStockController ctrl;
  final Future<void> Function() onSave;
  final VoidCallback onResetBatch;

  const _SilverSummaryPanel({
    required this.ctrl,
    required this.onSave,
    required this.onResetBatch,
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
                        'Silver batch totals and save controls',
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
            child: Column(
              children: [
                _summaryRow('Gross Value', _money(ctrl.totalEstimatedCost),
                    valueBold: true),
                const SizedBox(height: 10),
                _summaryRow(
                    'Estimated Sale', _money(ctrl.totalEstimatedSelling)),
                const SizedBox(height: 10),
                _summaryRow('Taxable Amount', _money(ctrl.totalTaxableAmount)),
                const SizedBox(height: 10),
                _summaryRow('Entered Rows',
                    '${ctrl.enteredRowCount} row${ctrl.enteredRowCount == 1 ? '' : 's'}'),
              ],
            ),
          ),
          if (ctrl.gstEnabled) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AddStockColors.success.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AddStockColors.success.withOpacity(0.20),
                ),
              ),
              child: Column(
                children: [
                  _summaryRow(
                      'GST Rate', '${ctrl.gstRate.toStringAsFixed(1)}%'),
                  const SizedBox(height: 8),
                  _summaryRow('CGST', _money(ctrl.cgstAmount),
                      labelColor: AddStockColors.success,
                      valueColor: AddStockColors.success),
                  const SizedBox(height: 4),
                  _summaryRow('SGST', _money(ctrl.sgstAmount),
                      labelColor: AddStockColors.success,
                      valueColor: AddStockColors.success),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AddStockColors.inputBgLocked,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AddStockColors.cardBorder),
                ),
                alignment: Alignment.center,
                child: Text(
                  'NORMAL BATCH  •  NO GST APPLIED',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                    color: AddStockColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        ? 'Ready to save • ${ctrl.enteredRowCount} entered row${ctrl.enteredRowCount == 1 ? '' : 's'}'
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: ctrl.prevStep,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: accent.withOpacity(0.35)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          AddStockStrings.btnBackPurity,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onResetBatch,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AddStockColors.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          AddStockStrings.btnResetBatch,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: AddStockColors.textBody,
                          ),
                        ),
                      ),
                    ),
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
                            Icons.inventory_2_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                    label: Text(
                      ctrl.isSaving
                          ? AddStockStrings.btnSaving
                          : 'SAVE SILVER BATCH',
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
          ),
          if (ctrl.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
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
            ),
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
