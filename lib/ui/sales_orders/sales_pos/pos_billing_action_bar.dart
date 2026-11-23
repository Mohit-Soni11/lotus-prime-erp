import 'package:flutter/material.dart';

import '../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import 'payment_summary/pos_payment_summary_cards.dart';
import 'pos_hold_list_dialog.dart';

class PosBillingActionBar extends StatelessWidget {
  const PosBillingActionBar({
    super.key,
    required this.ctrl,
    required this.isOpeningInvoicePreview,
    required this.onGenerateInvoicePressed,
    required this.onParkBillPressed,
  });

  final PosBillingController ctrl;
  final bool isOpeningInvoicePreview;
  final VoidCallback onGenerateInvoicePressed;
  final VoidCallback onParkBillPressed;

  @override
  Widget build(BuildContext context) => _buildActionButtons(context);
  Widget _buildActionButtons(BuildContext context) {
    final payableAmount = ctrl.finalPayableAmount;
    final hasItems = ctrl.saleItems.isNotEmpty || ctrl.tradeInItems.isNotEmpty;
    final validationMessage = hasItems ? ctrl.validateInvoiceReadiness() : null;
    final actionNeedsReview = validationMessage != null;
    final actionLabel = isOpeningInvoicePreview
        ? 'OPENING INVOICE...'
        : !hasItems
            ? 'ADD ITEMS FIRST'
            : ctrl.isEditingExistingBill
                ? 'UPDATE INVOICE'
                : actionNeedsReview
                    ? 'REVIEW INVOICE'
                    : 'GENERATE INVOICE';
    final actionColor = !hasItems
        ? SalesPosColors.bodyTextMuted
        : actionNeedsReview
            ? SalesPosColors.warning
            : SalesPosColors.success;
    final actionIcon = !hasItems
        ? SalesPosIcons.addItemToCart
        : actionNeedsReview
            ? SalesPosIcons.dueWarning
            : SalesPosIcons.printReceipt;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          PosAmountPayableCard(amount: payableAmount),

          // --- SMART PARKED BILLS BADGE (Visible only if bills are on hold) ---
          if (ctrl.heldBills.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => PosHoldListDialog(ctrl: ctrl),
                    );
                  },
                  icon: const Icon(SalesPosIcons.holdFilled,
                      size: 16, color: SalesPosColors.warning),
                  label: Text("VIEW PARKED BILLS (${ctrl.heldBills.length})",
                      style: const TextStyle(
                          color: SalesPosColors.warning,
                          fontWeight: FontWeight.w900,
                          fontSize: SalesPosStyles.fontCaption,
                          letterSpacing: 0)),
                  style: TextButton.styleFrom(
                    backgroundColor:
                        SalesPosColors.warning.withValues(alpha: 0.1),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),

          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildParkBillAction(),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    //  Generate invoice action
                    onPressed: isOpeningInvoicePreview
                        ? null
                        : onGenerateInvoicePressed,

                    icon: Icon(actionIcon, color: Colors.white, size: 20),
                    label: Text(
                      actionLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: SalesPosStyles.fontBody,
                          letterSpacing: 0),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParkBillAction() {
    final canPark = ctrl.canHoldCurrentBill;
    final hasItems = ctrl.saleItems.isNotEmpty || ctrl.tradeInItems.isNotEmpty;
    final isFinalized = ctrl.isCurrentSaleCommitted;
    final subtitle = canPark
        ? 'Save draft'
        : isFinalized
            ? 'Finalized'
            : hasItems
                ? 'Not available'
                : 'Add items';
    final accent =
        canPark ? SalesPosColors.warning : SalesPosColors.bodyTextMuted;

    return SizedBox(
      height: 54,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canPark ? onParkBillPressed : null,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: canPark
                  ? SalesPosColors.warning.withValues(alpha: 0.10)
                  : SalesPosColors.bodyBg.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: canPark
                    ? SalesPosColors.warning.withValues(alpha: 0.82)
                    : SalesPosColors.bodyBorder,
                width: canPark ? 1.8 : 1.4,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: canPark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent.withValues(alpha: 0.22)),
                  ),
                  child: Icon(
                    SalesPosIcons.holdFilled,
                    size: 17,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Park Bill',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: canPark
                              ? SalesPosColors.warning
                              : SalesPosColors.bodyTextMain
                                  .withValues(alpha: 0.60),
                          fontSize: SalesPosStyles.fontCaption,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              accent.withValues(alpha: canPark ? 0.88 : 0.70),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
