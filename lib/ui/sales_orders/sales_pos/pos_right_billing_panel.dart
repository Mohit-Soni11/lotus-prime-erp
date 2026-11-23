import 'package:flutter/material.dart';
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import 'pos_billing_action_bar.dart';
import 'gst_summary/pos_gst_classification_card.dart';
import 'pos_payment_settlement_section.dart';
import 'advance_stock/pos_advance_stock_resolution_dialog.dart';
import 'advance_stock/pos_advance_quick_stock_dialog.dart';

import 'pos_invoice_preview_screen.dart';
import 'package:lotus_erp/core/feedback/app_feedback.dart';

class PosRightBillingPanel extends StatefulWidget {
  final PosBillingController ctrl;
  const PosRightBillingPanel({super.key, required this.ctrl});

  @override
  State<PosRightBillingPanel> createState() => _PosRightBillingPanelState();
}

class _PosRightBillingPanelState extends State<PosRightBillingPanel> {
  bool _makingExpanded = false;
  bool _gstExpanded = false;
  bool _tradeInExpanded = false;
  bool _openingInvoicePreview = false;

  Future<void> _handleGenerateInvoicePressed() async {
    if (_openingInvoicePreview) return;
    setState(() => _openingInvoicePreview = true);
    try {
      await widget.ctrl.resolvePendingHuidStockSelections();
      if (!mounted) {
        return;
      }

      var stockIssue = await widget.ctrl.validateStockLinkReadiness();
      if (!mounted) {
        return;
      }
      while (stockIssue != null) {
        widget.ctrl.focusSaleItemDescription(stockIssue.rowIndex);
        final action = await PosAdvanceStockResolutionDialog.show(
          context: context,
          controller: widget.ctrl,
          issue: stockIssue,
        );
        if (!mounted || action == null) {
          return;
        }
        if (action == PosAdvanceStockResolutionAction.selectExistingStock) {
          widget.ctrl.focusSaleItemDescription(stockIssue.rowIndex);
          return;
        }
        if (action == PosAdvanceStockResolutionAction.quickAddStock) {
          final linked = await PosAdvanceQuickStockDialog.show(
            context: context,
            controller: widget.ctrl,
            rowIndex: stockIssue.rowIndex,
          );
          if (!mounted) {
            return;
          }
          if (linked) {
            AppFeedback.show(
              context,
              type: AppFeedbackType.success,
              message: 'Stock added and linked with the sale row.',
            );
            stockIssue = await widget.ctrl.validateStockLinkReadiness();
            if (!mounted) return;
            continue;
          }
          return;
        }
      }

      final validationMessage = widget.ctrl.validateInvoiceReadiness();
      if (validationMessage != null) {
        widget.ctrl.focusFirstInvoiceIssue();
        AppFeedback.show(
          context,
          type: AppFeedbackType.error,
          message: validationMessage,
        );
        return;
      }

      await PosInvoicePreviewScreen.push(
        context,
        billingCtrl: widget.ctrl,
      );
    } catch (error) {
      if (mounted) {
        AppFeedback.error(
          context,
          message: 'Invoice preview could not be opened. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _openingInvoicePreview = false);
    }
  }

  Future<void> _pickPromiseDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.ctrl.promiseDate ??
          DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: SalesPosColors.brandGold,
            onPrimary: Colors.white,
            surface: SalesPosColors.bodyPanelBg,
            onSurface: SalesPosColors.bodyTextMain,
          ),
          dialogTheme: const DialogThemeData(
              backgroundColor: SalesPosColors.bodyPanelBg),
        ),
        child: child!,
      ),
    );
    if (picked != null) widget.ctrl.setPromiseDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: SalesPosColors.billingRightPanelBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: SalesPosColors.shadowLight,
                  blurRadius: 8,
                  offset: Offset(0, 2)),
              BoxShadow(
                  color: SalesPosColors.shadowDark,
                  blurRadius: 24,
                  offset: Offset(0, 8)),
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
                        widget.ctrl.billingMode == BillingMode.wholesale
                            ? _buildWholesaleSummaryBoard()
                            : _buildRetailSummaryBoard(),
                        _buildPanelDivider(),
                        PosPaymentSettlementSection(
                          ctrl: widget.ctrl,
                          header: _buildSectionHead(
                            icon: SalesPosIcons.paymentHubWallet,
                            title: 'PAYMENT SETTLEMENT',
                            subtitle: 'Record received payment amounts',
                          ),
                          onPickPromiseDate: () => _pickPromiseDate(context),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildPanelDivider(),
                PosBillingActionBar(
                  ctrl: widget.ctrl,
                  isOpeningInvoicePreview: _openingInvoicePreview,
                  onGenerateInvoicePressed: _handleGenerateInvoicePressed,
                  onParkBillPressed: _handleParkBillPressed,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPanelDivider() => Container(
        height: 2.0,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            SalesPosColors.brandGold.withValues(alpha: 0.05),
            SalesPosColors.bodyBorder,
            SalesPosColors.brandGold.withValues(alpha: 0.05),
          ]),
        ),
      );

  // ==========================================
  // RETAIL SUMMARY BOARD
  // ==========================================
  Widget _buildRetailSummaryBoard() {
    double tradeInGoldFine = 0.0,
        tradeInSilverFine = 0.0,
        tradeInPlatinumFine = 0.0,
        tradeInDiamondFine = 0.0;
    double tradeInGoldAmt = 0.0,
        tradeInSilverAmt = 0.0,
        tradeInPlatinumAmt = 0.0,
        tradeInDiamondAmt = 0.0;

    for (var item in widget.ctrl.tradeInItems) {
      if (item.metal == MetalType.gold) {
        tradeInGoldFine += item.fineWt;
        tradeInGoldAmt += item.totalValue;
      } else if (item.metal == MetalType.silver) {
        tradeInSilverFine += item.fineWt;
        tradeInSilverAmt += item.totalValue;
      } else if (item.metal == MetalType.platinum) {
        tradeInPlatinumFine += item.fineWt;
        tradeInPlatinumAmt += item.totalValue;
      } else if (item.metal == MetalType.diamond) {
        tradeInDiamondFine += item.fineWt;
        tradeInDiamondAmt += item.totalValue;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(
              icon: SalesPosIcons.invoiceOutline,
              title: "INVOICE SUMMARY",
              subtitle: "Detailed itemized breakdown"),

          //if (widget.ctrl.totalGoldWt > 0) _buildSubtleRow("Gold (${widget.ctrl.totalGoldWt.toStringAsFixed(3)} g)", widget.ctrl.totalGoldAmount),
          //if (widget.ctrl.totalSilverWt > 0) _buildSubtleRow("Silver (${widget.ctrl.totalSilverWt.toStringAsFixed(3)} g)", widget.ctrl.totalSilverAmount),
          //if (widget.ctrl.totalPlatinumWt > 0) _buildSubtleRow("Platinum (${widget.ctrl.totalPlatinumWt.toStringAsFixed(3)} g)", widget.ctrl.totalPlatinumAmount),
          //if (widget.ctrl.totalDiamondWt > 0) _buildSubtleRow("Diamond (${widget.ctrl.totalDiamondWt.toStringAsFixed(3)} ct)", widget.ctrl.totalDiamondAmount),

          // 2. pos_right_billing_panel.dart
          // Inside _buildRetailSummaryBoard() method, update the metal rows to use the new 'pure' variables:

          if (widget.ctrl.totalGoldWt > 0)
            _buildSubtleRow(
                "Gold (${widget.ctrl.totalGoldWt.toStringAsFixed(3)} g)",
                widget.ctrl.pureGoldAmount),
          if (widget.ctrl.totalSilverWt > 0)
            _buildSubtleRow(
                "Silver (${widget.ctrl.totalSilverWt.toStringAsFixed(3)} g)",
                widget.ctrl.pureSilverAmount),
          if (widget.ctrl.totalPlatinumWt > 0)
            _buildSubtleRow(
                "Platinum (${widget.ctrl.totalPlatinumWt.toStringAsFixed(3)} g)",
                widget.ctrl.purePlatinumAmount),
          if (widget.ctrl.totalDiamondWt > 0)
            _buildSubtleRow(
                "Diamond (${widget.ctrl.totalDiamondWt.toStringAsFixed(3)} ct)",
                widget.ctrl.pureDiamondAmount),

          if (widget.ctrl.totalMakingCharge > 0) _buildMakingChargesSection(),

          if (widget.ctrl.tradeInMode == TradeInAdjustMode.metalAdjust) ...[
            if (tradeInGoldFine > 0)
              _buildSubtleRow("Less: Customer Gold Fine", 0,
                  customVal: "- ${tradeInGoldFine.toStringAsFixed(3)} g",
                  color: SalesPosColors.brandGold),
            if (tradeInSilverFine > 0)
              _buildSubtleRow("Less: Customer Silver Fine", 0,
                  customVal: "- ${tradeInSilverFine.toStringAsFixed(3)} g",
                  color: SalesPosColors.brandSilver),
            if (tradeInPlatinumFine > 0)
              _buildSubtleRow("Less: Customer Platinum Fine", 0,
                  customVal: "- ${tradeInPlatinumFine.toStringAsFixed(3)} g",
                  color: SalesPosColors.brandPlatinum),
            if (tradeInDiamondFine > 0)
              _buildSubtleRow("Less: Customer Diamond Fine", 0,
                  customVal: "- ${tradeInDiamondFine.toStringAsFixed(3)} ct",
                  color: SalesPosColors.brandDiamond),
          ],

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: SalesPosColors.bodyBg,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: SalesPosColors.bodyBorder, width: 1.5)),
            child: _buildPillarRow("Gross Value", widget.ctrl.grossAmount),
          ),
          const SizedBox(height: 12),

          if (widget.ctrl.tradeInMode == TradeInAdjustMode.cashAdjust &&
              widget.ctrl.totalTradeInAmount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () =>
                        setState(() => _tradeInExpanded = !_tradeInExpanded),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Customer Metal Adjusted",
                            style: TextStyle(
                                fontSize: SalesPosStyles.fontLabel,
                                fontWeight: FontWeight.w900,
                                color: SalesPosColors.danger
                                    .withValues(alpha: 0.90))),
                        Row(
                          children: [
                            Text(
                                "- Rs ${widget.ctrl.tradeInCashDeduction.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontSize: SalesPosStyles.fontBody,
                                    fontWeight: FontWeight.w900,
                                    color: SalesPosColors.danger)),
                            const SizedBox(width: 4),
                            Icon(
                                _tradeInExpanded
                                    ? SalesPosIcons.arrowUp
                                    : SalesPosIcons.arrowDown,
                                color: SalesPosColors.danger,
                                size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_tradeInExpanded)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: SalesPosColors.danger.withValues(alpha: 0.04),
                          border: Border.all(
                              color:
                                  SalesPosColors.danger.withValues(alpha: 0.25),
                              width: 1.5),
                          borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          if (tradeInGoldAmt > 0)
                            _buildSubtleRow("Gold Settlement", tradeInGoldAmt,
                                color: SalesPosColors.brandGold),
                          if (tradeInSilverAmt > 0)
                            _buildSubtleRow(
                                "Silver Settlement", tradeInSilverAmt,
                                color: SalesPosColors.brandSilver),
                          if (tradeInPlatinumAmt > 0)
                            _buildSubtleRow(
                                "Platinum Settlement", tradeInPlatinumAmt,
                                color: SalesPosColors.brandPlatinum),
                          if (tradeInDiamondAmt > 0)
                            _buildSubtleRow(
                                "Diamond Settlement", tradeInDiamondAmt,
                                color: SalesPosColors.brandDiamond),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          _buildDiscountRow(),
          const SizedBox(height: 8),
          _buildPillarRow(
              widget.ctrl.billType == BillType.gst
                  ? widget.ctrl.gstPricingMode == GstPricingMode.inclusive
                      ? "Taxable Value (Legacy Included)"
                      : "Taxable Value"
                  : "Net Value",
              widget.ctrl.taxableAmount,
              isMid: true),
          const SizedBox(height: 10),

          if (widget.ctrl.billType == BillType.gst)
            _buildGstDropdownSection()
          else
            _buildNonGstBadge(),
          _buildRoundOffRow(),
        ],
      ),
    );
  }

  // ==========================================
  // WHOLESALE SUMMARY BOARD
  // ==========================================
  Widget _buildWholesaleSummaryBoard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(
              icon: SalesPosIcons.emptyStateSync,
              title: "METAL LEDGERS",
              subtitle: "Fine metal & rate settlement"),
          _buildWholesaleMetalLedger(
              "GOLD",
              true,
              widget.ctrl.goldSoldFine,
              widget.ctrl.goldJamaFine,
              widget.ctrl.goldNetFine,
              widget.ctrl.goldBhawCtrl,
              widget.ctrl.goldBhawAmt,
              SalesPosColors.brandGold),
          _buildWholesaleMetalLedger(
              "SILVER",
              true,
              widget.ctrl.silverSoldFine,
              widget.ctrl.silverJamaFine,
              widget.ctrl.silverNetFine,
              widget.ctrl.silverBhawCtrl,
              widget.ctrl.silverBhawAmt,
              SalesPosColors.brandSilver),
          _buildWholesaleMetalLedger(
              "PLATINUM",
              true,
              widget.ctrl.platSoldFine,
              widget.ctrl.platJamaFine,
              widget.ctrl.platNetFine,
              widget.ctrl.platBhawCtrl,
              widget.ctrl.platBhawAmt,
              SalesPosColors.brandPlatinum),
          _buildWholesaleMetalLedger(
              "DIAMOND",
              false,
              widget.ctrl.diaSoldFine,
              widget.ctrl.diaJamaFine,
              widget.ctrl.diaNetFine,
              widget.ctrl.diaBhawCtrl,
              widget.ctrl.diaBhawAmt,
              SalesPosColors.brandDiamond),
          if (widget.ctrl.totalMakingCharge > 0) ...[
            const SizedBox(height: 8),
            _buildSubtleRow(
                "Total Labour Charges", widget.ctrl.totalMakingCharge,
                color: SalesPosColors.bodyTextMain),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: SalesPosColors.bodyBg,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: SalesPosColors.bodyBorder, width: 1.5)),
            child: _buildPillarRow("Gross Value", widget.ctrl.grossAmount),
          ),
          const SizedBox(height: 12),
          _buildDiscountRow(),
          const SizedBox(height: 8),
          _buildPillarRow(
              widget.ctrl.billType == BillType.gst
                  ? widget.ctrl.gstPricingMode == GstPricingMode.inclusive
                      ? "Taxable Value (Legacy Included)"
                      : "Taxable Value"
                  : "Net Value",
              widget.ctrl.taxableAmount,
              isMid: true),
          const SizedBox(height: 10),
          if (widget.ctrl.billType == BillType.gst)
            _buildGstDropdownSection()
          else
            _buildNonGstBadge(),
          _buildRoundOffRow(),
        ],
      ),
    );
  }

  Widget _buildWholesaleMetalLedger(
      String name,
      bool isGrams,
      double sold,
      double jama,
      double net,
      TextEditingController bhawCtrl,
      double bhawAmt,
      Color color) {
    if (sold == 0 && jama == 0) return const SizedBox.shrink();

    String unit = isGrams ? "g" : "ct";
    final rateHint =
        !isGrams ? "Rate /ct" : (name == "SILVER" ? "Rate /kg" : "Rate /10g");

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$name LEDGER",
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontSize: SalesPosStyles.fontCaption,
                  letterSpacing: 0)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Fine Sold:",
                  style: TextStyle(
                      fontSize: SalesPosStyles.fontLabel,
                      fontWeight: FontWeight.w800,
                      color:
                          SalesPosColors.bodyTextMain.withValues(alpha: 0.8))),
              Text("${sold.toStringAsFixed(3)} $unit",
                  style: const TextStyle(
                      fontSize: SalesPosStyles.fontLabel,
                      fontWeight: FontWeight.w900,
                      color: SalesPosColors.bodyTextMain)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Fine Jama:",
                  style: TextStyle(
                      fontSize: SalesPosStyles.fontLabel,
                      fontWeight: FontWeight.w800,
                      color:
                          SalesPosColors.bodyTextMain.withValues(alpha: 0.8))),
              Text("- ${jama.toStringAsFixed(3)} $unit",
                  style: const TextStyle(
                      fontSize: SalesPosStyles.fontLabel,
                      fontWeight: FontWeight.w900,
                      color: SalesPosColors.danger)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: color.withValues(alpha: 0.3), height: 1.5),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Net Fine Balance:",
                  style: TextStyle(
                      fontSize: SalesPosStyles.fontBody,
                      fontWeight: FontWeight.w900,
                      color: SalesPosColors.bodyTextMain)),
              Text("${net.toStringAsFixed(3)} $unit",
                  style: TextStyle(
                      fontSize: SalesPosStyles.fontBody,
                      fontWeight: FontWeight.w900,
                      color: net < 0
                          ? SalesPosColors.success
                          : SalesPosColors.bodyTextMain)),
            ],
          ),
          if (net != 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    flex: 5,
                    child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: bhawCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            hintText: rateHint,
                            hintStyle: TextStyle(
                                color: color.withValues(alpha: 0.5),
                                fontSize: SalesPosStyles.fontLabel),
                            filled: true,
                            fillColor: SalesPosColors.bodyBg,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: color.withValues(alpha: 0.4),
                                    width: 1.5),
                                borderRadius: BorderRadius.circular(6)),
                            focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: color, width: 2.0),
                                borderRadius: BorderRadius.circular(6)),
                          ),
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: SalesPosStyles.fontBody,
                              color: color),
                        ))),
                const SizedBox(width: 14),
                Expanded(
                    flex: 5,
                    child: Text(
                      bhawAmt < 0
                          ? "- Rs ${bhawAmt.abs().toStringAsFixed(2)}"
                          : "Rs ${bhawAmt.toStringAsFixed(2)}",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: SalesPosStyles.fontValue,
                          fontWeight: FontWeight.w900,
                          color: bhawAmt < 0
                              ? SalesPosColors.success
                              : SalesPosColors.bodyTextMain),
                    ))
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // COMMON HELPER WIDGETS
  // ==========================================

  Widget _buildSectionHead(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: SalesPosColors.brandGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: SalesPosColors.brandGold.withValues(alpha: 0.35),
                  width: 1.5),
            ),
            child: Icon(icon, color: SalesPosColors.brandGold, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: SalesPosStyles.fontBody,
                      letterSpacing: 0,
                      color: SalesPosColors.bodyTextMain,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: SalesPosStyles.fontCaption,
                      fontWeight: FontWeight.w800,
                      color: SalesPosColors.bodyTextMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubtleRow(String label, double amount,
      {String? customVal, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: SalesPosStyles.fontLabel,
                  fontWeight: FontWeight.w800,
                  color: SalesPosColors.bodyTextMain)),
          Text(customVal ?? "Rs ${amount.toStringAsFixed(2)}",
              style: TextStyle(
                  fontSize: SalesPosStyles.fontLabel,
                  fontWeight: FontWeight.w900,
                  color: color ?? SalesPosColors.bodyTextMain)),
        ],
      ),
    );
  }

  Widget _buildPillarRow(String label, double amount, {bool isMid = false}) {
    bool isCredit = amount < 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize:
                    isMid ? SalesPosStyles.fontBody : SalesPosStyles.fontInput,
                fontWeight: FontWeight.w900,
                color: SalesPosColors.bodyTextMain)),
        Text(
            isCredit
                ? "- Rs ${amount.abs().toStringAsFixed(2)}"
                : "Rs ${amount.toStringAsFixed(2)}",
            style: TextStyle(
                fontSize:
                    isMid ? SalesPosStyles.fontValue : SalesPosStyles.fontTitle,
                fontWeight: FontWeight.w900,
                color: isCredit
                    ? SalesPosColors.success
                    : SalesPosColors.bodyTextMain)),
      ],
    );
  }

  Widget _buildDiscountRow() {
    final discAmt = widget.ctrl.discountAmount;
    if (widget.ctrl.presentPaymentAllocationMetals.length > 1) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildSubtleRow('Metal-wise Discount', discAmt,
            customVal: '- Rs ${discAmt.toStringAsFixed(2)}'),
      );
    }
    final isPercent = widget.ctrl.discountType == DiscountType.percentage;
    // Show a warning when percentage mode exceeds 100%.
    final double inputVal = widget.ctrl.discountInputAmount;
    final bool isInvalidPct = isPercent && inputVal > 100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("Discount Applied",
                      style: TextStyle(
                          fontSize: SalesPosStyles.fontLabel,
                          fontWeight: FontWeight.w900,
                          color: SalesPosColors.bodyTextMain)),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => widget.ctrl.toggleDiscountType(isPercent
                        ? DiscountType.flatAmount
                        : DiscountType.percentage),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: SalesPosColors.bodyBg,
                          border: Border.all(
                              color: SalesPosColors.bodyBorder, width: 1.5),
                          borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        children: [
                          Text(widget.ctrl.discountType.symbol,
                              style: const TextStyle(
                                  color: SalesPosColors.brandGold,
                                  fontSize: SalesPosStyles.fontLabel,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(width: 4),
                          const Icon(SalesPosIcons.arrowDown,
                              color: SalesPosColors.bodyTextMain, size: 16),
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
                      child: Text("- Rs ${discAmt.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: SalesPosStyles.fontBody,
                              fontWeight: FontWeight.w900,
                              color: SalesPosColors.danger)),
                    ),
                  SizedBox(
                    width: 85,
                    height: 34,
                    child: TextField(
                      controller: widget.ctrl.discountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: isInvalidPct
                            ? SalesPosColors.danger
                            : SalesPosColors.danger,
                        fontSize: SalesPosStyles.fontBody,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: InputDecoration(
                        hintText: "0",
                        hintStyle: const TextStyle(
                            color: SalesPosColors.bodyTextMuted),
                        filled: true,
                        fillColor: isInvalidPct
                            ? SalesPosColors.danger.withValues(alpha: 0.08)
                            : SalesPosColors.bodyBg,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 0),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: isInvalidPct
                                  ? SalesPosColors.danger
                                  : SalesPosColors.bodyBorder,
                              width: isInvalidPct ? 2.0 : 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: SalesPosColors.danger, width: 2.0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          //  Warn when percentage exceeds 100%.
          if (isInvalidPct)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: SalesPosColors.danger, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    "Max 100%  -  Auto-capped at 100%",
                    style: TextStyle(
                        fontSize: SalesPosStyles.fontCaption,
                        color: SalesPosColors.danger.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoundOffRow() {
    final roundOff = widget.ctrl.roundOffAmount;
    if (roundOff.abs() <= 0.005) return const SizedBox.shrink();

    final label = roundOff > 0
        ? "+ Rs ${roundOff.toStringAsFixed(2)}"
        : "- Rs ${roundOff.abs().toStringAsFixed(2)}";
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _buildSubtleRow(
        "Round Off",
        roundOff,
        customVal: label,
        color: SalesPosColors.bodyTextMain,
      ),
    );
  }

  Widget _buildMakingChargesSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _makingExpanded = !_makingExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Making Charges",
                    style: TextStyle(
                        fontSize: SalesPosStyles.fontLabel,
                        fontWeight: FontWeight.w800,
                        color: SalesPosColors.bodyTextMain)),
                Row(
                  children: [
                    Text(
                        "Rs ${widget.ctrl.totalMakingCharge.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: SalesPosStyles.fontLabel,
                            fontWeight: FontWeight.w900,
                            color: SalesPosColors.bodyTextMain)),
                    const SizedBox(width: 4),
                    Icon(
                        _makingExpanded
                            ? SalesPosIcons.arrowUp
                            : SalesPosIcons.arrowDown,
                        color: SalesPosColors.bodyTextMain,
                        size: 18),
                  ],
                ),
              ],
            ),
          ),
          if (_makingExpanded)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: SalesPosColors.bodyBg,
                  border:
                      Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  if (widget.ctrl.goldMakingCharge > 0)
                    _buildSubtleRow(
                        "Gold Making", widget.ctrl.goldMakingCharge),
                  if (widget.ctrl.silverMakingCharge > 0)
                    _buildSubtleRow(
                        "Silver Making", widget.ctrl.silverMakingCharge),
                  if (widget.ctrl.platinumMakingCharge > 0)
                    _buildSubtleRow(
                        "Platinum Making", widget.ctrl.platinumMakingCharge),
                  if (widget.ctrl.diamondMakingCharge > 0)
                    _buildSubtleRow(
                        "Diamond Making", widget.ctrl.diamondMakingCharge),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWholesaleMetalGstBlock(
      String metalName, MetalType metal, double totalGst, Color brandColor) {
    final tax = widget.ctrl.metalTaxBreakdown(metal);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: brandColor.withValues(alpha: 0.04),
          border:
              Border.all(color: brandColor.withValues(alpha: 0.25), width: 1.5),
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$metalName GST BREAKDOWN",
              style: TextStyle(
                  fontSize: SalesPosStyles.fontCaption,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  color: brandColor)),
          const SizedBox(height: 8),
          _buildSubtleRow(
              tax.metalTaxable > 0
                  ? "Tax on Metal (${widget.ctrl.metalGstRateLabel(metal)} on Rs ${tax.metalTaxable.toStringAsFixed(2)})"
                  : "Tax on Metal (0.00)",
              0,
              customVal: "Rs ${tax.metalTax.toStringAsFixed(2)}"),
          _buildSubtleRow(
              tax.labourTaxable > 0
                  ? "Tax on Labour (${widget.ctrl.makingGstRateLabel} on Rs ${tax.labourTaxable.toStringAsFixed(2)})"
                  : "Tax on Labour (0.00)",
              0,
              customVal: "Rs ${tax.labourTax.toStringAsFixed(2)}"),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                  color: brandColor.withValues(alpha: 0.2), height: 1.5)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total GST",
                  style: TextStyle(
                      fontSize: SalesPosStyles.fontLabel,
                      fontWeight: FontWeight.w900,
                      color: SalesPosColors.bodyTextMain)),
              Text("Rs ${totalGst.toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: SalesPosStyles.fontBody,
                      fontWeight: FontWeight.w900,
                      color: brandColor)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGstDropdownSection() {
    bool isWholesale = widget.ctrl.billingMode == BillingMode.wholesale;
    String gstTitle = isWholesale
        ? "Total GST (Metal ${widget.ctrl.jewelleryGstRateLabel}, Labour ${widget.ctrl.makingGstRateLabel})"
        : "Total GST (${widget.ctrl.jewelleryGstRateLabel})";
    if (widget.ctrl.gstPricingMode == GstPricingMode.inclusive) {
      gstTitle = '$gstTitle - Included';
    }
    final isInterStateSupply = widget.ctrl.isInterStateSupplyPreview;
    final classificationLines = widget.ctrl.gstClassificationLines;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isWholesale)
            PosGstClassificationCard(
              lines: classificationLines,
            ),
          InkWell(
            onTap: () => setState(() => _gstExpanded = !_gstExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(gstTitle,
                    style: const TextStyle(
                        fontSize: SalesPosStyles.fontLabel,
                        fontWeight: FontWeight.w800,
                        color: SalesPosColors.bodyTextMain)),
                Row(
                  children: [
                    Text("Rs ${widget.ctrl.totalGst.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: SalesPosStyles.fontLabel,
                            fontWeight: FontWeight.w900,
                            color: SalesPosColors.bodyTextMain)),
                    const SizedBox(width: 4),
                    Icon(
                        _gstExpanded
                            ? SalesPosIcons.arrowUp
                            : SalesPosIcons.arrowDown,
                        color: SalesPosColors.bodyTextMain,
                        size: 18),
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
                  color: SalesPosColors.brandGold.withValues(alpha: 0.05),
                  border: Border.all(
                      color: SalesPosColors.brandGold.withValues(alpha: 0.25),
                      width: 1.5),
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  _buildSubtleRow(
                    "Supply Type",
                    0,
                    customVal: widget.ctrl.gstJurisdictionLabel,
                  ),
                  if (isInterStateSupply)
                    _buildSubtleRow(
                      "IGST (${widget.ctrl.jewelleryGstRateLabel})",
                      widget.ctrl.outputIgst,
                    )
                  else ...[
                    _buildSubtleRow(
                      isWholesale
                          ? "Total CGST Amount"
                          : "CGST (${widget.ctrl.halfJewelleryGstRateLabel})",
                      widget.ctrl.outputCgst,
                    ),
                    _buildSubtleRow(
                      isWholesale
                          ? "Total SGST Amount"
                          : "SGST (${widget.ctrl.halfJewelleryGstRateLabel})",
                      widget.ctrl.outputSgst,
                    ),
                  ],
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                          color:
                              SalesPosColors.brandGold.withValues(alpha: 0.3),
                          height: 1.5)),
                  if (isWholesale) ...[
                    if (widget.ctrl.goldNetFine != 0 ||
                        widget.ctrl.goldMakingCharge > 0)
                      _buildWholesaleMetalGstBlock("GOLD", MetalType.gold,
                          widget.ctrl.goldGst, SalesPosColors.brandGold),
                    if (widget.ctrl.silverNetFine != 0 ||
                        widget.ctrl.silverMakingCharge > 0)
                      _buildWholesaleMetalGstBlock("SILVER", MetalType.silver,
                          widget.ctrl.silverGst, SalesPosColors.brandSilver),
                    if (widget.ctrl.platNetFine != 0 ||
                        widget.ctrl.platinumMakingCharge > 0)
                      _buildWholesaleMetalGstBlock(
                          "PLATINUM",
                          MetalType.platinum,
                          widget.ctrl.platinumGst,
                          SalesPosColors.brandPlatinum),
                    if (widget.ctrl.diaNetFine != 0 ||
                        widget.ctrl.diamondMakingCharge > 0)
                      _buildWholesaleMetalGstBlock("DIAMOND", MetalType.diamond,
                          widget.ctrl.diamondGst, SalesPosColors.brandDiamond),
                  ] else ...[
                    if (widget.ctrl.totalGoldWt > 0 ||
                        widget.ctrl.goldNetFine != 0)
                      _buildSubtleRow("Gold Jewellery", 0,
                          customVal:
                              "Rs ${widget.ctrl.goldGst.toStringAsFixed(2)}"),
                    if (widget.ctrl.totalSilverWt > 0 ||
                        widget.ctrl.silverNetFine != 0)
                      _buildSubtleRow("Silver Jewellery", 0,
                          customVal:
                              "Rs ${widget.ctrl.silverGst.toStringAsFixed(2)}"),
                    if (widget.ctrl.totalPlatinumWt > 0 ||
                        widget.ctrl.platNetFine != 0)
                      _buildSubtleRow("Platinum Jewellery", 0,
                          customVal:
                              "Rs ${widget.ctrl.platinumGst.toStringAsFixed(2)}"),
                    if (widget.ctrl.totalDiamondWt > 0 ||
                        widget.ctrl.diaNetFine != 0)
                      _buildSubtleRow("Loose Diamond / Stone", 0,
                          customVal:
                              "Rs ${widget.ctrl.diamondGst.toStringAsFixed(2)}"),
                  ]
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNonGstBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        border: Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text("SALES INVOICE    GST NOT APPLIED",
            style: TextStyle(
                fontSize: SalesPosStyles.fontCaption,
                fontWeight: FontWeight.w900,
                color: SalesPosColors.bodyTextMain,
                letterSpacing: 0)),
      ),
    );
  }

  void _handleParkBillPressed() {
    final parked = widget.ctrl.holdCurrentBill();
    if (!parked) {
      AppFeedback.show(
        context,
        type: AppFeedbackType.warning,
        message:
            "Finalized invoices cannot be parked. Start a new sale instead.",
      );
      return;
    }
    AppFeedback.show(
      context,
      type: AppFeedbackType.success,
      message: "Bill successfully parked!",
    );
  }
}
