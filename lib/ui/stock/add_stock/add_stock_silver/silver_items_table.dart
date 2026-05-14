// =============================================================================
// silver_items_table.dart  —  SILVER INVOICE ITEMS TABLE
// ✅ POS jaisa: starts with EMPTY STATE ("NO SILVER ITEMS YET")
// ✅ F2 / ADD NEW ITEM se pehli row aati hai
// ✅ Sab rows delete hone par empty state wapas aata hai
// ✅ ctrl.silverRows use karta hai (SilverItemModel list)
// ✅ Bottom bar totals sirf tab dikhte hain jab rows hain
// ✅ ITEMS count header me, F2 shortcut, Delete shortcut
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
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
            final rows = ctrl.silverRows;

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
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER ──────────────────────────────────
                  _buildHeader(rows.length),

                  // ── COLUMN LABELS (sirf rows hon tab) ───────
                  if (rows.isNotEmpty) _buildColumnRow(),

                  // ── EMPTY STATE ya ROWS ──────────────────────
                  rows.isEmpty
                      ? _buildEmptyState() // POS jaisa "CART IS EMPTY"
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: rows.length,
                          itemBuilder: (_, i) => SilverItemRow(
                            key: ObjectKey(rows[i]), // stable key like POS
                            index: i,
                            model: rows[i],
                            ctrl: ctrl,
                          ),
                        ),

                  // ── BOTTOM BAR ───────────────────────────────
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
  // HEADER — title + ITEMS count badge
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader(int count) {
    return Container(
      decoration: BoxDecoration(
        color: SilverStockColors.brandSilver.withOpacity(0.06),
        border: const Border(
            bottom:
                BorderSide(color: SilverStockColors.cardBorder, width: 1.5)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon badge
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
              child: Icon(Icons.receipt_long_rounded,
                  color: SilverStockColors.brandSilver, size: 22),
            ),
          ),
          const SizedBox(width: 14),

          // Title + hint
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'INVOICE ITEMS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: SilverStockColors.textDark,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Scan barcode or press F2 to add item',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SilverStockColors.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),

          // ITEMS count badge — POS ka "CART : 0" jaisa
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
                  decoration: const BoxDecoration(
                    color: SilverStockColors.brandSilver,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ITEMS : $count',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: SilverStockColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COLUMN LABELS ROW
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
  // EMPTY STATE — exact same pattern as POS "CART IS EMPTY"
  // ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon box — same size as POS (72x72)
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: SilverStockColors.bodyBg,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: SilverStockColors.cardBorder, width: 2.0),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: SilverStockColors.brandSilver,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),

            // "NO SILVER ITEMS YET" — same style as POS "CART IS EMPTY"
            const Text(
              'NO SILVER ITEMS YET',
              style: TextStyle(
                color: SilverStockColors.textDark,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle — same as POS "Start typing description..."
            const Text(
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
  // BOTTOM BAR — ADD button + live totals (sirf rows hon tab)
  // same layout as POS _buildBottomBar
  // ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final hasItems = ctrl.enteredRowCount > 0;

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── ADD NEW ITEM ─────────────────────────────────────
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
                  Icon(Icons.add_circle_outline_rounded,
                      color: SilverStockColors.success, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'ADD NEW ITEM',
                    style: TextStyle(
                      color: SilverStockColors.success,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
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
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── LIVE TOTALS — sirf jab koi entered row ho ────────
          if (hasItems)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTotalBox(
                  'NET WT',
                  '${ctrl.totalNetWeight.toStringAsFixed(3)} g',
                  SilverStockColors.brandSilver,
                ),
                const SizedBox(width: 12),
                _buildTotalBox(
                  'BATCH TOTAL',
                  '₹ ${ctrl.totalEstimatedCost.toStringAsFixed(2)}',
                  SilverStockColors.success,
                ),
              ],
            ),
        ],
      ),
    );
  }

  // same as POS _buildMetalTotalBox
  Widget _buildTotalBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.30), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 10,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
