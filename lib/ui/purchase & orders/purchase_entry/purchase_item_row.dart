// =============================================================================
// FILE        : purchase_item_row.dart
// MODULE      : Purchase Entry
// LAYER       : UI
// DESCRIPTION : Single editable row in the purchase items table.
//               Metal dropdown, gross/less/net weight, purity, fine wt, rate, value.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';
import '../../../models/purchase/purchase_enums/purchase_enums.dart';
import '../../../models/purchase/purchase_entry/purchase_item_model.dart';
import '../../../logic/purchase/purchase_entry_controller.dart';

class PurchaseItemRow extends StatefulWidget {
  final int index;
  final PurchaseItemModel item;
  final PurchaseEntryController ctrl;

  const PurchaseItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.ctrl,
  });

  @override
  State<PurchaseItemRow> createState() => _PurchaseItemRowState();
}

class _PurchaseItemRowState extends State<PurchaseItemRow> {
  bool _isHovered = false;
  late PurchaseMetalType _metal;

  @override
  void initState() {
    super.initState();
    _metal = widget.item.metal;
    if (widget.item.purityCtrl.text.isEmpty) {
      widget.item.purityCtrl.text = '100';
    }
  }

  void _onMetalChanged(PurchaseMetalType m) {
    setState(() {
      _metal = m;
      widget.item.updateMetal(m);
    });
  }

  Color get _metalColor {
    switch (_metal) {
      case PurchaseMetalType.gold:     return PurchaseEntryColors.metalGold;
      case PurchaseMetalType.silver:   return PurchaseEntryColors.metalSilver;
      case PurchaseMetalType.platinum: return PurchaseEntryColors.metalPlatinum;
      case PurchaseMetalType.diamond:  return PurchaseEntryColors.metalDiamond;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.item,
      builder: (context, _) {
        final isEven = widget.index % 2 == 0;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit:  (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isHovered
                  ? PurchaseEntryColors.cardHoverBg
                  : (isEven
                      ? PurchaseEntryColors.bodyPanel
                      : PurchaseEntryColors.bodyBg),
              border: const Border(
                bottom: BorderSide(
                  color: PurchaseEntryColors.bodyBorder,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // S.NO
                Expanded(flex: 1, child: _buildSNo(_metalColor)),
                const SizedBox(width: 6),

                // METAL DROPDOWN
                Expanded(flex: 3, child: _buildMetalDropdown()),
                const SizedBox(width: 6),

                // ITEM DESCRIPTION
                Expanded(
                  flex: 4,
                  child: _textField(
                    controller: widget.item.descCtrl,
                    hint: 'Description',
                    focusNode: widget.item.firstFieldFocus,
                  ),
                ),
                const SizedBox(width: 6),

                // GROSS WT
                Expanded(
                  flex: 2,
                  child: _textField(
                    controller: widget.item.grossCtrl,
                    hint: '0.000',
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 6),

                // LESS WT
                Expanded(
                  flex: 2,
                  child: _textField(
                    controller: widget.item.lessCtrl,
                    hint: '0.000',
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 6),

                // NET WT (auto)
                Expanded(
                  flex: 2,
                  child: _autoCell(
                    widget.item.netWt.toStringAsFixed(3),
                    _metalColor,
                  ),
                ),
                const SizedBox(width: 6),

                // PURITY %
                Expanded(flex: 2, child: _buildPurityInput()),
                const SizedBox(width: 6),

                // FINE WT (auto)
                Expanded(
                  flex: 2,
                  child: _autoCell(
                    widget.item.fineWt.toStringAsFixed(3),
                    _metalColor,
                    isBold: true,
                  ),
                ),
                const SizedBox(width: 6),

                // RATE
                Expanded(
                  flex: 3,
                  child: _textField(
                    controller: widget.item.rateCtrl,
                    hint: 'Rate',
                    isNumber: true,
                    onSubmitted: (_) => widget.ctrl.addItem(),
                  ),
                ),
                const SizedBox(width: 6),

                // VALUE (auto)
                Expanded(
                  flex: 3,
                  child: _autoCell(
                    '₹ ${widget.item.totalValue.toStringAsFixed(2)}',
                    PurchaseEntryColors.textMain,
                    align: TextAlign.right,
                    isBold: true,
                  ),
                ),
                const SizedBox(width: 6),

                // DELETE
                Expanded(flex: 1, child: _buildDeleteBtn()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSNo(Color color) {
    return Center(
      child: Container(
        width: 32, height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:  color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Text(
          '${widget.index + 1}',
          style: PurchaseEntryStyles.inputText.copyWith(
            color: color,
            fontSize: 14,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  Widget _buildMetalDropdown() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color:  _metalColor.withOpacity(0.10),
        border: Border.all(color: _metalColor.withOpacity(0.40)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PurchaseMetalType>(
          value:          _metal,
          isExpanded:     true,
          icon: Icon(PurchaseEntryIcons.dropdownArrow, color: _metalColor, size: 22),
          style: PurchaseEntryStyles.inputText.copyWith(
              color: _metalColor, fontSize: 14),
          dropdownColor: PurchaseEntryColors.bodyPanel,
          items: PurchaseMetalType.values
              .map((t) => DropdownMenuItem<PurchaseMetalType>(
                    value: t,
                    child: Text(t.displayName),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) _onMetalChanged(val);
          },
        ),
      ),
    );
  }

  Widget _buildPurityInput() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color:  PurchaseEntryColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _metalColor.withOpacity(0.35)),
      ),
      child: TextFormField(
        controller: widget.item.purityCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.left,
        style: PurchaseEntryStyles.inputText.copyWith(
          color: _metalColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          hintText: '%',
          hintStyle: PurchaseEntryStyles.subTitleMuted.copyWith(
              color: _metalColor.withOpacity(0.50)),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
    FocusNode? focusNode,
    void Function(String)? onSubmitted,
  }) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller:   controller,
        focusNode:    focusNode,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: PurchaseEntryStyles.inputText.copyWith(fontSize: 14),
        onSubmitted:  onSubmitted,
        decoration: InputDecoration(
          hintText:   hint,
          isDense:    true,
          hintStyle: TextStyle(
            color: PurchaseEntryColors.textMuted.withOpacity(0.5),
            fontSize: 13,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          filled:     true,
          fillColor:  PurchaseEntryColors.formInputBg,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: PurchaseEntryColors.bodyBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
                color: PurchaseEntryColors.purchaseAccent, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _autoCell(
    String value,
    Color color, {
    TextAlign align = TextAlign.left,
    bool isBold = false,
  }) {
    final containerAlign = align == TextAlign.right
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: containerAlign,
      decoration: BoxDecoration(
        color:  color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        value,
        textAlign: align,
        style: PurchaseEntryStyles.inputText.copyWith(
          color:    color,
          fontSize: isBold ? 15 : 14,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildDeleteBtn() {
    return Center(
      child: Tooltip(
        message: 'Remove Item',
        waitDuration: const Duration(milliseconds: 400),
        child: InkWell(
          onTap: () => widget.ctrl.removeItem(widget.index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color:  PurchaseEntryColors.danger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: PurchaseEntryColors.danger.withOpacity(0.35)),
            ),
            child: const Icon(
              PurchaseEntryIcons.deleteItem,
              color: PurchaseEntryColors.danger,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
