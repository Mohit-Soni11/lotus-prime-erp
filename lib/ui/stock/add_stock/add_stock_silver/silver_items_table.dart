// =============================================================================
// FILE        : silver_items_table.dart
// MODULE      : Stock & Inventory — Silver
// LAYER       : UI / Table
// DESCRIPTION : Fast-Entry Table for Silver Stock intake.
//               ✅ Same UX pattern as GoldEntryTable — inline editing, no card-flip.
//               ✅ F2 → Add new row.  Delete key → Remove active row.
//               ✅ Horizontal scroll when viewport < tableWidth.
//               ✅ Empty state with silver illustration.
//               ✅ Bottom bar: ADD NEW ITEM [F2] + live batch totals.
//               ✅ Header + column labels with silver accent branding.
//               ✅ ListenableBuilder on ctrl — only table re-renders on change.
//
// COLUMNS:
//   S.NO | SUB CAT | ITEM NAME | HUID | GROSS | LESS | NET WT |
//   RATE/g | MAKING TYPE | MAKING | QTY | STONE VAL | ROW TOTAL | ACT
//
// HOW TO USE:
//   SilverItemsTable(ctrl: ctrl)
//   (Drop inside a scrollable parent — table renders as fixed height.)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/logic/stock/add_stock_controller.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_colors.dart';
import 'silver_item_row.dart';

class SilverItemsTable extends StatelessWidget {
  final SilverStockController ctrl;

  const SilverItemsTable({super.key, required this.ctrl});

  // Total fixed width for all columns + gaps
  // 62+160+200+110+88+88+88+110+148+100+72+110+140+96 = 1572  +  13×8 = 1676
  static const double _tableWidth = 1676;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final needsScroll = constraints.maxWidth < _tableWidth;

