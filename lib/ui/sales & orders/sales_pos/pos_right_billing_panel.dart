// ==========================================
// FILE: pos_right_billing_panel.dart
// TYPE: Smart UI Component (UPGRADED)
// AUTHOR: Senior System Architect
// DESCRIPTION: Payment Hub & Invoice Summary connected to Master Theme.
//              ✅ HOLD System Wired-Up with Smart Badge.
//              ✅ INVOICE PREVIEW Wired-Up.
// ==========================================

import 'package:flutter/material.dart';
import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../logic/sales & orders/sales pos/pos_billing_controller.dart';
import '../../../models/sales & orders/sales_pos_enums/sales_pos_enums.dart';
import 'pos_hold_list_dialog.dart';

// 🚀 NAYA IMPORT INVOICE PREVIEW KE LIYE:
import 'pos_invoice_preview_screen.dart';

class PosRightBillingPanel extends StatefulWidget {
  final PosBillingController ctrl;
  const PosRightBillingPanel({super.key, required this.ctrl});

  @override
  State<PosRightBillingPanel> createState() => _PosRightBillingPanelState();
}

class _PosRightBillingPanelState extends State<PosRightBillingPanel> {
  bool _makingExpanded = false;
  bool _gstExpanded = false;
  bool _exchangeExpanded = false;
  // ✅ promiseDate ab ctrl mein hai (PosBillingController.promiseDate)

  String? _refundMethod;
  double _lastGrandTotal = 0.0;
  double _lastTotalPaid = 0.0;

  @override
  void initState() {
    super.initState();
    _lastGrandTotal = widget.ctrl.grandTotal;
    _lastTotalPaid = widget.ctrl.totalPaid;
    widget.ctrl.addListener(_onCtrlChanged);
  }

