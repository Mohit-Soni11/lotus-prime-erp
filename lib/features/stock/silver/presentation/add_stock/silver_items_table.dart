import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_colors.dart';

import 'silver_item_row.dart';

class SilverItemsTable extends StatefulWidget {
  static const double _minTableWidth = 1320;

  final SilverStockController ctrl;

  const SilverItemsTable({super.key, required this.ctrl});

  @override
  State<SilverItemsTable> createState() => _SilverItemsTableState();
}

class _SilverItemsTableState extends State<SilverItemsTable> {
  final ScrollController _horizontalCtrl = ScrollController();

  SilverStockController get ctrl => widget.ctrl;

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
            final rows = ctrl.silverRows;

            return LayoutBuilder(
              builder: (context, constraints) {
                final needsHorizontalScroll =
                    constraints.maxWidth < SilverItemsTable._minTableWidth;
                final tableWidth =
                    constraints.maxWidth > SilverItemsTable._minTableWidth
                        ? constraints.maxWidth
                        : SilverItemsTable._minTableWidth;

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
        color: SilverStockColors.cardBg,
        border: Border(
          bottom: BorderSide(color: SilverStockColors.cardBorder, width: 1.5),
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
                    color: SilverStockColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  needsHorizontalScroll
                      ? 'Scroll horizontally to review serial, HUID, weight, purity, making and amount.'
                      : 'Enter each silver stock item with segment, HUID, weight, purity, making and valuation.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: SilverStockColors.textBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: SilverStockColors.cardBorder, width: 1.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _h('SERIAL NO.', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('COMPANY', flex: 4),
          const SizedBox(width: 4),
          _h('ITEM TYPE', flex: 4),
          const SizedBox(width: 4),
          _h('SEGMENT', flex: 3),
          const SizedBox(width: 4),
          _h('ITEM NAME', flex: 5),
          const SizedBox(width: 4),
          _h('QTY / UNIT', flex: 4, center: true),
          const SizedBox(width: 4),
          _h('HUID / SERIAL NO.', flex: 4),
          const SizedBox(width: 4),
          _h('GROSS WT\n(g)', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('LESS WT\n(g)', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('NET WT\n(g)', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('PURITY\n(%)', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('WASTAGE\n(%)', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('TOTAL\nPURITY (%)', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('ACTUAL\nFINE (g)', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('VALUATION\nFINE (g)', flex: 2, center: true),
          const SizedBox(width: 4),
          _h('MAKING', flex: 3, center: true),
          const SizedBox(width: 4),
          _h('AMOUNT (Rs)', flex: 4, right: true),
          const SizedBox(width: 4),
          _h('ACTION', flex: 2, center: true),
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
      child: Align(
        alignment: right
            ? Alignment.centerRight
            : (center ? Alignment.center : Alignment.centerLeft),
        child: Text(
          text,
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.visible,
          textAlign: right
              ? TextAlign.right
              : (center ? TextAlign.center : TextAlign.left),
          style: GoogleFonts.inter(
            fontSize: 12,
            height: 1.08,
            fontWeight: FontWeight.w900,
            color: SilverStockColors.textDark,
            letterSpacing: 0.15,
          ),
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
            Text(
              'No Silver Items Yet',
              style: GoogleFonts.inter(
                color: SilverStockColors.textDark,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Press F2 or click Add New Item to begin silver stock entry.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: SilverStockColors.textBody,
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
        color: SilverStockColors.cardBg,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            Text(
              'Add New Item',
              style: GoogleFonts.inter(
                color: SilverStockColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: SilverStockColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '[F2]',
                style: GoogleFonts.inter(
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
      message: 'Round valuation fine to the nearest gram',
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: enabled ? ctrl.roundOffInvoiceFine : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                'Round Valuation Fine',
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
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
        'TOTAL ROWS',
        ctrl.enteredRowCount.toString(),
        SilverStockColors.textDark,
      ),
      const SizedBox(width: 12),
      _buildTotalBox(
        'TOTAL WEIGHT',
        '${ctrl.totalNetWeight.toStringAsFixed(3)} g',
        SilverStockColors.brandSilver,
      ),
      const SizedBox(width: 12),
      _buildTotalBox(
        'PCS',
        ctrl.totalQuantity.toString(),
        SilverStockColors.accentPricing,
      ),
      const SizedBox(width: 12),
      _buildTotalBox(
        'ACTUAL FINE',
        '${ctrl.totalActualFineWeight.toStringAsFixed(3)} g',
        SilverStockColors.success,
      ),
      const SizedBox(width: 12),
      _buildTotalBox(
        'VALUATION FINE',
        '${ctrl.totalValuationFineWeight.toStringAsFixed(3)} g',
        SilverStockColors.brandSilver,
      ),
      const SizedBox(width: 12),
      _buildTotalBox(
        'MAKING',
        'Rs ${ctrl.totalMakingAmount.toStringAsFixed(2)}',
        SilverStockColors.textDark,
      ),
      const SizedBox(width: 12),
      _buildTotalBox(
        'TOTAL AMOUNT',
        'Rs ${ctrl.totalEstimatedCost.toStringAsFixed(2)}',
        SilverStockColors.success,
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
