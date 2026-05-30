// ==========================================
// FILE: pos_old_gold_table.dart
// TYPE: Smart Exchange/Scrap Container (UPGRADED)
// AUTHOR: Senior System Architect
// DESCRIPTION: Zero-Lag Old Gold Table connected to Master Theme.
//               Hardcoded colors, icons, and typography removed.
// ==========================================

import 'package:flutter/material.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../models/sales & orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../logic/sales & orders/sales pos/pos_billing_controller.dart';
import 'pos_old_gold_row.dart';

class PosOldGoldTable extends StatelessWidget {
  final PosBillingController ctrl;

  const PosOldGoldTable({
    super.key,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: ctrl,
        builder: (context, _) {
          final isWholesale = ctrl.billingMode == BillingMode.wholesale;

          return Container(
            decoration: BoxDecoration(
              color: SalesPosColors.oldGoldTableBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: SalesPosColors.shadowLight,
                    blurRadius: 10,
                    offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isWholesale),
                _buildColumnRow(isWholesale),
                ctrl.oldGoldItems.isEmpty
                    ? _buildEmptyState(isWholesale)
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ctrl.oldGoldItems.length,
                        itemBuilder: (context, index) {
                          return PosOldGoldRow(
                            index: index,
                            item: ctrl.oldGoldItems[index],
                            ctrl: ctrl,
                          );
                        },
                      ),
                _buildBottomSummary(isWholesale),
              ],
            ),
          );
        });
  }

  Widget _buildHeader(bool isWholesale) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: SalesPosColors.danger.withValues(alpha: 0.04),
        border: const Border(
            bottom: BorderSide(color: SalesPosColors.bodyBorder, width: 1.5)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SalesPosColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: SalesPosColors.danger.withValues(alpha: 0.40)),
            ),
            child: const Icon(SalesPosIcons.oldGoldHeader,
                color: SalesPosColors.danger, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isWholesale
                    ? "METAL INWARD (KACHHI / JAMA)"
                    : "EXCHANGE & SCRAP METAL",
                style: SalesPosStyles.highVisHeader
                    .copyWith(color: SalesPosColors.danger, height: 1),
              ),
              const SizedBox(height: 4),
              Text(
                isWholesale
                    ? "Record raw metal receipts for fine weight calculation"
                    : "Record old customer items for deduction",
                style: SalesPosStyles.subTitleMuted,
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: SalesPosColors.bodyBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(SalesPosIcons.itemsCountBag,
                    color: SalesPosColors.danger, size: 18),
                const SizedBox(width: 8),
                Text(
                  "ITEMS : ${ctrl.oldGoldItems.length}",
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: SalesPosColors.danger,
                      letterSpacing: 0.5),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildColumnRow(bool isWholesale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: SalesPosColors.bodyBg,
        border: Border(
            bottom: BorderSide(color: SalesPosColors.bodyBorder, width: 1.5)),
      ),
      child: Row(
        children: [
          _h("S.NO", flex: 1, center: true),
          const SizedBox(width: 6),
          _h("METAL", flex: 3),
          const SizedBox(width: 6),
          if (!isWholesale) ...[
            _h("ITEM DESCRIPTION", flex: 4),
            const SizedBox(width: 6),
          ],
          _h("GROSS", flex: isWholesale ? 4 : 2),
          const SizedBox(width: 6),
          _h("LESS", flex: isWholesale ? 4 : 2),
          const SizedBox(width: 6),
          _h("NET WT", flex: isWholesale ? 4 : 2),
          const SizedBox(width: 6),
          _h(isWholesale ? "TUNCH" : "PURITY", flex: isWholesale ? 4 : 2),
          const SizedBox(width: 6),
          _h("FINE WT", flex: isWholesale ? 4 : 2),
          const SizedBox(width: 6),
          if (!isWholesale) ...[
            _h("RATE", flex: 3),
            const SizedBox(width: 6),
            _h("VALUE", flex: 3, right: true),
            const SizedBox(width: 6),
          ],
          _h("ACT", flex: 1, center: true),
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
          style: SalesPosStyles.tableColumnHeader,
        ));
  }

  Widget _buildEmptyState(bool isWholesale) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: SalesPosColors.bodyBg,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: SalesPosColors.bodyBorder, width: 2.0),
              ),
              child: const Icon(SalesPosIcons.emptyStateSync,
                  color: SalesPosColors.danger, size: 32),
            ),
            const SizedBox(height: 18),
            Text(isWholesale ? "NO METAL INWARDS" : "NO EXCHANGE ITEMS",
                style: const TextStyle(
                    color: SalesPosColors.bodyTextMain,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Text(
                isWholesale
                    ? "Click below to receive Kachhi/Jama"
                    : "Click below to record customer scrap",
                style: SalesPosStyles.subTitleMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSummary(bool isWholesale) {
    double gFine = 0, sFine = 0, pFine = 0, dFine = 0;
    double gVal = 0, sVal = 0, pVal = 0, dVal = 0;

    for (var item in ctrl.oldGoldItems) {
      if (item.metal == MetalType.gold) {
        gFine += item.fineWt;
        gVal += item.totalValue;
      } else if (item.metal == MetalType.silver) {
        sFine += item.fineWt;
        sVal += item.totalValue;
      } else if (item.metal == MetalType.platinum) {
        pFine += item.fineWt;
        pVal += item.totalValue;
      } else if (item.metal == MetalType.diamond) {
        dFine += item.fineWt;
        dVal += item.totalValue;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: SalesPosColors.bodyPanelBg,
        border: Border(
            top: BorderSide(color: SalesPosColors.bodyBorder, width: 1.5)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: ctrl.addOldGoldItem,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  color: SalesPosColors.danger.withValues(alpha: 0.08),
                  border: Border.all(
                      color: SalesPosColors.danger.withValues(alpha: 0.35),
                      width: 1.5),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(SalesPosIcons.addOldGold,
                      color: SalesPosColors.danger, size: 20),
                  const SizedBox(width: 8),
                  Text(
                      isWholesale
                          ? "RECORD METAL INWARD"
                          : "RECORD EXCHANGE ITEM",
                      style: const TextStyle(
                          color: SalesPosColors.danger,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8)),
                ],
              ),
            ),
          ),
          if (ctrl.oldGoldItems.isNotEmpty)
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 10,
                children: [
                  if (gFine > 0)
                    _buildMetalTotalBox(
                        "GOLD", gFine, gVal, SalesPosColors.brandGold,
                        isGrams: true, isWholesale: isWholesale),
                  if (sFine > 0)
                    _buildMetalTotalBox(
                        "SILVER", sFine, sVal, SalesPosColors.brandSilver,
                        isGrams: true, isWholesale: isWholesale),
                  if (pFine > 0)
                    _buildMetalTotalBox(
                        "PLATINUM", pFine, pVal, SalesPosColors.brandPlatinum,
                        isGrams: true, isWholesale: isWholesale),
                  if (dFine > 0)
                    _buildMetalTotalBox(
                        "DIAMOND", dFine, dVal, SalesPosColors.brandDiamond,
                        isGrams: false, isWholesale: isWholesale),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetalTotalBox(
      String metalName, double fineWt, double totalVal, Color color,
      {required bool isGrams, required bool isWholesale}) {
    String unit = isGrams ? "g" : "ct";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(isWholesale ? "$metalName INWARD" : "$metalName TOTAL",
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: color,
                  letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Fine: ${fineWt.toStringAsFixed(3)} $unit",
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: color.withValues(alpha: 0.9))),
              if (!isWholesale) ...[
                const SizedBox(width: 12),
                Text("Rs ${totalVal.toStringAsFixed(2)}",
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: color)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
