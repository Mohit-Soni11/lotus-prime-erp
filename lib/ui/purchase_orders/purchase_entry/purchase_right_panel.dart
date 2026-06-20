import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../logic/purchase/purchase_entry_controller.dart';
import '../../../logic/purchase/purchase_voucher_print_service.dart';
import '../../../models/purchase/purchase_enums/purchase_enums.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';

class PurchaseRightPanel extends StatefulWidget {
  final PurchaseEntryController ctrl;

  const PurchaseRightPanel({super.key, required this.ctrl});

  @override
  State<PurchaseRightPanel> createState() => _PurchaseRightPanelState();
}

class _PurchaseRightPanelState extends State<PurchaseRightPanel> {
  bool _gstExpanded = false;

  String _currency(double amount) => 'Rs. ${amount.toStringAsFixed(2)}';

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
        height: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.05),
              PurchaseEntryColors.bodyBorder,
              PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.05),
            ],
          ),
        ),
      );

  Widget _buildSummaryBoard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHead(
            icon: PurchaseEntryIcons.invoiceOutline,
            title: PurchaseEntryStrings.purchaseSummary,
            subtitle: 'Review valuation, discount, and tax before saving',
          ),
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
          _discountCard(),
          const SizedBox(height: 12),
          _pillarRow(
            widget.ctrl.taxType == PurchaseTaxType.gst
                ? 'Taxable Value'
                : 'Net Purchase',
            widget.ctrl.taxableAmount,
            isMid: true,
          ),
          const SizedBox(height: 10),
          if (widget.ctrl.taxType == PurchaseTaxType.gst)
            _buildGstSection()
          else
            _buildNoGstBadge(),
        ],
      ),
    );
  }

  Widget _discountCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.bodyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: PurchaseEntryColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Discount',
            style: TextStyle(
              color: PurchaseEntryColors.textMain,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _discountToggle(
                  title: 'Flat',
                  active: widget.ctrl.discountType ==
                      PurchaseDiscountType.flatAmount,
                  onTap: () => widget.ctrl
                      .toggleDiscountType(PurchaseDiscountType.flatAmount),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _discountToggle(
                  title: 'Percent',
                  active: widget.ctrl.discountType ==
                      PurchaseDiscountType.percentage,
                  onTap: () => widget.ctrl
                      .toggleDiscountType(PurchaseDiscountType.percentage),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: TextField(
              controller: widget.ctrl.discountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: PurchaseEntryStyles.inputText.copyWith(fontSize: 14),
              decoration: InputDecoration(
                prefixText:
                    widget.ctrl.discountType == PurchaseDiscountType.flatAmount
                        ? 'Rs. '
                        : null,
                suffixText:
                    widget.ctrl.discountType == PurchaseDiscountType.percentage
                        ? '%'
                        : null,
                hintText:
                    widget.ctrl.discountType == PurchaseDiscountType.flatAmount
                        ? 'Enter discount amount'
                        : 'Enter discount percentage',
                hintStyle: PurchaseEntryStyles.subTitleMuted.copyWith(
                  fontSize: 13,
                ),
                filled: true,
                fillColor: PurchaseEntryColors.bodyPanel,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: PurchaseEntryColors.bodyBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: PurchaseEntryColors.bodyBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: PurchaseEntryColors.purchaseAccent,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _subtleRow('Discount Applied', widget.ctrl.discountAmount),
        ],
      ),
    );
  }

  Widget _discountToggle({
    required String title,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.12)
              : PurchaseEntryColors.bodyPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? PurchaseEntryColors.purchaseAccent
                : PurchaseEntryColors.bodyBorder,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active
                ? PurchaseEntryColors.purchaseAccent
                : PurchaseEntryColors.textMain,
            fontWeight: FontWeight.w800,
          ),
        ),
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
                  'GST (3%)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: PurchaseEntryColors.textMain,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _currency(widget.ctrl.totalGst),
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
                color:
                    PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.05),
                border: Border.all(
                  color: PurchaseEntryColors.purchaseAccent
                      .withValues(alpha: 0.25),
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
          'STANDARD PURCHASE - NO GST APPLIED',
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

  Widget _buildPaymentHub() {
    final isEmpty = widget.ctrl.grandTotal == 0.0;
    final isDue = widget.ctrl.balanceDue > 0.005;
    final isOverpaid = widget.ctrl.balanceDue < -0.005;
    final isSettled = !isDue && !isOverpaid && !isEmpty;

    final balanceColor = isSettled || isOverpaid
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
            subtitle: 'Record how the payout is being settled',
          ),
          _paymentInput(
              'Cash Paid', widget.ctrl.cashCtrl, PurchaseEntryIcons.cashPay),
          const SizedBox(height: 12),
          _paymentInput('UPI / Bank Paid', widget.ctrl.upiCtrl,
              PurchaseEntryIcons.upiPay),
          const SizedBox(height: 12),
          _paymentInput(
              'Card Paid', widget.ctrl.cardCtrl, PurchaseEntryIcons.cardPay),
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
                  'NO PURCHASE LINES ADDED',
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
                color: balanceColor.withValues(alpha: 0.10),
                border: Border.all(
                  color: balanceColor.withValues(alpha: 0.60),
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
                            ? 'OVERPAID'
                            : isSettled
                                ? 'PAYMENT COMPLETE'
                                : 'BALANCE TO SETTLE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: balanceColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currency(widget.ctrl.balanceDue.abs()),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: balanceColor,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isSettled || isOverpaid
                        ? PurchaseEntryIcons.settledVerified
                        : PurchaseEntryIcons.dueWarning,
                    color: balanceColor,
                    size: 32,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isCredit = widget.ctrl.grandTotal < 0;
    const totalColor = PurchaseEntryColors.purchaseAccent;
    final canPrint = widget.ctrl.items.any((item) => item.hasContent);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: totalColor.withValues(alpha: 0.10),
              border: Border.all(
                color: totalColor.withValues(alpha: 0.50),
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: PurchaseEntryColors.textMain,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${isCredit ? '- ' : ''}${_currency(widget.ctrl.grandTotal.abs())}',
                      style: PurchaseEntryStyles.grandTotalText,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.ctrl.saveErrorMessage != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PurchaseEntryColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: PurchaseEntryColors.danger.withValues(alpha: 0.20),
                ),
              ),
              child: Text(
                widget.ctrl.saveErrorMessage!,
                style: const TextStyle(
                  color: PurchaseEntryColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: canPrint
                        ? () =>
                            PurchaseVoucherPrintService.printDraft(widget.ctrl)
                        : null,
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
                            .withValues(alpha: 0.80),
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
                    onPressed: widget.ctrl.isSaving
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final saved = await widget.ctrl.savePurchase();
                            if (!mounted) {
                              return;
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  saved
                                      ? 'Purchase voucher saved successfully.'
                                      : widget.ctrl.saveErrorMessage ??
                                          'The purchase could not be saved. Review the details and try again.',
                                ),
                                backgroundColor: saved
                                    ? PurchaseEntryColors.success
                                    : PurchaseEntryColors.danger,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                    icon: widget.ctrl.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            PurchaseEntryIcons.saveVoucher,
                            color: Colors.white,
                            size: 20,
                          ),
                    label: Text(
                      widget.ctrl.isSaving
                          ? 'SAVING...'
                          : PurchaseEntryStrings.saveBtn,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PurchaseEntryColors.success,
                      disabledBackgroundColor:
                          PurchaseEntryColors.success.withValues(alpha: 0.55),
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
              color: PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    PurchaseEntryColors.purchaseAccent.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: PurchaseEntryColors.purchaseAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
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
            _currency(amount),
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
            fontSize: isMid ? 13 : 14,
            fontWeight: FontWeight.w800,
            color: PurchaseEntryColors.textMain,
          ),
        ),
        Text(
          _currency(amount),
          style: TextStyle(
            fontSize: isMid ? 15 : 16,
            fontWeight: FontWeight.w900,
            color: PurchaseEntryColors.textMain,
          ),
        ),
      ],
    );
  }

  Widget _paymentInput(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: PurchaseEntryColors.textMain,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            style: PurchaseEntryStyles.inputText.copyWith(fontSize: 14),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: 'Rs. ',
              prefixIcon: Icon(
                icon,
                size: 18,
                color: PurchaseEntryColors.textMuted,
              ),
              hintStyle:
                  PurchaseEntryStyles.subTitleMuted.copyWith(fontSize: 13),
              filled: true,
              fillColor: PurchaseEntryColors.formInputBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: PurchaseEntryColors.bodyBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: PurchaseEntryColors.bodyBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: PurchaseEntryColors.purchaseAccent,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
