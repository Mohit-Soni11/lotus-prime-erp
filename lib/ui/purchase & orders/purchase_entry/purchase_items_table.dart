// =============================================================================
// FILE        : purchase_items_table.dart
// MODULE      : Purchase Entry
// LAYER       : UI
// DESCRIPTION : Purchase items table container with header, rows, summary.
//               Based on POS Old Gold Table design pattern.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';
import '../../../logic/purchase/purchase_entry_controller.dart';
import '../../../models/purchase/purchase_enums/purchase_enums.dart';
import 'purchase_item_row.dart';

class PurchaseItemsTable extends StatelessWidget {
  final PurchaseEntryController ctrl;

  const PurchaseItemsTable({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color:  PurchaseEntryColors.bodyPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: PurchaseEntryColors.bodyBorder,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color:      PurchaseEntryColors.shadowLight,
                blurRadius: 10,
                offset:     Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildColumnHeaders(),
              ctrl.items.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ctrl.items.length,
                      itemBuilder: (context, index) => PurchaseItemRow(
                        index: index,
                        item:  ctrl.items[index],
                        ctrl:  ctrl,
                      ),
                    ),
              _buildBottomSummary(),
            ],
          ),
        );
      },
    );
  }

  // ── Table Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.purchaseAccent.withOpacity(0.04),
        border: const Border(
          bottom: BorderSide(color: PurchaseEntryColors.bodyBorder, width: 1.5),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: PurchaseEntryColors.purchaseAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: PurchaseEntryColors.purchaseAccent.withOpacity(0.40),
              ),
            ),
            child: const Icon(
              PurchaseEntryIcons.purchaseHeader,
              color: PurchaseEntryColors.purchaseAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ctrl.purchaseSource == PurchaseSource.fromCustomer
                    ? 'PURCHASED ITEMS (FROM CUSTOMER)'
                    : 'PURCHASED ITEMS (FROM SUPPLIER)',
                style: PurchaseEntryStyles.highVisHeader.copyWith(
                  color: PurchaseEntryColors.purchaseAccent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ctrl.purchaseSource == PurchaseSource.fromCustomer
                    ? 'Customer ka sona/zewar jo hum khared rahe hain'
                    : 'Supplier se aane wala maal',
                style: PurchaseEntryStyles.subTitleMuted,
              ),
            ],
          ),
          const Spacer(),

          // Item count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color:  PurchaseEntryColors.bodyBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: PurchaseEntryColors.bodyBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  PurchaseEntryIcons.purchaseHeader,
                  color: PurchaseEntryColors.purchaseAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'ITEMS : ${ctrl.items.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: PurchaseEntryColors.purchaseAccent,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Column Headers ──────────────────────────────────────────────────────────
  Widget _buildColumnHeaders() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: PurchaseEntryColors.bodyBg,
        border: Border(
          bottom: BorderSide(color: PurchaseEntryColors.bodyBorder, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          _h('S.NO',  flex: 1, center: true), const SizedBox(width: 6),
          _h('METAL', flex: 3),               const SizedBox(width: 6),
          _h('ITEM DESCRIPTION', flex: 4),   const SizedBox(width: 6),
          _h('GROSS', flex: 2),               const SizedBox(width: 6),
          _h('LESS',  flex: 2),               const SizedBox(width: 6),
          _h('NET WT', flex: 2),              const SizedBox(width: 6),
          _h('PURITY', flex: 2),              const SizedBox(width: 6),
          _h('FINE WT', flex: 2),             const SizedBox(width: 6),
          _h('RATE',   flex: 3),              const SizedBox(width: 6),
          _h('VALUE',  flex: 3, right: true), const SizedBox(width: 6),
          _h('ACT',    flex: 1, center: true),
        ],
      ),
    );
  }

  Widget _h(String t,
      {required int flex, bool right = false, bool center = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        t,
        textAlign: right
            ? TextAlign.right
            : (center ? TextAlign.center : TextAlign.left),
        style: PurchaseEntryStyles.tableColumnHeader,
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color:  PurchaseEntryColors.bodyBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: PurchaseEntryColors.bodyBorder,
                  width: 2.0,
                ),
              ),
              child: const Icon(
                PurchaseEntryIcons.purchaseHeader,
                color: PurchaseEntryColors.purchaseAccent,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              PurchaseEntryStrings.noItems,
              style: TextStyle(
                color: PurchaseEntryColors.textMain,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              PurchaseEntryStrings.noItemsSub,
              style: TextStyle(
                color: PurchaseEntryColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Summary ──────────────────────────────────────────────────────────
  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: PurchaseEntryColors.bodyPanel,
        border: Border(
          top: BorderSide(color: PurchaseEntryColors.bodyBorder, width: 1.5),
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add item button
          InkWell(
            onTap: ctrl.addItem,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:  PurchaseEntryColors.purchaseAccent.withOpacity(0.08),
                border: Border.all(
                  color: PurchaseEntryColors.purchaseAccent.withOpacity(0.35),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    PurchaseEntryIcons.addItem,
                    color: PurchaseEntryColors.purchaseAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    PurchaseEntryStrings.addItemBtn,
                    style: TextStyle(
                      color:      PurchaseEntryColors.purchaseAccent,
                      fontSize:   14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Metal totals
          if (ctrl.items.isNotEmpty)
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 10,
                children: [
                  if (ctrl.totalGoldValue > 0)
                    _metalBox('GOLD', ctrl.totalGoldFine,
                        ctrl.totalGoldValue, PurchaseEntryColors.metalGold),
                  if (ctrl.totalSilverValue > 0)
                    _metalBox('SILVER', ctrl.totalSilverFine,
                        ctrl.totalSilverValue, PurchaseEntryColors.metalSilver),
                  if (ctrl.totalPlatinumValue > 0)
                    _metalBox('PLATINUM', ctrl.totalPlatinumFine,
                        ctrl.totalPlatinumValue, PurchaseEntryColors.metalPlatinum),
                  if (ctrl.totalDiamondValue > 0)
                    _metalBox('DIAMOND', ctrl.totalDiamondFine,
                        ctrl.totalDiamondValue, PurchaseEntryColors.metalDiamond,
                        isGrams: false),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _metalBox(
    String name,
    double fine,
    double value,
    Color color, {
    bool isGrams = true,
  }) {
    final unit = isGrams ? 'g' : 'ct';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:  color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$name PURCHASE',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fine: ${fine.toStringAsFixed(3)} $unit',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: color.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '₹ ${value.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
