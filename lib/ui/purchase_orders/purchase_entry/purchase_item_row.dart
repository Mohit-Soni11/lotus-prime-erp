import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../logic/purchase/purchase_entry_controller.dart';
import '../../../models/purchase/purchase_enums/purchase_enums.dart';
import '../../../models/purchase/purchase_entry/purchase_item_model.dart';
import '../../../theme/purchase/purchase_entry/purchase_entry_theme.dart';
import 'purchase_item_grid_spec.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(widget.ctrl.applyPurchaseMasterBuyRate(widget.item));
    });
  }

  void _onMetalChanged(PurchaseMetalType metal) {
    setState(() {
      _metal = metal;
      widget.item.updateMetal(metal);
    });
    unawaited(widget.ctrl.applyPurchaseMasterBuyRate(widget.item, force: true));
  }

  Color get _metalColor {
    switch (_metal) {
      case PurchaseMetalType.gold:
        return PurchaseEntryColors.metalGold;
      case PurchaseMetalType.silver:
        return PurchaseEntryColors.metalSilver;
      case PurchaseMetalType.platinum:
        return PurchaseEntryColors.metalPlatinum;
      case PurchaseMetalType.diamond:
        return PurchaseEntryColors.metalDiamond;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.item,
      builder: (context, _) {
        final isEven = widget.index.isEven;
        final isInvalid = widget.item.hasContent && !widget.item.isValidEntry;
        final background = isInvalid
            ? PurchaseEntryColors.danger.withValues(alpha: 0.04)
            : _isHovered
                ? PurchaseEntryColors.cardHoverBg
                : (isEven
                    ? PurchaseEntryColors.bodyPanel
                    : PurchaseEntryColors.bodyBg);

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: background,
              border: Border(
                bottom: BorderSide(
                  color: isInvalid
                      ? PurchaseEntryColors.danger.withValues(alpha: 0.18)
                      : PurchaseEntryColors.bodyBorder,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: PurchaseItemGridSpec.serialFlex,
                  child: _buildSNo(_metalColor),
                ),
                const SizedBox(width: PurchaseItemGridSpec.columnGap),
                Expanded(
                  flex: PurchaseItemGridSpec.metalFlex,
                  child: _buildMetalDropdown(),
                ),
                const SizedBox(width: PurchaseItemGridSpec.columnGap),
                Expanded(
                  flex: PurchaseItemGridSpec.descriptionFlex,
                  child: _atomicTextField(
                    controller: widget.item.descCtrl,
                    hint: 'Item description',
                    focusNode: widget.item.firstFieldFocus,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: PurchaseItemGridSpec.columnGap),
                Expanded(
                  flex: PurchaseItemGridSpec.weightFlex,
                  child: _atomicTextField(
                    controller: widget.item.grossCtrl,
                    hint: '0.000',
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: PurchaseItemGridSpec.columnGap),
                Expanded(
                  flex: PurchaseItemGridSpec.weightFlex,
                  child: _atomicTextField(
                    controller: widget.item.lessCtrl,
                    hint: '0.000',
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: PurchaseItemGridSpec.columnGap),
                Expanded(
                  flex: PurchaseItemGridSpec.weightFlex,
                  child: _autoCell(
                    widget.item.netWt.toStringAsFixed(3),
                    _metalColor,
                  ),
                ),
                const SizedBox(width: PurchaseItemGridSpec.columnGap),
                Expanded(
                  flex: PurchaseItemGridSpec.purityFlex,
                  child: _buildPurityInput(),
                ),
                const SizedBox(width: PurchaseItemGridSpec.columnGap),
                Expanded(
                  flex: PurchaseItemGridSpec.weightFlex,
                  child: _autoCell(
                    widget.item.fineWt.toStringAsFixed(3),
                    _metalColor,
                    isBold: true,
                  ),
                ),
                const SizedBox(width: PurchaseItemGridSpec.columnGap),
                Expanded(
                  flex: PurchaseItemGridSpec.rateFlex,
                  child: _atomicTextField(
                    controller: widget.item.rateCtrl,
                    hint: '0.00',
                    isNumber: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => widget.ctrl.addItem(),
                  ),
                ),
                const SizedBox(width: PurchaseItemGridSpec.columnGap),
                Expanded(
                  flex: PurchaseItemGridSpec.valueFlex,
                  child: _autoCell(
                    'Rs. ${widget.item.totalValue.toStringAsFixed(2)}',
                    PurchaseEntryColors.textMain,
                    align: TextAlign.right,
                    isBold: true,
                  ),
                ),
                const SizedBox(width: PurchaseItemGridSpec.columnGap),
                Expanded(
                  flex: PurchaseItemGridSpec.actionFlex,
                  child: _buildDeleteButton(),
                ),
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
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.35)),
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
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _metalColor.withValues(alpha: 0.10),
        border: Border.all(color: _metalColor.withValues(alpha: 0.40)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PurchaseMetalType>(
          value: _metal,
          isExpanded: true,
          icon: Icon(
            PurchaseEntryIcons.dropdownArrow,
            color: _metalColor,
            size: 22,
          ),
          style: PurchaseEntryStyles.inputText.copyWith(
            color: _metalColor,
            fontSize: 14,
          ),
          dropdownColor: PurchaseEntryColors.bodyPanel,
          items: PurchaseMetalType.values
              .map(
                (type) => DropdownMenuItem<PurchaseMetalType>(
                  value: type,
                  child: Text(type.displayName),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              _onMetalChanged(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPurityInput() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: PurchaseEntryColors.bodyBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _metalColor.withValues(alpha: 0.35)),
      ),
      child: TextFormField(
        controller: widget.item.purityCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        onChanged: (_) =>
            unawaited(widget.ctrl.applyPurchaseMasterBuyRate(widget.item)),
        textAlign: TextAlign.left,
        style: PurchaseEntryStyles.inputText.copyWith(
          color: _metalColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          hintText: 'Purity',
          hintStyle: PurchaseEntryStyles.subTitleMuted.copyWith(
            color: _metalColor.withValues(alpha: 0.50),
          ),
        ),
      ),
    );
  }

  Widget _atomicTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    final action = textInputAction ??
        (onSubmitted != null ? TextInputAction.done : TextInputAction.next);

    return Focus(
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            height: 36,
            padding: EdgeInsets.symmetric(horizontal: isNumber ? 8 : 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PurchaseEntryColors.bodyPanel,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: hasFocus
                    ? PurchaseEntryColors.purchaseAccent
                    : PurchaseEntryColors.bodyBorder,
                width: hasFocus ? 1.5 : 1,
              ),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: isNumber
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              inputFormatters: isNumber
                  ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                  : null,
              textAlign: isNumber ? TextAlign.right : TextAlign.left,
              textInputAction: action,
              style: PurchaseEntryStyles.inputText.copyWith(
                fontSize: isNumber ? 14 : 15,
                fontWeight: isNumber ? FontWeight.w900 : FontWeight.w800,
                fontFeatures:
                    isNumber ? const [FontFeature.tabularFigures()] : null,
              ),
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: hint,
                hintStyle: TextStyle(
                  color: PurchaseEntryColors.textMuted.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _autoCell(
    String value,
    Color color, {
    TextAlign align = TextAlign.left,
    bool isBold = false,
  }) {
    final alignment =
        align == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        value,
        textAlign: align,
        style: PurchaseEntryStyles.inputText.copyWith(
          color: color,
          fontSize: isBold ? 15 : 14,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.ctrl.removeItem(widget.index);
            }
          });
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: PurchaseEntryColors.danger.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: PurchaseEntryColors.danger.withValues(alpha: 0.35),
            ),
          ),
          child: const Icon(
            PurchaseEntryIcons.deleteItem,
            color: PurchaseEntryColors.danger,
            size: 20,
          ),
        ),
      ),
    );
  }
}
