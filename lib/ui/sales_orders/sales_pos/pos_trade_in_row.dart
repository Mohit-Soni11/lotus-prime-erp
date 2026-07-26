// ==========================================
// FILE: pos_trade_in_row.dart
// TYPE: Smart UI Component (Single Row) (UPGRADED)
// AUTHOR: Senior System Architect
// DESCRIPTION: Low-latency row for the trade-in and exchange table.
//               Strictly mapped Colors, Icons, and TextStyles.
// ==========================================

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/sales_orders/sales_pos_models/sales_pos_models.dart';
import '../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import 'shared_pos_components.dart';

class PosTradeInRow extends StatefulWidget {
  final int index;
  final TradeInItemModel item;
  final PosBillingController ctrl;

  const PosTradeInRow({
    super.key,
    required this.index,
    required this.item,
    required this.ctrl,
  });

  @override
  State<PosTradeInRow> createState() => _PosTradeInRowState();
}

class _PosTradeInRowState extends State<PosTradeInRow> {
  bool _isHovered = false;
  late MetalType _currentMetal;

  @override
  void initState() {
    super.initState();
    _currentMetal = widget.item.metal;

    if (widget.item.purityCtrl.text.isEmpty) {
      widget.item.purityCtrl.text = "100";
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(widget.ctrl.applyTradeInMasterBuyRate(widget.item));
    });
  }

  void _onMetalChanged(MetalType newMetal) {
    setState(() {
      _currentMetal = newMetal;
      widget.item.updateMetal(newMetal);

      if (newMetal == MetalType.silver) {
        widget.item.purityCtrl.clear();
      } else if (widget.item.purityCtrl.text.isEmpty) {
        widget.item.purityCtrl.text = "100";
      }
    });
    unawaited(widget.ctrl.applyTradeInMasterBuyRate(widget.item, force: true));
  }

  Color _metalColor(MetalType metal) {
    switch (metal) {
      case MetalType.gold:
        return SalesPosColors.brandGold;
      case MetalType.silver:
        return SalesPosColors.brandSilver;
      case MetalType.platinum:
        return SalesPosColors.brandPlatinum;
      case MetalType.diamond:
        return SalesPosColors.brandDiamond;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.item,
      builder: (context, _) {
        final metalColor = _metalColor(_currentMetal);
        final isEven = widget.index % 2 == 0;
        final isWholesale = widget.ctrl.billingMode == BillingMode.wholesale;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isHovered
                  ? SalesPosColors.cardHoverBg
                  : (isEven
                      ? SalesPosColors.bodyPanelBg
                      : SalesPosColors.bodyBg),
              border: const Border(
                  bottom:
                      BorderSide(color: SalesPosColors.bodyBorder, width: 1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                    flex: 1, child: _buildSNo(widget.index + 1, metalColor)),
                const SizedBox(width: 6),
                Expanded(flex: 3, child: _buildMetalDropdown(metalColor)),
                const SizedBox(width: 6),
                if (!isWholesale) ...[
                  Expanded(
                    flex: 4,
                    child: PosAtomicTextField(
                      controller: widget.item.descCtrl,
                      hint: "Description",
                      focusNode: widget.item.firstFieldFocus,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  flex: isWholesale ? 4 : 2,
                  child: PosAtomicTextField(
                      controller: widget.item.grossCtrl,
                      hint: "0.000",
                      isNumber: true,
                      focusNode:
                          isWholesale ? widget.item.firstFieldFocus : null),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: isWholesale ? 4 : 2,
                  child: PosAtomicTextField(
                      controller: widget.item.lessCtrl,
                      hint: "0.000",
                      isNumber: true),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: isWholesale ? 4 : 2,
                  child: _buildAutoCell(
                      value: widget.item.netWt.toStringAsFixed(3),
                      color: metalColor,
                      align: TextAlign.left),
                ),
                const SizedBox(width: 6),
                Expanded(
                    flex: isWholesale ? 4 : 2,
                    child: _buildCleanPurityInput(metalColor, isWholesale)),
                const SizedBox(width: 6),
                Expanded(
                  flex: isWholesale ? 4 : 2,
                  child: _buildAutoCell(
                      value: widget.item.fineWt.toStringAsFixed(3),
                      color: metalColor,
                      align: TextAlign.left,
                      isBold: true),
                ),
                const SizedBox(width: 6),
                if (!isWholesale) ...[
                  Expanded(
                    flex: 3,
                    child: PosAtomicTextField(
                      controller: widget.item.rateCtrl,
                      hint: "Rate",
                      isNumber: true,
                      onSubmitted: (_) => widget.ctrl.addTradeInItem(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: _buildAutoCell(
                      value: "Rs ${widget.item.totalValue.toStringAsFixed(2)}",
                      color: SalesPosColors.bodyTextMain,
                      align: TextAlign.right,
                      isBold: true,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(flex: 1, child: _buildDeleteBtn()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSNo(int number, Color metalColor) {
    return Center(
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: metalColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: metalColor.withValues(alpha: 0.35)),
        ),
        child: Text(
          '$number',
          style: SalesPosStyles.inputText.copyWith(
              color: metalColor,
              fontSize: SalesPosStyles.fontBody,
              fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ),
    );
  }

  Widget _buildMetalDropdown(Color metalColor) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: metalColor.withValues(alpha: 0.10),
        border: Border.all(color: metalColor.withValues(alpha: 0.40)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MetalType>(
          value: _currentMetal,
          isExpanded: true,
          icon: Icon(SalesPosIcons.dropdownArrow, color: metalColor, size: 22),
          style: SalesPosStyles.inputText
              .copyWith(color: metalColor, fontSize: SalesPosStyles.fontBody),
          dropdownColor: SalesPosColors.bodyPanelBg,
          items: MetalType.values
              .map((type) => DropdownMenuItem<MetalType>(
                  value: type,
                  child: Text(type.displayName.toString().toUpperCase())))
              .toList(),
          onChanged: (val) {
            if (val != null) _onMetalChanged(val);
          },
        ),
      ),
    );
  }

  Widget _buildCleanPurityInput(Color metalColor, bool isWholesale) {
    final isSilver = _currentMetal == MetalType.silver;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: metalColor.withValues(alpha: 0.35)),
      ),
      child: TextFormField(
        controller: widget.item.purityCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) =>
            unawaited(widget.ctrl.applyTradeInMasterBuyRate(widget.item)),
        textAlign: TextAlign.left,
        style: SalesPosStyles.inputText.copyWith(
            color: metalColor,
            fontFeatures: const [FontFeature.tabularFigures()]),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          hintText: isWholesale ? "Tunch" : (isSilver ? "Opt." : "%"),
          hintStyle: SalesPosStyles.subTitleMuted
              .copyWith(color: metalColor.withValues(alpha: 0.50)),
        ),
      ),
    );
  }

  Widget _buildAutoCell(
      {required String value,
      required Color color,
      TextAlign align = TextAlign.center,
      bool isBold = false}) {
    Alignment containerAlign = Alignment.center;
    if (align == TextAlign.left) containerAlign = Alignment.centerLeft;
    if (align == TextAlign.right) containerAlign = Alignment.centerRight;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: containerAlign,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        value,
        textAlign: align,
        style: SalesPosStyles.inputText.copyWith(
            color: color,
            fontSize:
                isBold ? SalesPosStyles.fontInput : SalesPosStyles.fontBody,
            fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }

  Widget _buildDeleteBtn() {
    return Center(
      child: Tooltip(
        message: "Remove Item",
        waitDuration: const Duration(milliseconds: 400),
        child: InkWell(
          onTap: () => widget.ctrl.removeTradeInItem(widget.index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: SalesPosColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: SalesPosColors.danger.withValues(alpha: 0.35)),
            ),
            child: const Icon(SalesPosIcons.deleteItem,
                color: SalesPosColors.danger, size: 20),
          ),
        ),
      ),
    );
  }
}
