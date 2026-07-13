import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/features/stock/shared/application/add_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/features/stock/shared/presentation/add_stock/stock_metal_ui.dart';
import 'add_stock_item_row_card.dart';
import 'add_stock_supplier_autocomplete.dart';

class AddStockItemsStep extends StatelessWidget {
  final AddStockController ctrl;
  final Future<void> Function() onSave;
  final VoidCallback onResetBatch;

  const AddStockItemsStep({
    super.key,
    required this.ctrl,
    required this.onSave,
    required this.onResetBatch,
  });

  @override
  Widget build(BuildContext context) {
    final ui = stockMetalUiFor(ctrl.selectedMetal);

    return Column(
      children: [
        _buildOverview(ui),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
            children: [
              ...ctrl.rows.asMap().entries.map(
                    (entry) => AddStockItemRowCard(
                      index: entry.key + 1,
                      row: entry.value,
                      ctrl: ctrl,
                    ),
                  ),
              OutlinedButton.icon(
                onPressed: ctrl.addRow,
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AddStockColors.brandGold,
                ),
                label: Text(
                  AddStockStrings.btnAddRow,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AddStockColors.brandGold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AddStockColors.brandGold),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildSaveBar(ui),
      ],
    );
  }

  Widget _buildOverview(StockMetalUiData ui) {
    return Container(
      color: AddStockColors.cardBg,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ui.softSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ui.accent.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AddStockStrings.batchOverview,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AddStockColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AddStockStrings.batchInsights,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AddStockColors.textBody,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _statPill(ui.title, ui.accent),
                    _statPill(ctrl.purityDisplay, AddStockColors.accentPricing),
                    _statPill(ctrl.batchCode, AddStockColors.textBody),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _metricCard(
                      AddStockStrings.overviewPieces,
                      '${ctrl.totalQuantity}',
                    ),
                    _metricCard(
                      AddStockStrings.overviewGross,
                      '${ctrl.totalGrossWeight.toStringAsFixed(3)} g',
                    ),
                    _metricCard(
                      AddStockStrings.overviewNet,
                      '${ctrl.totalNetWeight.toStringAsFixed(3)} g',
                    ),
                    _metricCard(
                      AddStockStrings.overviewCost,
                      'Rs ${ctrl.totalEstimatedCost.toStringAsFixed(2)}',
                    ),
                    _metricCard(
                      AddStockStrings.overviewSale,
                      'Rs ${ctrl.totalEstimatedSelling.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AddStockSupplierAutocomplete(
                  label: AddStockStrings.supplierSession,
                  suppliers: ctrl.suppliers,
                  initialName: ctrl.sessionSupplierName,
                  onSelected: ctrl.setSessionSupplier,
                  onTextChanged: ctrl.setSessionSupplierText,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    AddStockStrings.sameForAll,
                    style: AddStockStyles.caption,
                  ),
                  Switch(
                    value: ctrl.sameForAll,
                    onChanged: ctrl.setSameForAll,
                    activeThumbColor: ui.accent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
          if (ctrl.suppliers.isEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AddStockStrings.noSupplierSaved,
                style: AddStockStyles.caption,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveBar(StockMetalUiData ui) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AddStockColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: AddStockColors.shadowMedium,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ctrl.errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AddStockColors.dangerBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AddStockColors.danger.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                ctrl.errorMessage!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AddStockColors.danger,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: ui.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: ui.accent.withValues(alpha: 0.16)),
                  ),
                  child: Text(
                    ctrl.rowsWithErrorsCount == 0
                        ? AddStockStrings.readyToSave
                        : '${ctrl.rowsWithErrorsCount} ${AddStockStrings.rowsNeedAttention}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ui.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: ctrl.prevStep,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ui.accent.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  AddStockStrings.btnBackPurity,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: ui.accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onResetBatch,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AddStockColors.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  AddStockStrings.btnResetBatch,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AddStockColors.textBody,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: ctrl.isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: ui.accent,
                disabledBackgroundColor: AddStockColors.inputBgLocked,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: ctrl.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_alt_rounded, color: Colors.white),
              label: Text(
                ctrl.isSaving
                    ? AddStockStrings.btnSaving
                    : 'Save ${ctrl.rowCount} item${ctrl.rowCount > 1 ? 's' : ''} to stock',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AddStockColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AddStockColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AddStockColors.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }
}
