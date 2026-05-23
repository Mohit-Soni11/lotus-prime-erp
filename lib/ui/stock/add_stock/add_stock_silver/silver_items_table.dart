import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_colors.dart';

import 'silver_item_row.dart';

class SilverItemsTable extends StatelessWidget {
  static const double _minTableWidth = 1880;

  final SilverStockController ctrl;

  const SilverItemsTable({super.key, required this.ctrl});

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

            return LayoutBuilder(
              builder: (context, constraints) {
                final needsHorizontalScroll =
                    constraints.maxWidth < _minTableWidth;
                final tableWidth = constraints.maxWidth > _minTableWidth
                    ? constraints.maxWidth
                    : _minTableWidth;

                return Container(
                  decoration: BoxDecoration(
                    color: SilverStockColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: SilverStockColors.cardBorder,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: SilverStockColors.shadowLight,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(rows.length, needsHorizontalScroll),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: needsHorizontalScroll
                            ? const BouncingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          width: tableWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (rows.isNotEmpty) _buildColumnRow(),
                              rows.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: rows.length,
                                      itemBuilder: (_, i) => SilverItemRow(
                                        key: ObjectKey(rows[i]),
                                        index: i,
                                        model: rows[i],
                                        ctrl: ctrl,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                      _buildBottomBar(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int count, bool needsHorizontalScroll) {
    return Container(
      decoration: BoxDecoration(
        color: SilverStockColors.brandSilver.withValues(alpha: 0.06),
        border: const Border(
          bottom: BorderSide(color: SilverStockColors.cardBorder, width: 1.5),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SilverStockColors.brandSilver.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: SilverStockColors.brandSilver.withValues(alpha: 0.40),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.receipt_long_rounded,
                color: SilverStockColors.brandSilver,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
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
                needsHorizontalScroll
                    ? 'Scroll to review every column. Each row can capture a full silver lot with PCS and transparent purity.'
                    : 'Enter total pieces and combined lot weight. Total purity = base purity + wastage.',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SilverStockColors.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: SilverStockColors.bodyBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: SilverStockColors.cardBorder,
                width: 1.5,
              ),
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

  Widget _buildColumnRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: SilverStockColors.bodyBg,
        border: Border(
          bottom: BorderSide(color: SilverStockColors.cardBorder, width: 1.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _h('NO.', flex: 1, center: true),
          const SizedBox(width: 6),
          _h('ITEM TYPE', flex: 3),
          const SizedBox(width: 6),
          _h('ITEM NAME', flex: 4),
          const SizedBox(width: 6),
          _h('PCS', flex: 2, center: true),
          const SizedBox(width: 6),
          _h('HUID', flex: 2),
          const SizedBox(width: 6),
          _h('GROSS', flex: 2),
          const SizedBox(width: 6),
          _h('LESS/PC', flex: 2),
          const SizedBox(width: 6),
          _h('LESS TOTAL', flex: 2, center: true),
          const SizedBox(width: 6),
          _h('NET', flex: 2, center: true),
          const SizedBox(width: 6),
          _h('PURITY', flex: 2, center: true),
          const SizedBox(width: 6),
          _h('WASTAGE', flex: 2, center: true),
          const SizedBox(width: 6),
          _h('TOTAL PURITY', flex: 2, center: true),
          const SizedBox(width: 6),
          _h('FINE', flex: 2, center: true),
          const SizedBox(width: 6),
          _h('MAKING', flex: 3),
          const SizedBox(width: 6),
          _h('AMOUNT', flex: 3, right: true),
          const SizedBox(width: 6),
          _h('ACT', flex: 1, center: true),
        ],
      ),
    );
  }

  Widget _h(
    String text, {
    required int flex,
    bool right = false,
    bool center = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
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
  }

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
                border: Border.all(
                  color: SilverStockColors.cardBorder,
                  width: 2.0,
                ),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: SilverStockColors.brandSilver,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
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
            const Text(
              'Press F2 or click ADD NEW ITEM to begin silver stock entry',
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: SilverStockColors.bodyBg,
        border: Border(
          top: BorderSide(color: SilverStockColors.cardBorder, width: 1.5),
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackFooter = constraints.maxWidth < 980;

          if (stackFooter) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildActionButtons(),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _buildFooterStats()),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildActionButtons(),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildFooterStats(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _buildAddItemButton(),
        _buildRoundOffButton(),
      ],
    );
  }

  Widget _buildAddItemButton() {
    return InkWell(
      onTap: () => ctrl.addRow(requestFocus: true),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: SilverStockColors.success.withValues(alpha: 0.08),
          border: Border.all(
            color: SilverStockColors.success.withValues(alpha: 0.35),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
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
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: SilverStockColors.success.withValues(alpha: 0.15),
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
    );
  }

  Widget _buildRoundOffButton() {
    final enabled = ctrl.canRoundOffInvoiceFine;
    final color =
        enabled ? SilverStockColors.accentPricing : SilverStockColors.textMuted;

    return Tooltip(
      message: 'Round invoice fine only',
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: enabled ? ctrl.roundOffInvoiceFine : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: enabled ? 0.08 : 0.04),
            border: Border.all(
              color: color.withValues(alpha: enabled ? 0.35 : 0.18),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.exposure_plus_1_rounded, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                'ROUND INVOICE FINE',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFooterStats() {
    return [
      _buildTotalBox(
        'ROWS',
        '${ctrl.enteredRowCount}',
        SilverStockColors.textDark,
      ),
      const SizedBox(width: 12),
      _buildTotalBox(
        'PCS',
        '${ctrl.totalQuantity}',
        SilverStockColors.accentPricing,
      ),
      const SizedBox(width: 12),
      _buildTotalBox(
        'NET WT',
        '${ctrl.totalNetWeight.toStringAsFixed(3)} g',
        SilverStockColors.brandSilver,
      ),
      const SizedBox(width: 12),
      _buildTotalBox(
        'FINE WT',
        '${ctrl.totalFineWeight.toStringAsFixed(3)} g',
        SilverStockColors.accentPricing,
      ),
      const SizedBox(width: 12),
      _buildTotalBox(
        'BATCH TOTAL',
        'Rs ${ctrl.totalEstimatedCost.toStringAsFixed(2)}',
        SilverStockColors.success,
      ),
    ];
  }

  Widget _buildTotalBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 1.5),
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
