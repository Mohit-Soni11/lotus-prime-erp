// =============================================================================
// FILE        : purchase_right_panel.dart
// MODULE      : Purchase Entry
// LAYER       : UI
// DESCRIPTION : Right billing panel for Purchase Entry.
//               Shows purchase summary + payment disbursement to seller.
//               "We are paying the seller" — balance logic reversed from Sales.
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';
import '../../../logic/purchase/purchase_entry_controller.dart';
import '../../../models/purchase/purchase_enums/purchase_enums.dart';

class PurchaseRightPanel extends StatefulWidget {
  final PurchaseEntryController ctrl;

  const PurchaseRightPanel({super.key, required this.ctrl});

  @override
  State<PurchaseRightPanel> createState() => _PurchaseRightPanelState();
}

class _PurchaseRightPanelState extends State<PurchaseRightPanel> {
  bool _gstExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: PurchaseEntryColors.bodyPanel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: PurchaseEntryColors.bodyBorder,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: PurchaseEntryColors.shadowLight,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
              BoxShadow(
                color: PurchaseEntryColors.shadowDark,
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildSummaryBoard(),
                        _panelDivider(),
                        _buildPaymentHub(),
                      ],
                    ),
                  ),
                ),
                _panelDivider(),
                _buildActionButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _panelDivider() => Container(
        height: 2.0,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            PurchaseEntryColors.purchaseAccent.withOpacity(0.05),
            PurchaseEntryColors.bodyBorder,
            PurchaseEntryColors.purchaseAccent.withOpacity(0.05),
          ]),
        ),
      );

  // ── Summary Board ───────────────────────────────────────────────────────────
  Widget _buildSummaryBoard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHead(
            icon: PurchaseEntryIcons.invoiceOutline,
            title: PurchaseEntryStrings.purchaseSummary,
            subtitle: 'Kharidi gayi cheez ka breakdown',
          ),

          // Metal rows
          if (widget.ctrl.totalGoldValue > 0)
            _subtleRow(
              'Gold (${widget.ctrl.totalGoldFine.toStringAsFixed(3)} g)',
              widget.ctrl.totalGoldValue,
              color: PurchaseEntryColors.metalGold,
            ),
          if (widget.ctrl.totalSilverValue > 0)
            _subtleRow(
              'Silver (${widget.ctrl.totalSilverFine.toStringAsFixed(3)} g)',
              widget.ctrl.totalSilverValue,
              color: PurchaseEntryColors.metalSilver,
            ),
          if (widget.ctrl.totalPlatinumValue > 0)
            _subtleRow(
              'Platinum (${widget.ctrl.totalPlatinumFine.toStringAsFixed(3)} g)',
              widget.ctrl.totalPlatinumValue,
              color: PurchaseEntryColors.metalPlatinum,
            ),
          if (widget.ctrl.totalDiamondValue > 0)
            _subtleRow(
              'Diamond (${widget.ctrl.totalDiamondFine.toStringAsFixed(3)} ct)',
              widget.ctrl.totalDiamondValue,
              color: PurchaseEntryColors.metalDiamond,
            ),

          const SizedBox(height: 12),

          // Gross total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: PurchaseEntryColors.bodyBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: PurchaseEntryColors.bodyBorder,
                width: 1.5,
              ),
            ),
            child:
                _pillarRow('Gross Purchase', widget.ctrl.grossPurchaseAmount),
          ),

          const SizedBox(height: 12),

          // Discount row
          _discountRow(),

          const SizedBox(height: 8),
          _pillarRow(
            widget.ctrl.taxType == PurchaseTaxType.gst
                ? 'Taxable Value'
                : 'Net Purchase',
            widget.ctrl.taxableAmount,
            isMid: true,
          ),
          const SizedBox(height: 10),

          // GST
          if (widget.ctrl.taxType == PurchaseTaxType.gst)
            _buildGstSection()
          else
            _buildNoGstBadge(),
        ],
      ),
    );
  }

  Widget _buildGstSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _gstExpanded = !_gstExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total GST (3% on Purchase)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: PurchaseEntryColors.textMain,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '₹ ${widget.ctrl.totalGst.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: PurchaseEntryColors.textMain,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _gstExpanded
                          ? PurchaseEntryIcons.arrowUp
                          : PurchaseEntryIcons.arrowDown,
                      color: PurchaseEntryColors.textMain,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_gstExpanded)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PurchaseEntryColors.purchaseAccent.withOpacity(0.05),
                border: Border.all(
                  color: PurchaseEntryColors.purchaseAccent.withOpacity(0.25),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _subtleRow('CGST (1.5%)', widget.ctrl.cgst),
                  _subtleRow('SGST (1.5%)', widget.ctrl.sgst),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoGstBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.bodyBg,
        border: Border.all(
          color: PurchaseEntryColors.bodyBorder,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'NORMAL PURCHASE  ·  NO GST APPLIED',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: PurchaseEntryColors.textMain,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  // ── Payment Hub ─────────────────────────────────────────────────────────────
  Widget _buildPaymentHub() {
    final isEmpty = widget.ctrl.grandTotal == 0.0;
    final isDue = widget.ctrl.balanceDue > 0.005;
    final isOverpaid = widget.ctrl.balanceDue < -0.005;
    final isSettled = !isDue && !isOverpaid && !isEmpty;

    final balColor = isSettled || isOverpaid
        ? PurchaseEntryColors.success
        : PurchaseEntryColors.purchaseAccent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHead(
            icon: PurchaseEntryIcons.cashPay,
            title: PurchaseEntryStrings.paymentDisburse,
            subtitle: 'Seller ko diye gaye payments',
          ),
          _paymentInput(
              'Cash Paid', widget.ctrl.cashCtrl, PurchaseEntryIcons.cashPay),
          const SizedBox(height: 12),
          _paymentInput(
              'UPI / Bank', widget.ctrl.upiCtrl, PurchaseEntryIcons.upiPay),
          const SizedBox(height: 12),
          _paymentInput('Card / Cheque', widget.ctrl.cardCtrl,
              PurchaseEntryIcons.cardPay),
          const SizedBox(height: 18),
          if (isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: PurchaseEntryColors.bodyBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: PurchaseEntryColors.bodyBorder,
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Text(
                  'NO ITEMS ADDED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: PurchaseEntryColors.textMain,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            )
          else
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: balColor.withOpacity(0.10),
                border: Border.all(
                  color: balColor.withOpacity(0.60),
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOverpaid
                            ? 'OVERPAID (WAPAS LO)'
                            : isSettled
                                ? 'PAYMENT COMPLETE'
                                : 'BAAKI DENA HAI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: balColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹ ${widget.ctrl.balanceDue.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: balColor,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isSettled || isOverpaid
                        ? PurchaseEntryIcons.settledVerified
                        : PurchaseEntryIcons.dueWarning,
                    color: balColor,
                    size: 32,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Action Buttons ──────────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    final isCredit = widget.ctrl.grandTotal < 0;
    final boxColor = PurchaseEntryColors.purchaseAccent;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          // Grand total box
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: boxColor.withOpacity(0.10),
              border: Border.all(
                color: boxColor.withOpacity(0.50),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCredit ? 'CREDIT NOTE' : 'TOTAL PAYABLE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: PurchaseEntryColors.textMain,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${isCredit ? '- ' : ''}₹ ${widget.ctrl.grandTotal.abs().toStringAsFixed(2)}',
                      style: PurchaseEntryStyles.grandTotalText,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Save + Print buttons
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Purchase voucher printing will be added in the next update.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(PurchaseEntryIcons.printVoucher, size: 18),
                    label: const Text(
                      'PRINT',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PurchaseEntryColors.purchaseAccent,
                      side: BorderSide(
                        color: PurchaseEntryColors.purchaseAccent
                            .withOpacity(0.80),
                        width: 2.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (widget.ctrl.items.isEmpty) return;
                      final saved = await widget.ctrl.savePurchase();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            saved
                                ? 'Purchase saved successfully.'
                                : 'Unable to save the purchase. Check the item data and try again.',
                          ),
                          backgroundColor: saved
                              ? PurchaseEntryColors.success
                              : PurchaseEntryColors.danger,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(
                      PurchaseEntryIcons.saveVoucher,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      PurchaseEntryStrings.saveBtn,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PurchaseEntryColors.success,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _sectionHead({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: PurchaseEntryColors.purchaseAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: PurchaseEntryColors.purchaseAccent.withOpacity(0.35),
                width: 1.5,
              ),
            ),
            child:
                Icon(icon, color: PurchaseEntryColors.purchaseAccent, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  letterSpacing: 1.2,
                  color: PurchaseEntryColors.textMain,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: PurchaseEntryStyles.subTitleMuted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subtleRow(String label, double amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: PurchaseEntryColors.textMain,
            ),
          ),
          Text(
            '₹ ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color ?? PurchaseEntryColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillarRow(String label, double amount, {bool isMid = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMid ? 14 : 15,
            fontWeight: FontWeight.w900,
            color: PurchaseEntryColors.textMain,
          ),
        ),
        Text(
          '₹ ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isMid ? 16 : 17,
            fontWeight: FontWeight.w900,
            color: PurchaseEntryColors.textMain,
          ),
        ),
      ],
    );
  }

  Widget _discountRow() {
    final discAmt = widget.ctrl.discountAmount;
    final isPercent =
        widget.ctrl.discountType == PurchaseDiscountType.percentage;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'Discount / Deduction',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: PurchaseEntryColors.textMain,
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => widget.ctrl.toggleDiscountType(isPercent
                    ? PurchaseDiscountType.flatAmount
                    : PurchaseDiscountType.percentage),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: PurchaseEntryColors.bodyBg,
                    border: Border.all(
                      color: PurchaseEntryColors.bodyBorder,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.ctrl.discountType.symbol,
                        style: const TextStyle(
                          color: PurchaseEntryColors.purchaseAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        PurchaseEntryIcons.arrowDown,
                        color: PurchaseEntryColors.textMain,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (discAmt > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    '- ₹ ${discAmt.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: PurchaseEntryColors.danger,
                    ),
                  ),
                ),
              SizedBox(
                width: 85,
                height: 34,
                child: TextField(
                  controller: widget.ctrl.discountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: PurchaseEntryColors.danger,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: PurchaseEntryColors.textMuted),
                    filled: true,
                    fillColor: PurchaseEntryColors.bodyBg,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: PurchaseEntryColors.bodyBorder,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: PurchaseEntryColors.danger,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
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

  Widget _paymentInput(
    String label,
    TextEditingController tCtrl,
    IconData icon,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Icon(icon, color: PurchaseEntryColors.textMain, size: 18),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: PurchaseEntryColors.textMain,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: tCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: PurchaseEntryColors.textMain,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(
                  color: PurchaseEntryColors.textMuted,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: PurchaseEntryColors.bodyBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: PurchaseEntryColors.bodyBorder,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: PurchaseEntryColors.purchaseAccent,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