            return CallbackShortcuts(
              bindings: {
                // F2 → add new row and focus item name
                const SingleActivator(LogicalKeyboardKey.f2): () =>
                    ctrl.addRow(requestFocus: true),
                // Delete → remove the currently active row
                const SingleActivator(LogicalKeyboardKey.delete): () =>
                    ctrl.removeActiveRow(),
              },
              child: Focus(
                autofocus: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: AddStockColors.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AddStockColors.cardBorder,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AddStockColors.shadowLight,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Table header ──────────────────────────
                      _buildHeader(needsScroll),

                      // ── Column labels + rows ──────────────────
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: needsScroll
                            ? const BouncingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: _tableWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildColumnHeaders(),

                              // Empty state
                              ctrl.rows.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: ctrl.rows.length,
                                      itemBuilder: (context, index) =>
                                          SilverItemRow(
                                        // ObjectKey prevents state mix-up on row delete
                                        key: ObjectKey(ctrl.rows[index]),
                                        index: index,
                                        row: ctrl.rows[index],
                                        ctrl: ctrl,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),

                      // ── Bottom bar ────────────────────────────
                      _buildBottomBar(context),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TABLE HEADER
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader(bool needsScroll) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: SilverStockColors.brandSilver.withOpacity(0.04),
        border: const Border(
          bottom: BorderSide(color: AddStockColors.cardBorder, width: 1.5),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SilverStockColors.brandSilver.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: SilverStockColors.brandSilver.withOpacity(0.40),
              ),
            ),
            child: Icon(
              Icons.table_rows_rounded,
              color: SilverStockColors.brandSilver,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FAST SILVER ENTRY TABLE',
                  style: AddStockStyles.pageTitle.copyWith(
                    fontSize: 18,
                    color: SilverStockColors.brandSilver,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Press F2 or click ADD NEW ITEM to add a row. Press Enter in the last field to jump to the next row.',
                  style: AddStockStyles.caption.copyWith(fontSize: 12),
                ),
                if (needsScroll) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Scroll horizontally to see all silver-entry columns.',
                    style: AddStockStyles.caption.copyWith(
                      color: SilverStockColors.brandSilver,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Row count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AddStockColors.bodyBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AddStockColors.cardBorder, width: 1.5),
            ),
            child: Text(
              'ROWS : ${ctrl.enteredRowCount > 0 ? ctrl.enteredRowCount : ctrl.rows.length}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: SilverStockColors.brandSilver,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COLUMN HEADERS
  // ─────────────────────────────────────────────────────────────

  Widget _buildColumnHeaders() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AddStockColors.bodyBg,
        border: Border(
          bottom: BorderSide(color: AddStockColors.cardBorder, width: 1.5),
        ),
      ),
      child: const Row(
        children: [
          _SilverHeaderCell('S.NO', width: 62, center: true),
          SizedBox(width: 8),
          _SilverHeaderCell('SUB CATEGORY', width: 160),
          SizedBox(width: 8),
          _SilverHeaderCell('ITEM NAME', width: 200),
          SizedBox(width: 8),
          _SilverHeaderCell('HUID', width: 110),
          SizedBox(width: 8),
          _SilverHeaderCell('GROSS', width: 88, right: true),
          SizedBox(width: 8),
          _SilverHeaderCell('LESS', width: 88, right: true),
          SizedBox(width: 8),
          _SilverHeaderCell('NET WT', width: 88, right: true),
          SizedBox(width: 8),
          _SilverHeaderCell('RATE / g', width: 110, right: true),
          SizedBox(width: 8),
          _SilverHeaderCell('MAKING TYPE', width: 148),
          SizedBox(width: 8),
          _SilverHeaderCell('MAKING', width: 100, right: true),
          SizedBox(width: 8),
          _SilverHeaderCell('QTY', width: 72, center: true),
          SizedBox(width: 8),
          _SilverHeaderCell('STONE VAL', width: 110, right: true),
          SizedBox(width: 8),
          _SilverHeaderCell('ROW TOTAL', width: 140, right: true),
          SizedBox(width: 8),
          _SilverHeaderCell('ACT', width: 96, center: true),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AddStockColors.bodyBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AddStockColors.cardBorder,
                  width: 2.0,
                ),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: SilverStockColors.brandSilver,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'NO SILVER ITEMS YET',
              style: GoogleFonts.manrope(
                color: AddStockColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Click ADD NEW ITEM or press F2 to begin entry',
              style: AddStockStyles.caption.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BOTTOM BAR
  // ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: AddStockColors.bodyBg,
        border: Border(
          top: BorderSide(color: AddStockColors.cardBorder, width: 1.5),
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ADD NEW ITEM button — same style as POS & Gold
          InkWell(
            onTap: () => ctrl.addRow(requestFocus: true),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AddStockColors.success.withOpacity(0.08),
                border: Border.all(
                  color: AddStockColors.success.withOpacity(0.35),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AddStockColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ADD NEW ITEM',
                    style: TextStyle(
                      color: AddStockColors.success,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // F2 badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AddStockColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '[F2]',
                      style: TextStyle(
                        color: AddStockColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Live batch summary chips — visible only when rows are entered
          if (ctrl.enteredRowCount > 0)
            Row(
              children: [
                _summaryChip(
                  'Net Weight',
                  '${_wt(ctrl.totalNetWeight)} g',
                  SilverStockColors.brandSilver,
                ),
                const SizedBox(width: 10),
                _summaryChip(
                  'Taxable Amt',
                  _money(ctrl.totalTaxableAmount),
                  AddStockColors.accentPricing,
                ),
                const SizedBox(width: 10),
                _summaryChip(
                  'Batch Total',
                  _money(ctrl.totalBatchAmount),
                  AddStockColors.success,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        border: Border.all(color: color.withOpacity(0.28), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 10,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COLUMN HEADER CELL
// ─────────────────────────────────────────────────────────────────────────────

class _SilverHeaderCell extends StatelessWidget {
  final String title;
  final double width;
  final bool right;
  final bool center;

  const _SilverHeaderCell(
    this.title, {
    required this.width,
    this.right = false,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        textAlign: center
            ? TextAlign.center
            : (right ? TextAlign.right : TextAlign.left),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AddStockColors.textMuted,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

double _wt(double v) => double.parse(v.toStringAsFixed(3));

String _money(double amount) => NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs ',
      decimalDigits: 2,
    ).format(amount);
