import 'package:flutter/material.dart';

import '../../../features/sales_pos/domain/services/pos_payment_labels.dart';
import '../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import 'payment_summary/pos_payment_summary_cards.dart';

class PosPaymentSettlementSection extends StatelessWidget {
  const PosPaymentSettlementSection({
    super.key,
    required this.ctrl,
    required this.header,
    required this.onPickPromiseDate,
  });

  final PosBillingController ctrl;
  final Widget header;
  final VoidCallback onPickPromiseDate;

  @override
  Widget build(BuildContext context) {
    final isEmptyCart = ctrl.saleItems.isEmpty && ctrl.tradeInItems.isEmpty;
    final hasIncompleteDraft =
        !isEmptyCart && ctrl.validateInvoiceReadiness() != null;
    final isReturn = ctrl.balanceDue < -0.005;
    final returnMethod = ctrl.changeReturnMethod;
    final isDue = ctrl.balanceDue > 0.005;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          _buildPaymentInput(
              "Cash Received", ctrl.cashCtrl, SalesPosIcons.cashFilled),
          const SizedBox(height: 12),
          _buildPaymentInput(
              PosPaymentLabels.upi, ctrl.upiCtrl, SalesPosIcons.bankUpi),
          const SizedBox(height: 12),
          _buildPaymentInput("Card Payment", ctrl.cardCtrl, SalesPosIcons.card),
          const SizedBox(height: 12),
          _buildPaymentInput(
              "Customer Advance", ctrl.advCtrl, SalesPosIcons.advancePayment),
          if (!isEmptyCart) ...[
            const SizedBox(height: 18),
            if (ctrl.shouldShowMetalPaymentAllocation) ...[
              PosMetalPaymentAllocationCard(
                allocations: ctrl.metalPaymentAllocations,
                settleFirstMetals: ctrl.settleFirstMetals,
                onToggle: ctrl.toggleSettleFirstMetal,
                metalDiscounts: ctrl.metalDiscounts,
                onDiscountChanged: ctrl.setMetalDiscount,
                billId: ctrl.editingBillId,
                manualMode: ctrl.isManualMetalSettlement,
                onManualModeChanged: ctrl.setManualMetalSettlement,
                manualPaidByMetal: ctrl.manualPaidByMetal,
                onManualPaidChanged: ctrl.setManualMetalPaid,
                allocationError: ctrl.metalSettlementError,
              ),
              const SizedBox(height: 12),
            ],
            PosPaymentBreakdownCard(
              amountPayable: ctrl.finalPayableAmount,
              amountReceived: ctrl.totalPaid,
              balanceDue: ctrl.balanceDue,
              hasIncompleteDraft: hasIncompleteDraft,
            ),
            const SizedBox(height: 12),
            PosPaymentStatusCard(
              isEmptyCart: isEmptyCart,
              hasIncompleteDraft: hasIncompleteDraft,
              balanceDue: ctrl.balanceDue,
              returnMethod: returnMethod,
            ),
          ],
          if (!isEmptyCart) ...[
            if (isReturn && returnMethod == null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: ctrl.canReturnChangeWith(
                        RefundMethod.cash,
                      )
                          ? () => ctrl.setChangeReturnMethod(
                                RefundMethod.cash,
                              )
                          : null,
                      icon: const Icon(SalesPosIcons.cashFilled,
                          size: 18, color: Colors.white),
                      label: const Text("RETURN CASH",
                          style: TextStyle(
                              fontSize: SalesPosStyles.fontLabel,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SalesPosColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: ctrl.canReturnChangeWith(
                        RefundMethod.upi,
                      )
                          ? () => ctrl.setChangeReturnMethod(
                                RefundMethod.upi,
                              )
                          : null,
                      icon: const Icon(SalesPosIcons.bankUpi,
                          size: 18, color: Colors.white),
                      label: const Text("RETURN UPI",
                          style: TextStyle(
                              fontSize: SalesPosStyles.fontLabel,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SalesPosColors.upiButtonBg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: ctrl.canReturnChangeWith(
                    RefundMethod.refundPayable,
                  )
                      ? () => ctrl.setChangeReturnMethod(
                            RefundMethod.refundPayable,
                          )
                      : null,
                  icon: const Icon(SalesPosIcons.advancePayment,
                      size: 18, color: Colors.white),
                  label: const Text("MARK REFUND PAYABLE",
                      style: TextStyle(
                          fontSize: SalesPosStyles.fontLabel,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SalesPosColors.brandGold,
                    disabledBackgroundColor:
                        SalesPosColors.bodyTextMuted.withValues(alpha: 0.20),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              if (ctrl.selectedCustomer == null) ...[
                const SizedBox(height: 8),
                Text(
                  "Select a customer to record a refund payable.",
                  style: TextStyle(
                    color: SalesPosColors.bodyTextMuted.withValues(alpha: 0.85),
                    fontSize: SalesPosStyles.fontCaption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ],
          if (isDue && !isEmptyCart) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => onPickPromiseDate(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: SalesPosColors.bodyBg,
                  border: Border.all(
                      color: SalesPosColors.danger.withValues(alpha: 0.50),
                      width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(SalesPosIcons.promiseDate,
                          color: SalesPosColors.danger, size: 18),
                      const SizedBox(width: 10),
                      Text("Promise Date",
                          style: TextStyle(
                              fontSize: SalesPosStyles.fontLabel,
                              fontWeight: FontWeight.w900,
                              color: SalesPosColors.danger
                                  .withValues(alpha: 0.95))),
                    ]),
                    ctrl.promiseDate != null
                        ? Text(
                            "${ctrl.promiseDate!.day.toString().padLeft(2, '0')}/${ctrl.promiseDate!.month.toString().padLeft(2, '0')}/${ctrl.promiseDate!.year}",
                            style: const TextStyle(
                                color: SalesPosColors.danger,
                                fontWeight: FontWeight.w900,
                                fontSize: SalesPosStyles.fontBody))
                        : const Text("Select Date",
                            style: TextStyle(
                                color: SalesPosColors.danger,
                                fontWeight: FontWeight.w900,
                                fontSize: SalesPosStyles.fontCaption)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentInput(
      String label, TextEditingController tCtrl, IconData icon) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Icon(icon, color: SalesPosColors.bodyTextMain, size: 18),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      fontSize: SalesPosStyles.fontLabel,
                      fontWeight: FontWeight.w900,
                      color: SalesPosColors.bodyTextMain)),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: tCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: SalesPosColors.bodyTextMain,
                  fontSize: SalesPosStyles.fontInput,
                  fontWeight: FontWeight.w900),
              decoration: InputDecoration(
                hintText: "0.00",
                hintStyle: const TextStyle(
                    color: SalesPosColors.bodyTextMuted,
                    fontSize: SalesPosStyles.fontBody),
                filled: true,
                fillColor: SalesPosColors.bodyBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: SalesPosColors.bodyBorder, width: 1.5),
                    borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: SalesPosColors.brandGold, width: 2.0),
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
