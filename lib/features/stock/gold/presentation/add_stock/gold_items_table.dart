import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_gold/gold_stock_colors.dart';

import 'gold_item_row.dart';

class GoldItemsTable extends StatefulWidget {
  static const double _minTableWidth = 1760;

  final GoldStockController ctrl;

  const GoldItemsTable({super.key, required this.ctrl});

  @override
  State<GoldItemsTable> createState() => _GoldItemsTableState();
}

class _GoldItemsTableState extends State<GoldItemsTable> {
  final ScrollController _horizontalCtrl = ScrollController();

  GoldStockController get ctrl => widget.ctrl;

  @override
  void dispose() {
    _horizontalCtrl.dispose();
    super.dispose();
  }

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
            final rows = ctrl.goldRows;

            return LayoutBuilder(
              builder: (context, constraints) {
                final needsHorizontalScroll =
                    constraints.maxWidth < GoldItemsTable._minTableWidth;
                final tableWidth =
                    constraints.maxWidth > GoldItemsTable._minTableWidth
                        ? constraints.maxWidth
                        : GoldItemsTable._minTableWidth;

                return Container(
                  decoration: BoxDecoration(
                    color: GoldStockColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: GoldStockColors.cardBorder,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: GoldStockColors.shadowLight,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(rows.length, needsHorizontalScroll),
                      ClipRRect(
                        child: Scrollbar(
                          controller: _horizontalCtrl,
                          thumbVisibility: needsHorizontalScroll,
                          trackVisibility: needsHorizontalScroll,
                          notificationPredicate: (notification) =>
                              notification.metrics.axis == Axis.horizontal,
                          child: SingleChildScrollView(
                            controller: _horizontalCtrl,
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
                                          itemBuilder: (_, i) => GoldItemRow(
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
      decoration: const BoxDecoration(
        color: GoldStockColors.cardBg,
        border: Border(
          bottom: BorderSide(color: GoldStockColors.cardBorder, width: 1.5),
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: GoldStockColors.brandGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: GoldStockColors.brandGold.withValues(alpha: 0.40),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.receipt_long_rounded,
                color: GoldStockColors.brandGold,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '3. Item Entry',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: GoldStockColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  needsHorizontalScroll
                      ? 'Scroll horizontally to review serial, HUID, weight, purity, making and amount.'
                      : 'Enter each stock item with serial number, HUID, weight, purity, making and valuation.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: GoldStockColors.textBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: GoldStockColors.bodyBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: GoldStockColors.cardBorder,
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
                    color: GoldStockColors.brandGold,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ITEMS : $count',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: GoldStockColors.textDark,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFCF5),
        border: Border(
          bottom: BorderSide(color: GoldStockColors.cardBorder, width: 1.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _h('SERIAL NO.', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('ITEM TYPE', flex: 3),
          const SizedBox(width: 4),
          _h('SEGMENT', flex: 3),
          const SizedBox(width: 4),
          _h('ITEM NAME', flex: 4),
          const SizedBox(width: 4),
          _h('PCS', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('HUID / SERIAL NO.', flex: 4),
          const SizedBox(width: 4),
          _h('GROSS WT (g)', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('LESS WT (g)', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('NET WT (g)', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('PURITY (%)', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('WASTAGE (%)', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('TOTAL PURITY (%)', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('ACTUAL FINE (g)', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('VALUATION FINE (g)', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('MAKING', flex: 3, center: true),
          const SizedBox(width: 4),
          _h('AMOUNT (Rs)', flex: 3, right: true),
          const SizedBox(width: 4),
          _h('ACTION', flex: 1, center: true),
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
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: GoldStockColors.textDark,
          letterSpacing: 0.35,
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
                color: GoldStockColors.bodyBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: GoldStockColors.cardBorder,
                  width: 2.0,
                ),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: GoldStockColors.brandGold,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Gold Items Yet',
              style: GoogleFonts.inter(
                color: GoldStockColors.textDark,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Press F2 or click Add New Item to begin gold stock entry.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: GoldStockColors.textBody,
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
        color: GoldStockColors.cardBg,
        border: Border(
          top: BorderSide(color: GoldStockColors.cardBorder, width: 1.5),
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
      ],
    );
  }

  Widget _buildAddItemButton() {
    return InkWell(
      onTap: () => ctrl.addRow(requestFocus: true),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: GoldStockColors.success.withValues(alpha: 0.08),
          border: Border.all(
            color: GoldStockColors.success.withValues(alpha: 0.35),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              color: GoldStockColors.success,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Add New Item',
              style: GoogleFonts.inter(
                color: GoldStockColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: GoldStockColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '[F2]',
                style: GoogleFonts.inter(
                  color: GoldStockColors.success,
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

  List<Widget> _buildFooterStats() {
    return [
      _buildTotalBox(
        'TOTAL ROWS',
        ctrl.enteredRowCount.toString(),
        GoldStockColors.textDark,
      ),
      const SizedBox(width: 12),
      _buildTotalBox(
        'ACTUAL FINE',
        '${ctrl.totalActualFineWeight.toStringAsFixed(3)} g',
        GoldStockColors.success,
      ),
      const SizedBox(width: 12),
      _buildTotalBox(
        'VALUATION FINE',
        '${ctrl.totalValuationFineWeight.toStringAsFixed(3)} g',
        GoldStockColors.brandGold,
      ),
      const SizedBox(width: 12),
      _buildTotalBox(
        'MAKING',
        'Rs ${ctrl.totalMakingAmount.toStringAsFixed(2)}',
        GoldStockColors.textDark,
      ),
      const SizedBox(width: 12),
      _buildTotalBox(
        'TOTAL AMOUNT',
        'Rs ${ctrl.totalEstimatedCost.toStringAsFixed(2)}',
        GoldStockColors.success,
      ),
    ];
  }

  Widget _buildTotalBox(String label, String value, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 128, maxWidth: 178),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