  void _onCtrlChanged() {
    bool shouldReset = false;

    if (_lastGrandTotal != widget.ctrl.grandTotal) {
      _lastGrandTotal = widget.ctrl.grandTotal;
      shouldReset = true;
    }
    if (_lastTotalPaid != widget.ctrl.totalPaid) {
      _lastTotalPaid = widget.ctrl.totalPaid;
      shouldReset = true;
    }

    if (shouldReset && _refundMethod != null) {
      setState(() {
        _refundMethod = null;
      });
    }
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onCtrlChanged);
    super.dispose();
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
          dialogBackgroundColor: SalesPosColors.bodyPanelBg,
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
                        _buildPaymentHub(),
                      ],
                    ),
                  ),
                ),
                _buildPanelDivider(),
                _buildActionButtons(),
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
            SalesPosColors.brandGold.withOpacity(0.05),
            SalesPosColors.bodyBorder,
            SalesPosColors.brandGold.withOpacity(0.05),
          ]),
        ),
      );

  // ==========================================
  // RETAIL SUMMARY BOARD
  // ==========================================
  Widget _buildRetailSummaryBoard() {
    double oldGoldFine = 0.0,
        oldSilverFine = 0.0,
        oldPlatinumFine = 0.0,
        oldDiamondFine = 0.0;
    double oldGoldAmt = 0.0,
        oldSilverAmt = 0.0,
        oldPlatinumAmt = 0.0,
        oldDiamondAmt = 0.0;

    for (var item in widget.ctrl.oldGoldItems) {
      if (item.metal == MetalType.gold) {
        oldGoldFine += item.fineWt;
        oldGoldAmt += item.totalValue;
      } else if (item.metal == MetalType.silver) {
        oldSilverFine += item.fineWt;
        oldSilverAmt += item.totalValue;
      } else if (item.metal == MetalType.platinum) {
        oldPlatinumFine += item.fineWt;
        oldPlatinumAmt += item.totalValue;
      } else if (item.metal == MetalType.diamond) {
        oldDiamondFine += item.fineWt;
        oldDiamondAmt += item.totalValue;
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

          if (widget.ctrl.oldGoldMode == OldGoldAdjustMode.metalAdjust) ...[
            if (oldGoldFine > 0)
              _buildSubtleRow("Less: Exchange Gold Fine", 0,
                  customVal: "- ${oldGoldFine.toStringAsFixed(3)} g",
                  color: SalesPosColors.brandGold),
            if (oldSilverFine > 0)
              _buildSubtleRow("Less: Exchange Silver Fine", 0,
                  customVal: "- ${oldSilverFine.toStringAsFixed(3)} g",
                  color: SalesPosColors.brandSilver),
            if (oldPlatinumFine > 0)
              _buildSubtleRow("Less: Exchange Platinum Fine", 0,
                  customVal: "- ${oldPlatinumFine.toStringAsFixed(3)} g",
                  color: SalesPosColors.brandPlatinum),
            if (oldDiamondFine > 0)
              _buildSubtleRow("Less: Exchange Diamond Fine", 0,
                  customVal: "- ${oldDiamondFine.toStringAsFixed(3)} ct",
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

          if (widget.ctrl.oldGoldMode == OldGoldAdjustMode.cashAdjust &&
              widget.ctrl.totalOldGoldAmount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () =>
                        setState(() => _exchangeExpanded = !_exchangeExpanded),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Exchange Value Adjusted",
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color:
                                    SalesPosColors.danger.withOpacity(0.90))),
                        Row(
                          children: [
                            Text(
                                "- ₹ ${widget.ctrl.oldGoldCashDeduction.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: SalesPosColors.danger)),
                            const SizedBox(width: 4),
                            Icon(
                                _exchangeExpanded
                                    ? SalesPosIcons.arrowUp
                                    : SalesPosIcons.arrowDown,
                                color: SalesPosColors.danger,
                                size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_exchangeExpanded)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: SalesPosColors.danger.withOpacity(0.04),
                          border: Border.all(
                              color: SalesPosColors.danger.withOpacity(0.25),
                              width: 1.5),
                          borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          if (oldGoldAmt > 0)
                            _buildSubtleRow("Gold Exchange", oldGoldAmt,
                                color: SalesPosColors.brandGold),
                          if (oldSilverAmt > 0)
                            _buildSubtleRow("Silver Exchange", oldSilverAmt,
                                color: SalesPosColors.brandSilver),
                          if (oldPlatinumAmt > 0)
                            _buildSubtleRow("Platinum Exchange", oldPlatinumAmt,
                                color: SalesPosColors.brandPlatinum),
                          if (oldDiamondAmt > 0)
                            _buildSubtleRow("Diamond Exchange", oldDiamondAmt,
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
                  ? "Taxable Value"
                  : "Net Value",
              widget.ctrl.taxableAmount,
              isMid: true),
          const SizedBox(height: 10),

          if (widget.ctrl.billType == BillType.gst)
            _buildGstDropdownSection()
          else
            _buildNonGstBadge(),
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
                  ? "Taxable Value"
                  : "Net Value",
              widget.ctrl.taxableAmount,
              isMid: true),
          const SizedBox(height: 10),
          if (widget.ctrl.billType == BillType.gst)
            _buildGstDropdownSection()
          else
            _buildNonGstBadge(),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$name LEDGER",
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontSize: 11,
                  letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Fine Sold:",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: SalesPosColors.bodyTextMain.withOpacity(0.8))),
              Text("${sold.toStringAsFixed(3)} $unit",
                  style: const TextStyle(
                      fontSize: 13,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: SalesPosColors.bodyTextMain.withOpacity(0.8))),
              Text("- ${jama.toStringAsFixed(3)} $unit",
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: SalesPosColors.danger)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: color.withOpacity(0.3), height: 1.5),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Net Fine Balance:",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: SalesPosColors.bodyTextMain)),
              Text("${net.toStringAsFixed(3)} $unit",
                  style: TextStyle(
                      fontSize: 14,
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
                            hintText: isGrams ? "Bhaw /g" : "Bhaw /ct",
                            hintStyle: TextStyle(
                                color: color.withOpacity(0.5), fontSize: 13),
                            filled: true,
                            fillColor: SalesPosColors.bodyBg,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: color.withOpacity(0.4), width: 1.5),
                                borderRadius: BorderRadius.circular(6)),
                            focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: color, width: 2.0),
                                borderRadius: BorderRadius.circular(6)),
                          ),
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: color),
                        ))),
                const SizedBox(width: 14),
                Expanded(
                    flex: 5,
                    child: Text(
                      bhawAmt < 0
                          ? "- ₹ ${bhawAmt.abs().toStringAsFixed(2)}"
                          : "₹ ${bhawAmt.toStringAsFixed(2)}",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 16,
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
              color: SalesPosColors.brandGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: SalesPosColors.brandGold.withOpacity(0.35),
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
                      fontSize: 14,
                      letterSpacing: 1.2,
                      color: SalesPosColors.bodyTextMain,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
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
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: SalesPosColors.bodyTextMain)),
          Text(customVal ?? "₹ ${amount.toStringAsFixed(2)}",
              style: TextStyle(
                  fontSize: 13,
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
                fontSize: isMid ? 14 : 15,
                fontWeight: FontWeight.w900,
                color: SalesPosColors.bodyTextMain)),
        Text(
            isCredit
                ? "- ₹ ${amount.abs().toStringAsFixed(2)}"
                : "₹ ${amount.toStringAsFixed(2)}",
            style: TextStyle(
                fontSize: isMid ? 16 : 17,
                fontWeight: FontWeight.w900,
                color: isCredit
                    ? SalesPosColors.success
                    : SalesPosColors.bodyTextMain)),
      ],
    );
  }

  Widget _buildDiscountRow() {
    final discAmt = widget.ctrl.discountAmount;
    final isPercent = widget.ctrl.discountType == DiscountType.percentage;
    // ✅ FIX: % mode mein 100 se zyada ho to warning dikhao
    final double inputVal = double.tryParse(widget.ctrl.discountCtrl.text) ?? 0;
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
                          fontSize: 13,
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
                                  fontSize: 13,
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
                      child: Text("- ₹ ${discAmt.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 14,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: InputDecoration(
                        hintText: "0",
                        hintStyle:
                            TextStyle(color: SalesPosColors.bodyTextMuted),
                        filled: true,
                        fillColor: isInvalidPct
                            ? SalesPosColors.danger.withOpacity(0.08)
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
          // ✅ Warning: % 100 se zyada ho to
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
                    "Max 100% — Auto-capped at 100%",
                    style: TextStyle(
                        fontSize: 11,
                        color: SalesPosColors.danger.withOpacity(0.85),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
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
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: SalesPosColors.bodyTextMain)),
                Row(
                  children: [
                    Text(
                        "₹ ${widget.ctrl.totalMakingCharge.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 13,
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

  Widget _buildWholesaleMetalGstBlock(String metalName, double bhawAmt,
      double makingCharge, double controllerTotalGst, Color brandColor) {
    double ratio(double amt) =>
        widget.ctrl.grossAmount == 0 ? 0 : (amt / widget.ctrl.grossAmount);

    double mTaxable = bhawAmt > 0
        ? bhawAmt - (widget.ctrl.discountAmount * ratio(bhawAmt))
        : 0.0;
    double lTaxable = makingCharge > 0
        ? makingCharge - (widget.ctrl.discountAmount * ratio(makingCharge))
        : 0.0;

    double mGst = mTaxable > 0 ? mTaxable * 0.03 : 0.0;
    double lGst = lTaxable > 0 ? lTaxable * 0.05 : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: brandColor.withOpacity(0.04),
          border: Border.all(color: brandColor.withOpacity(0.25), width: 1.5),
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$metalName GST BREAKDOWN",
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: brandColor)),
          const SizedBox(height: 8),
          _buildSubtleRow(
              mTaxable > 0
                  ? "Tax on Metal (3% on ₹${mTaxable.toStringAsFixed(2)})"
                  : "Tax on Metal (0.00)",
              0,
              customVal: "₹ ${mGst.toStringAsFixed(2)}"),
          _buildSubtleRow(
              lTaxable > 0
                  ? "Tax on Labour (5% on ₹${lTaxable.toStringAsFixed(2)})"
                  : "Tax on Labour (0.00)",
              0,
              customVal: "₹ ${lGst.toStringAsFixed(2)}"),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: brandColor.withOpacity(0.2), height: 1.5)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total GST",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: SalesPosColors.bodyTextMain)),
              Text("₹ ${controllerTotalGst.toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: 14,
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
    String gstTitle =
        isWholesale ? "Total GST (Metal 3%, Labour 5%)" : "Total GST (3%)";

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
                Text(gstTitle,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: SalesPosColors.bodyTextMain)),
                Row(
                  children: [
                    Text("₹ ${widget.ctrl.totalGst.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 13,
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
                  color: SalesPosColors.brandGold.withOpacity(0.05),
                  border: Border.all(
                      color: SalesPosColors.brandGold.withOpacity(0.25),
                      width: 1.5),
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  _buildSubtleRow(
                      isWholesale ? "Total CGST Amount" : "CGST (1.5%)",
                      widget.ctrl.cgst),
                  _buildSubtleRow(
                      isWholesale ? "Total SGST Amount" : "SGST (1.5%)",
                      widget.ctrl.sgst),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                          color: SalesPosColors.brandGold.withOpacity(0.3),
                          height: 1.5)),
                  if (isWholesale) ...[
                    if (widget.ctrl.goldNetFine != 0 ||
                        widget.ctrl.goldMakingCharge > 0)
                      _buildWholesaleMetalGstBlock(
                          "GOLD",
                          widget.ctrl.goldBhawAmt,
                          widget.ctrl.goldMakingCharge,
                          widget.ctrl.goldGst,
                          SalesPosColors.brandGold),
                    if (widget.ctrl.silverNetFine != 0 ||
                        widget.ctrl.silverMakingCharge > 0)
                      _buildWholesaleMetalGstBlock(
                          "SILVER",
                          widget.ctrl.silverBhawAmt,
                          widget.ctrl.silverMakingCharge,
                          widget.ctrl.silverGst,
                          SalesPosColors.brandSilver),
                    if (widget.ctrl.platNetFine != 0 ||
                        widget.ctrl.platinumMakingCharge > 0)
                      _buildWholesaleMetalGstBlock(
                          "PLATINUM",
                          widget.ctrl.platBhawAmt,
                          widget.ctrl.platinumMakingCharge,
                          widget.ctrl.platinumGst,
                          SalesPosColors.brandPlatinum),
                    if (widget.ctrl.diaNetFine != 0 ||
                        widget.ctrl.diamondMakingCharge > 0)
                      _buildWholesaleMetalGstBlock(
                          "DIAMOND",
                          widget.ctrl.diaBhawAmt,
                          widget.ctrl.diamondMakingCharge,
                          widget.ctrl.diamondGst,
                          SalesPosColors.brandDiamond),
                  ] else ...[
                    if (widget.ctrl.totalGoldWt > 0 ||
                        widget.ctrl.goldNetFine != 0)
                      _buildSubtleRow("Gold (HSN 7113)", 0,
                          customVal:
                              "₹ ${widget.ctrl.goldGst.toStringAsFixed(2)}"),
                    if (widget.ctrl.totalSilverWt > 0 ||
                        widget.ctrl.silverNetFine != 0)
                      _buildSubtleRow("Silver (HSN 7113)", 0,
                          customVal:
                              "₹ ${widget.ctrl.silverGst.toStringAsFixed(2)}"),
                    if (widget.ctrl.totalPlatinumWt > 0 ||
                        widget.ctrl.platNetFine != 0)
                      _buildSubtleRow("Platinum (HSN 7113)", 0,
                          customVal:
                              "₹ ${widget.ctrl.platinumGst.toStringAsFixed(2)}"),
                    if (widget.ctrl.totalDiamondWt > 0 ||
                        widget.ctrl.diaNetFine != 0)
                      _buildSubtleRow("Diamond (HSN 7102)", 0,
                          customVal:
                              "₹ ${widget.ctrl.diamondGst.toStringAsFixed(2)}"),
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
        child: Text("NORMAL BILL  ·  NO GST APPLIED",
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: SalesPosColors.bodyTextMain,
                letterSpacing: 0.8)),
      ),
    );
  }

  Widget _buildPaymentHub() {
    final isEmptyCart = widget.ctrl.grandTotal == 0.0;
    final isDue = widget.ctrl.balanceDue > 0.005;
    final isReturn = widget.ctrl.balanceDue < -0.005;
    final isPaid = !isDue && !isReturn && !isEmptyCart;

    final balanceColor = (isReturn && _refundMethod != null) || isPaid
        ? SalesPosColors.success
        : (isReturn ? SalesPosColors.warning : SalesPosColors.danger);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHead(
              icon: SalesPosIcons.paymentHubWallet,
              title: "PAYMENT SETTLEMENT",
              subtitle: "Record received cash amounts"),
          _buildPaymentInput(
              "Cash Received", widget.ctrl.cashCtrl, SalesPosIcons.cashFilled),
          const SizedBox(height: 12),
          _buildPaymentInput("UPI / Bank Transfer", widget.ctrl.upiCtrl,
              SalesPosIcons.bankUpi),
          const SizedBox(height: 12),
          _buildPaymentInput(
              "Card Payment", widget.ctrl.cardCtrl, SalesPosIcons.card),
          const SizedBox(height: 12),
          _buildPaymentInput("Customer Advance", widget.ctrl.advCtrl,
              SalesPosIcons.advancePayment),
          const SizedBox(height: 18),
          if (isEmptyCart)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: SalesPosColors.bodyBg,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: SalesPosColors.bodyBorder, width: 1.5),
              ),
              child: const Center(
                child: Text("NO CASH / AMOUNT DUE YET",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: SalesPosColors.bodyTextMain,
                        letterSpacing: 1.5)),
              ),
            )
          else ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: balanceColor.withOpacity(0.10),
                border: Border.all(
                    color: balanceColor.withOpacity(0.60), width: 2.0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              isReturn && _refundMethod != null
                                  ? "CHANGE RETURNED VIA ${_refundMethod!}"
                                  : isReturn
                                      ? "CHANGE DUE TO CUSTOMER"
                                      : isPaid
                                          ? "INVOICE SETTLED"
                                          : "BALANCE OUTSTANDING",
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: balanceColor)),
                          const SizedBox(height: 4),
                          Text(
                              "₹ ${widget.ctrl.balanceDue.abs().toStringAsFixed(2)}",
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: balanceColor)),
                        ],
                      ),
                      Icon(
                          (isReturn && _refundMethod != null) || isPaid
                              ? SalesPosIcons.settledVerified
                              : isReturn
                                  ? SalesPosIcons.returnChange
                                  : SalesPosIcons.dueWarning,
                          color: balanceColor,
                          size: 32),
                    ],
                  ),
                ],
              ),
            ),
            if (isReturn && _refundMethod == null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _refundMethod = "CASH"),
                      icon: const Icon(SalesPosIcons.cashFilled,
                          size: 18, color: Colors.white),
                      label: const Text("RETURN CASH",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5)),
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
                      onPressed: () => setState(() => _refundMethod = "UPI"),
                      icon: const Icon(SalesPosIcons.bankUpi,
                          size: 18, color: Colors.white),
                      label: const Text("RETURN UPI",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5)),
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
            ],
          ],
          if (isDue && !isEmptyCart) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickPromiseDate(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: SalesPosColors.bodyBg,
                  border: Border.all(
                      color: SalesPosColors.danger.withOpacity(0.50),
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
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: SalesPosColors.danger.withOpacity(0.95))),
                    ]),
                    widget.ctrl.promiseDate != null
                        ? Text(
                            "${widget.ctrl.promiseDate!.day.toString().padLeft(2, '0')}/${widget.ctrl.promiseDate!.month.toString().padLeft(2, '0')}/${widget.ctrl.promiseDate!.year}",
                            style: const TextStyle(
                                color: SalesPosColors.danger,
                                fontWeight: FontWeight.w900,
                                fontSize: 14))
                        : const Text("Select Date",
                            style: TextStyle(
                                color: SalesPosColors.danger,
                                fontWeight: FontWeight.w900,
                                fontSize: 12)),
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
                      fontSize: 13,
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
                  fontSize: 15,
                  fontWeight: FontWeight.w900),
              decoration: InputDecoration(
                hintText: "0.00",
                hintStyle: TextStyle(
                    color: SalesPosColors.bodyTextMuted, fontSize: 14),
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

  // ==========================================
  // FINAL ACTION BUTTONS & HOLD LOGIC
  // ==========================================
  Widget _buildActionButtons() {
    bool isCredit = widget.ctrl.grandTotal < 0;
    Color boxColor =
        isCredit ? SalesPosColors.success : SalesPosColors.brandGold;
    String topLabel = isCredit ? "PAYABLE TO CUSTOMER" : "FINAL CASH AMOUNT";

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: boxColor.withOpacity(0.10),
              border: Border.all(color: boxColor.withOpacity(0.50), width: 2.0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topLabel,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isCredit
                                ? boxColor
                                : SalesPosColors.bodyTextMain,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 6),
                    Text(
                        "${isCredit ? '- ' : ''}₹ ${widget.ctrl.grandTotal.abs().toStringAsFixed(2)}",
                        style: SalesPosStyles.grandTotalText
                            .copyWith(color: boxColor)),
                  ],
                ),
              ],
            ),
          ),

          // --- SMART PARKED BILLS BADGE (Visible only if bills are on hold) ---
          if (widget.ctrl.heldBills.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          PosHoldListDialog(ctrl: widget.ctrl),
                    );
                  },
                  icon: const Icon(SalesPosIcons.holdFilled,
                      size: 16, color: SalesPosColors.warning),
                  label: Text(
                      "VIEW PARKED BILLS (${widget.ctrl.heldBills.length})",
                      style: const TextStyle(
                          color: SalesPosColors.warning,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.0)),
                  style: TextButton.styleFrom(
                    backgroundColor: SalesPosColors.warning.withOpacity(0.1),
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
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    // --- HOLD BUTTON LINKED ---
                    onPressed: () {
                      if (widget.ctrl.saleItems.isEmpty &&
                          widget.ctrl.oldGoldItems.isEmpty) return;
                      widget.ctrl.holdCurrentBill();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Bill successfully parked!"),
                        backgroundColor: SalesPosColors.success,
                        behavior: SnackBarBehavior.floating,
                      ));
                    },
                    icon: const Icon(SalesPosIcons.holdFilled, size: 18),
                    label: const Text("HOLD",
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1.2)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SalesPosColors.warning,
                      side: BorderSide(
                          color: SalesPosColors.warning.withOpacity(0.80),
                          width: 2.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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
                    // 🚀 YAHAN MAIN CHANGE KIYA HAI (GENERATE INVOICE LINKED)
                    onPressed: () {
                      // Safety Check: Agar cart khali hai toh error show karo
                      if (widget.ctrl.saleItems.isEmpty &&
                          widget.ctrl.oldGoldItems.isEmpty) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content:
                              Text("Cart is empty! Please add items first."),
                          backgroundColor: SalesPosColors.danger,
                          behavior: SnackBarBehavior.floating,
                        ));
                        return;
                      }

                      // Agar cart mein item hai, toh naya Preview Screen kholo
                      PosInvoicePreviewScreen.push(
                        context,
                        billingCtrl: widget.ctrl,
                      );
                    },

                    icon: const Icon(SalesPosIcons.printReceipt,
                        color: Colors.white, size: 20),
                    label: const Text("GENERATE INVOICE",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1.0)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SalesPosColors.success,
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
}
