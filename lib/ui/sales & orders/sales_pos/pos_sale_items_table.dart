// ==========================================
// FILE: pos_sale_items_table.dart
// TYPE: Invoice Items Container (UPGRADED)
// AUTHOR: Senior System Architect
// DESCRIPTION: Zero-Lag Cart Table connected to Master Theme.
//              ✅ Strictly mapped Colors, Icons, and TextStyles.
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../logic/sales & orders/sales pos/pos_billing_controller.dart';
import '../../../models/sales & orders/sales_pos_enums/sales_pos_enums.dart';
import 'pos_sale_item_row.dart';

class PosSaleItemsTable extends StatelessWidget {
  final PosBillingController ctrl;

  const PosSaleItemsTable({
    super.key,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f2): () =>
            ctrl.addNewSaleItem(),
        const SingleActivator(LogicalKeyboardKey.delete): () =>
            ctrl.removeActiveItem(),
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: ctrl,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                color: SalesPosColors.itemsTableBg,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: SalesPosColors.shadowLight,
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildColumnRow(),
                  ctrl.saleItems.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: ctrl.saleItems.length,
                          itemBuilder: (_, i) => PosSaleItemRow(
                            // ✅ FIX: ObjectKey prevents state mix-up when rows deleted
                            key: ObjectKey(ctrl.saleItems[i]),
                            index: i,
                            item: ctrl.saleItems[i],
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

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: SalesPosColors.brandGold.withOpacity(0.06),
        border: const Border(
            bottom: BorderSide(color: SalesPosColors.bodyBorder, width: 1.5)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SalesPosColors.brandGold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: SalesPosColors.brandGold.withOpacity(0.40)),
              ),
              child: const Center(
                child: Icon(SalesPosIcons.invoiceItemsHeader,
                    color: SalesPosColors.brandGold, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "INVOICE ITEMS",
                  style: SalesPosStyles.highVisHeader,
                ),
                const SizedBox(height: 4),
                Text(
                  "Scan barcode or press F2 to add product",
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
                border:
                    Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: SalesPosColors.brandGold,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(
                    "CART : ${ctrl.saleItems.length}",
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: SalesPosColors.bodyTextMain),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnRow() {
    final isWholesale = ctrl.billingMode == BillingMode.wholesale;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: SalesPosColors.bodyBg,
        border: Border(
            bottom: BorderSide(color: SalesPosColors.bodyBorder, width: 1.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _h("S.NO", flex: 1, center: true),
          const SizedBox(width: 6),
          _h("METAL", flex: 3),
          const SizedBox(width: 6),
          _h("ITEM DESCRIPTION", flex: 4),
          const SizedBox(width: 6),
          _h("PCS", flex: 1, center: true),
          const SizedBox(width: 6),
          if (!isWholesale) ...[
            _h("HUID", flex: 2),
            const SizedBox(width: 6),
            _h("PURITY", flex: 2, center: true),
            const SizedBox(width: 6),
          ],
          _h("GR. WT", flex: 2),
          const SizedBox(width: 6),
          _h("LESS", flex: 2),
          const SizedBox(width: 6),
          _h("NET WT", flex: 2, center: true),
          const SizedBox(width: 6),
          if (isWholesale) ...[
            _h("TUNCH", flex: 2, center: true),
            const SizedBox(width: 6),
            _h("FINE WT", flex: 2, center: true),
            const SizedBox(width: 6),
            _h("LABOUR CHARGE", flex: 3),
            const SizedBox(width: 6),
            _h("MAKING AMT", flex: 3, right: true),
            const SizedBox(width: 6),
          ] else ...[
            _h("RATE", flex: 3),
            const SizedBox(width: 6),
            _h("MAKING", flex: 3),
            const SizedBox(width: 6),
            _h("TOTAL", flex: 3, right: true),
            const SizedBox(width: 6),
          ],
          _h("ACT", flex: 1, center: true),
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
          style: SalesPosStyles.tableColumnHeader,
        ),
      );

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
                color: SalesPosColors.bodyBg,
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: SalesPosColors.bodyBorder, width: 2.0),
              ),
              child: const Icon(SalesPosIcons.barcodeScanner,
                  color: SalesPosColors.brandGold, size: 36),
            ),
            const SizedBox(height: 18),
            const Text(
              "CART IS EMPTY",
              style: TextStyle(
                  color: SalesPosColors.bodyTextMain,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5),
            ),
            const SizedBox(height: 6),
            Text(
              "Start typing description or scan a barcode",
              style: SalesPosStyles.subTitleMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    double gWt = 0, sWt = 0, pWt = 0, dWt = 0;
    double gVal = 0, sVal = 0, pVal = 0, dVal = 0;

    bool isWholesale = ctrl.billingMode == BillingMode.wholesale;

    for (var item in ctrl.saleItems) {
      double weight = isWholesale ? item.fineWt : item.netWt;
      double val = isWholesale ? item.wholesaleLabourAmt : item.totalValue;

      if (item.metal == MetalType.gold) {
        gWt += weight;
        gVal += val;
      } else if (item.metal == MetalType.silver) {
        sWt += weight;
        sVal += val;
      } else if (item.metal == MetalType.platinum) {
        pWt += weight;
        pVal += val;
      } else if (item.metal == MetalType.diamond) {
        dWt += weight;
        dVal += val;
      }
    }

    String wtLabel = isWholesale ? "Fine:" : "Net:";

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
          // ADD BUTTON
          InkWell(
            onTap: ctrl.addNewSaleItem,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: SalesPosColors.success.withOpacity(0.08),
                border: Border.all(
                    color: SalesPosColors.success.withOpacity(0.35),
                    width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(SalesPosIcons.addItemToCart,
                      color: SalesPosColors.success, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "ADD NEW ITEM",
                    style: TextStyle(
                        color: SalesPosColors.success,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SalesPosColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "[F2]",
                      style: TextStyle(
                          color: SalesPosColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // METALS SUMMARY
          if (ctrl.saleItems.isNotEmpty)
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 10,
                children: [
                  if (gVal > 0 || gWt > 0)
                    _buildMetalTotalBox(
                        "GOLD", gWt, gVal, SalesPosColors.brandGold,
                        isGrams: true, wtLabel: wtLabel),
                  if (sVal > 0 || sWt > 0)
                    _buildMetalTotalBox(
                        "SILVER", sWt, sVal, SalesPosColors.brandSilver,
                        isGrams: true, wtLabel: wtLabel),
                  if (pVal > 0 || pWt > 0)
                    _buildMetalTotalBox(
                        "PLATINUM", pWt, pVal, SalesPosColors.brandPlatinum,
                        isGrams: true, wtLabel: wtLabel),
                  if (dVal > 0 || dWt > 0)
                    _buildMetalTotalBox(
                        "DIAMOND", dWt, dVal, SalesPosColors.brandDiamond,
                        isGrams: false, wtLabel: wtLabel),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetalTotalBox(
      String metalName, double wt, double totalVal, Color color,
      {required bool isGrams, required String wtLabel}) {
    String unit = isGrams ? "g" : "ct";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text("$metalName TOTAL",
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  color: color,
                  letterSpacing: 1.0)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("$wtLabel ${wt.toStringAsFixed(3)} $unit",
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: color.withOpacity(0.8))),
              const SizedBox(width: 10),
              Text("₹ ${totalVal.toStringAsFixed(2)}",
                  style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 14, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}
