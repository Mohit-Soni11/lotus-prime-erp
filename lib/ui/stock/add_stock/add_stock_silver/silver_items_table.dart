// ==========================================
// FILE: silver_items_table.dart
// TYPE: Invoice Items Container (SILVER — POS-STYLE)
// DESCRIPTION: Zero-Lag Silver Cart Table — exact same design as PosSaleItemsTable.
//              ✅ Silver-branded Colors, Icons, and TextStyles.
//              ✅ F2 → Add new row.  Delete key → Remove active row.
//              ✅ Header + Column labels + Empty State + Bottom Bar.
//              ✅ ListenableBuilder on ctrl — only table re-renders on change.
//
// COLUMNS:
//   S.NO | ITEM NAME | HUID | GROSS | LESS | NET WT | RATE | MAKING | TOTAL | ACT
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_colors.dart';
import 'silver_item_row.dart';

class SilverItemsTable extends StatelessWidget {
  final SilverStockController ctrl;

  const SilverItemsTable({
    super.key,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f2): () =>
            ctrl.addRow(requestFocus: true),
        const SingleActivator(LogicalKeyboardKey.delete): () =>
            ctrl.removeActiveRow(),
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: ctrl,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                color: SilverStockColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: SilverStockColors.cardBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: SilverStockColors.shadowLight,
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildColumnRow(),
                  ctrl.rows.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: ctrl.rows.length,
                          itemBuilder: (_, i) => SilverItemRow(
                            key: ObjectKey(ctrl.rows[i]),
                            index: i,
                            row: ctrl.rows[i],
                            ctrl: ctrl,
                          ),
                        ),
                  _buildBottomBar(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TABLE HEADER — exact same layout as PosSaleItemsTable
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: SilverStockColors.brandSilver.withOpacity(0.06),
        border: const Border(
            bottom:
                BorderSide(color: SilverStockColors.cardBorder, width: 1.5)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Silver icon badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SilverStockColors.brandSilver.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: SilverStockColors.brandSilver.withOpacity(0.40)),
              ),
              child: Center(
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: SilverStockColors.brandSilver,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Title + subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'INVOICE ITEMS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: SilverStockColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Press F2 to add item or click ADD NEW ITEM below',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: SilverStockColors.textMuted,
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Row count badge — same as POS CART badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: SilverStockColors.bodyBg,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: SilverStockColors.cardBorder, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: SilverStockColors.brandSilver,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(
                    'ITEMS : ${ctrl.rows.length}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: SilverStockColors.textDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COLUMN HEADER ROW — exact same _h() helper as POS
  // ─────────────────────────────────────────────────────────────

  Widget _buildColumnRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: SilverStockColors.bodyBg,
        border: Border(
            bottom:
                BorderSide(color: SilverStockColors.cardBorder, width: 1.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _h('S.NO', flex: 1, center: true),
          const SizedBox(width: 6),
          _h('ITEM NAME', flex: 4),
          const SizedBox(width: 6),
          _h('HUID', flex: 2),
          const SizedBox(width: 6),
          _h('GR. WT', flex: 2),
          const SizedBox(width: 6),
          _h('LESS', flex: 2),
          const SizedBox(width: 6),
          _h('NET WT', flex: 2, center: true),
          const SizedBox(width: 6),
          _h('RATE / g', flex: 3),
          const SizedBox(width: 6),
          _h('MAKING', flex: 3),
          const SizedBox(width: 6),
          _h('TOTAL', flex: 3, right: true),
          const SizedBox(width: 6),
          _h('ACT', flex: 1, center: true),
        ],
      ),
    );
  }

  // Same _h() helper as PosSaleItemsTable — Expanded flex col header
  Widget _h(String t,
          {required int flex, bool right = false, bool center = false}) =>
      Expanded(
        flex: flex,
        child: Text(
          t,
          textAlign: right
              ? TextAlign.right
              : (center ? TextAlign.center : TextAlign.left),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: SilverStockColors.textMuted,
            letterSpacing: 0.7,
          ),
        ),
      );

  // ─────────────────────────────────────────────────────────────
  // EMPTY STATE — exact same pattern as POS
  // ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: SilverStockColors.bodyBg,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: SilverStockColors.cardBorder, width: 2.0),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: SilverStockColors.brandSilver,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'NO SILVER ITEMS YET',
              style: TextStyle(
                  color: SilverStockColors.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5),
            ),
            const SizedBox(height: 6),
            Text(
              'Press F2 or click ADD NEW ITEM to begin entry',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SilverStockColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BOTTOM BAR — exact same layout as POS bottom bar
  // ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    // Live totals
    double totalNetWt = 0;
    double totalAmount = 0;

    for (final row in ctrl.rows) {
      totalNetWt += row.netWeight;
      totalAmount += ctrl.rowTotalAmount(row);
    }

    final hasItems = ctrl.rows.isNotEmpty && totalNetWt > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: SilverStockColors.bodyBg,
        border: Border(
            top: BorderSide(color: SilverStockColors.cardBorder, width: 1.5)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ADD NEW ITEM — same button as POS
          InkWell(
            onTap: () => ctrl.addRow(requestFocus: true),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: SilverStockColors.success.withOpacity(0.08),
                border: Border.all(
                    color: SilverStockColors.success.withOpacity(0.35),
                    width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: SilverStockColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ADD NEW ITEM',
                    style: TextStyle(
                        color: SilverStockColors.success,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8),
                  ),
                  const SizedBox(width: 14),
                  // F2 badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SilverStockColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '[F2]',
                      style: TextStyle(
                          color: SilverStockColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Live Silver Summary Chips — same as POS metal total boxes
          if (hasItems)
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 10,
                children: [
                  _buildSilverTotalBox(
                    'NET WT',
                    '${totalNetWt.toStringAsFixed(3)} g',
                    SilverStockColors.brandSilver,
                  ),
                  _buildSilverTotalBox(
                    'BATCH TOTAL',
                    '₹ ${totalAmount.toStringAsFixed(2)}',
                    SilverStockColors.success,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Same pattern as _buildMetalTotalBox in POS — silver branded
  Widget _buildSilverTotalBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  color: color,
                  letterSpacing: 1.0)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 14, color: color)),
        ],
      ),
    );
  }
}
