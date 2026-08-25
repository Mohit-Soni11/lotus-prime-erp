import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../logic/purchase/purchase_entry_controller.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';
import 'customer_metal_purchase_invoice_preview_screen.dart';

class PurchaseRightPanel extends StatefulWidget {
  final PurchaseEntryController ctrl;

  const PurchaseRightPanel({super.key, required this.ctrl});

  @override
  State<PurchaseRightPanel> createState() => _PurchaseRightPanelState();
}

class _PurchaseRightPanelState extends State<PurchaseRightPanel> {
  String _currency(double amount) => 'Rs. ${amount.toStringAsFixed(2)}';

  bool get _hasInvoiceItems {
    return widget.ctrl.items.any((item) => item.hasContent);
  }

  Future<void> _generateInvoice() async {
    final readinessError = widget.ctrl.invoiceReadinessError;
    if (readinessError != null) {
      AppFeedback.show(
        context,
        type: AppFeedbackType.error,
        message: readinessError,
      );
      return;
    }

    await CustomerMetalPurchaseInvoicePreviewScreen.push(
      context,
      controller: widget.ctrl,
    );
  }

  Future<void> _pickPayoutCommitmentDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = widget.ctrl.payoutCommitmentDate;
    final initialDate =
        selected == null || selected.isBefore(today) ? today : selected;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(today.year + 5, today.month, today.day),
      builder: (context, child) {
        final baseTheme = Theme.of(context);
        const colorScheme = ColorScheme.light(
          primary: PurchaseEntryColors.purchaseAccent,
          onPrimary: Colors.white,
          surface: PurchaseEntryColors.bodyPanel,
          onSurface: PurchaseEntryColors.textMain,
        );

        return Theme(
          data: baseTheme.copyWith(
            colorScheme: colorScheme,
            dialogTheme: baseTheme.dialogTheme.copyWith(
              backgroundColor: PurchaseEntryColors.bodyPanel,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: PurchaseEntryColors.bodyPanel,
              headerBackgroundColor: PurchaseEntryColors.purchaseAccent,
              headerForegroundColor: Colors.white,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return PurchaseEntryColors.textMain.withValues(alpha: 0.35);
                }
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return PurchaseEntryColors.textMain;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return PurchaseEntryColors.purchaseAccent;
                }
                return null;
              }),
              todayForegroundColor: const WidgetStatePropertyAll(
                PurchaseEntryColors.purchaseAccent,
              ),
              todayBorder: const BorderSide(
                color: PurchaseEntryColors.purchaseAccent,
                width: 1.5,
              ),
              yearForegroundColor: const WidgetStatePropertyAll(
                PurchaseEntryColors.textMain,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: PurchaseEntryColors.purchaseAccent,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      widget.ctrl.setPayoutCommitmentDate(picked);
    }
  }

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
            subtitle: 'Review assessed metal value and seller payable amount',
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
            child: _pillarRow(
              'Assessed Metal Value',
              widget.ctrl.grossPurchaseAmount,
            ),
          ),
          const SizedBox(height: 12),
          _pillarRow(
            'Seller Payable',
            widget.ctrl.netPurchaseAmount,
            isMid: true,
          ),
        ],
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
            subtitle: 'Record payout released against customer metal purchase',
          ),
          _paymentInput(
              'Cash Payout', widget.ctrl.cashCtrl, PurchaseEntryIcons.cashPay),
          const SizedBox(height: 12),
          _paymentInput('UPI / Bank Payout', widget.ctrl.upiCtrl,
              PurchaseEntryIcons.upiPay),
          const SizedBox(height: 12),
          _paymentInput(
              'Card Payout', widget.ctrl.cardCtrl, PurchaseEntryIcons.cardPay),
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
                  'NO CUSTOMER METAL RECORDED',
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
                            ? 'PAYOUT EXCESS'
                            : isSettled
                                ? 'PAYOUT SETTLED'
                                : 'PENDING SELLER PAYOUT',
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
          if (widget.ctrl.hasPendingSellerPayout) ...[
            const SizedBox(height: 14),
            _payoutCommitmentDateField(),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isCredit = widget.ctrl.grandTotal < 0;
    final canGenerateInvoice = _hasInvoiceItems && !widget.ctrl.isSaving;
    const totalColor = PurchaseEntryColors.purchaseAccent;

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
                      isCredit ? 'PAYOUT CREDIT' : 'SELLER PAYABLE',
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
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: widget.ctrl.isSaving
                        ? null
                        : () async {
                            final saved = await widget.ctrl.savePurchase();
                            if (!mounted) {
                              return;
                            }
                            AppFeedback.show(
                              context,
                              type: saved
                                  ? AppFeedbackType.success
                                  : AppFeedbackType.error,
                              message: saved
                                  ? 'Customer metal purchase saved successfully.'
                                  : widget.ctrl.saveErrorMessage ??
                                      'The purchase could not be saved. Review the details and try again.',
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
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: canGenerateInvoice ? _generateInvoice : null,
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text(
                      'GENERATE INVOICE',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PurchaseEntryColors.purchaseAccent,
                      disabledForegroundColor:
                          PurchaseEntryColors.shellMuted.withValues(alpha: 0.7),
                      side: BorderSide(
                        color: PurchaseEntryColors.purchaseAccent
                            .withValues(alpha: 0.45),
                        width: 1.6,
                      ),
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

  Widget _payoutCommitmentDateField() {
    final hasDate = widget.ctrl.payoutCommitmentDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PAYOUT COMMITMENT DATE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: PurchaseEntryColors.textMain,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 46,
          child: TextField(
            controller: widget.ctrl.payoutCommitmentDateCtrl,
            readOnly: true,
            onTap: _pickPayoutCommitmentDate,
            style: PurchaseEntryStyles.inputText.copyWith(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Select seller payout date',
              prefixIcon: const Icon(
                PurchaseEntryIcons.calendarDate,
                size: 18,
                color: PurchaseEntryColors.purchaseAccent,
              ),
              suffixIcon: hasDate
                  ? IconButton(
                      tooltip: 'Clear payout commitment date',
                      onPressed: widget.ctrl.clearPayoutCommitmentDate,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: PurchaseEntryColors.textMain,
                      ),
                    )
                  : const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: PurchaseEntryColors.textMain,
                    ),
              hintStyle: PurchaseEntryStyles.subTitleMuted.copyWith(
                fontSize: 13,
              ),
              filled: true,
              fillColor: PurchaseEntryColors.bodyBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: PurchaseEntryColors.bodyBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: PurchaseEntryColors.bodyBorder,
                ),
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
        const SizedBox(height: 6),
        Text(
          'Scheduled date to release the remaining seller payout.',
          style: PurchaseEntryStyles.subTitleMuted.copyWith(fontSize: 12),
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
