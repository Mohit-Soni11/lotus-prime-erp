import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lotus_erp/features/stock/gold/application/gold_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_gold/gold_stock_colors.dart';

import 'package:lotus_erp/features/stock/gold/domain/models/gold_item_model.dart';

const double _invoiceFieldHeight = 38;
const double _invoiceFieldRadius = 8;

class GoldItemRow extends StatefulWidget {
  final int index;
  final GoldItemModel model;
  final GoldStockController ctrl;

  const GoldItemRow({
    super.key,
    required this.index,
    required this.model,
    required this.ctrl,
  });

  @override
  State<GoldItemRow> createState() => _GoldItemRowState();
}

class _GoldItemRowState extends State<GoldItemRow> {
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _handlePendingFocus();
  }

  @override
  void didUpdateWidget(covariant GoldItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handlePendingFocus();
  }

  void _handlePendingFocus() {
    if (!widget.ctrl.shouldRequestGoldFocus(widget.model.id)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.model.categoryFocus.requestFocus();
      widget.ctrl.clearGoldFocusRequest(widget.model.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEven = widget.index.isEven;

    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          widget.ctrl.setGoldActiveRow(widget.model.id);
        }
      },
      child: ListenableBuilder(
        listenable: widget.model,
        builder: (context, _) {
          return MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isHovered
                    ? GoldStockColors.cardHoverBg
                    : (isEven
                        ? GoldStockColors.bodyBg
                        : GoldStockColors.cardBg),
                border: const Border(
                  bottom: BorderSide(
                    color: GoldStockColors.cardBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 2, child: _buildSNo()),
                  const SizedBox(width: 6),
                  Expanded(flex: 3, child: _buildCategoryField()),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 4,
                    child: _GoldTextField(
                      controller: widget.model.itemNameCtrl,
                      focusNode: widget.model.itemNameFocus,
                      hint: 'Item name',
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => widget.model.huidFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: _GoldTextField(
                      controller: widget.model.huidCtrl,
                      focusNode: widget.model.huidFocus,
                      hint: 'HUID',
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9]'),
                        ),
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onSubmitted: (_) =>
                          widget.model.grossFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: _GoldTextField(
                      controller: widget.model.grossCtrl,
                      focusNode: widget.model.grossFocus,
                      hint: '0.000',
                      isNumber: true,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => widget.model.lessFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: _GoldTextField(
                      controller: widget.model.lessCtrl,
                      focusNode: widget.model.lessFocus,
                      hint: '0.000',
                      isNumber: true,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) =>
                          widget.model.purityFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: _buildAutoCell(
                      value: widget.model.netWeight.toStringAsFixed(3),
                      color: GoldStockColors.brandGold,
                      align: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: _GoldTextField(
                      controller: widget.model.purityCtrl,
                      focusNode: widget.model.purityFocus,
                      hint: 'Purity',
                      isNumber: true,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) =>
                          widget.model.wastageFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: _GoldTextField(
                      controller: widget.model.wastageCtrl,
                      focusNode: widget.model.wastageFocus,
                      hint: '0.00',
                      isNumber: true,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) =>
                          widget.model.makingFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: _buildAutoCell(
                      value: _actualFineWeight().toStringAsFixed(3),
                      color: GoldStockColors.success,
                      align: TextAlign.center,
                      isBold: true,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(flex: 3, child: _buildMakingField()),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: Tooltip(
                      message:
                          'Fine ${widget.model.fineWeight.toStringAsFixed(3)} g at ${widget.model.effectiveTotalPurityLabel}% purity x Rs ${widget.model.purchaseRate.toStringAsFixed(2)}/g',
                      waitDuration: const Duration(milliseconds: 400),
                      child: _buildAutoCell(
                        value:
                            'Rs ${widget.model.totalAmount.toStringAsFixed(2)}',
                        color: GoldStockColors.textDark,
                        align: TextAlign.right,
                        isBold: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(flex: 2, child: _buildRowActions()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryField() {
    return _GoldPopupField(
      controller: widget.model.categoryCtrl,
      focusNode: widget.model.categoryFocus,
      hint: 'Item type',
      popupItems: GoldItemModel.categoryPresets,
      onSelected: (value) {
        if (value == 'Other') {
          if (GoldItemModel.categoryPresets.contains(
            widget.model.categoryCtrl.text.trim(),
          )) {
            widget.model.categoryCtrl.clear();
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.model.categoryFocus.requestFocus();
            }
          });
          return;
        }

        _setText(widget.model.categoryCtrl, value);
        widget.model.itemNameFocus.requestFocus();
      },
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => widget.model.itemNameFocus.requestFocus(),
    );
  }

  void _setText(TextEditingController controller, String value) {
    controller.text = value;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: value.length),
    );
  }

  double _actualFineWeight() {
    final fine =
        widget.model.netWeight * (widget.model.basePurityPercent / 100);
    return double.parse(fine.toStringAsFixed(3));
  }

  Widget _buildSNo() {
    return Center(
      child: Container(
        width: 54,
        height: _invoiceFieldHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: GoldStockColors.brandGold.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(_invoiceFieldRadius),
          border: Border.all(
            color: GoldStockColors.brandGold.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          (widget.index + 1).toString().padLeft(2, '0'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: GoldStockColors.brandGold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoCell({
    required String value,
    required Color color,
    required TextAlign align,
    bool isBold = false,
  }) {
    return Container(
      height: _invoiceFieldHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment:
          align == TextAlign.center ? Alignment.center : Alignment.centerRight,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(_invoiceFieldRadius),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: align == TextAlign.center
            ? Alignment.center
            : Alignment.centerRight,
        child: Text(
          value,
          maxLines: 1,
          softWrap: false,
          textAlign: align,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: isBold ? 16 : 15,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  Widget _buildMakingField() {
    return Row(
      children: [
        Expanded(
          child: _GoldTextField(
            controller: widget.model.makingCtrl,
            focusNode: widget.model.makingFocus,
            hint: widget.model.makingHint,
            isNumber: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) =>
                widget.ctrl.completeRowAndAdvanceGold(widget.model.id),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Toggle: /g -> Flat -> %',
          waitDuration: const Duration(milliseconds: 400),
          child: InkWell(
            onTap: widget.model.toggleMakingType,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: _invoiceFieldHeight,
              height: _invoiceFieldHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: GoldStockColors.brandGold.withValues(alpha: 0.12),
                border: Border.all(
                  color: GoldStockColors.brandGold.withValues(alpha: 0.40),
                ),
                borderRadius: BorderRadius.circular(_invoiceFieldRadius),
              ),
              child: Text(
                widget.model.makingTypeSymbol,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: GoldStockColors.brandGold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRowActions() {
    return Center(
      child: Tooltip(
        message: 'Remove item',
        waitDuration: const Duration(milliseconds: 400),
        child: InkWell(
          onTap: () => widget.ctrl.removeRow(widget.model.id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: _invoiceFieldHeight,
            height: _invoiceFieldHeight,
            decoration: BoxDecoration(
              color: GoldStockColors.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(_invoiceFieldRadius),
              border: Border.all(
                color: GoldStockColors.danger.withValues(alpha: 0.32),
              ),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: GoldStockColors.danger,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoldTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final bool isNumber;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;

  const _GoldTextField({
    required this.controller,
    required this.hint,
    this.focusNode,
    this.isNumber = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildField(bool hasFocus) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        height: _invoiceFieldHeight,
        decoration: BoxDecoration(
          color: GoldStockColors.inputBg,
          borderRadius: BorderRadius.circular(_invoiceFieldRadius),
          border: Border.all(
            color: hasFocus
                ? GoldStockColors.brandGold
                : GoldStockColors.cardBorder,
            width: hasFocus ? 2.0 : 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters ??
              (isNumber
                  ? [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'),
                      ),
                    ]
                  : null),
          textInputAction: textInputAction,
          textAlign: textAlign,
          textAlignVertical: TextAlignVertical.center,
          maxLines: 1,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: GoldStockColors.textDark,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            isDense: true,
            isCollapsed: true,
            hintText: hint,
            hintStyle: TextStyle(
              color: GoldStockColors.textMuted.withValues(alpha: 0.50),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
          ),
        ),
      );
    }

    if (focusNode == null) {
      return buildField(false);
    }

    return ListenableBuilder(
      listenable: focusNode!,
      builder: (context, _) => buildField(focusNode!.hasFocus),
    );
  }
}

class _GoldPopupField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final List<String> popupItems;
  final ValueChanged<String> onSelected;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _GoldPopupField({
    required this.controller,
    required this.hint,
    required this.popupItems,
    required this.onSelected,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildField(bool hasFocus) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        height: _invoiceFieldHeight,
        decoration: BoxDecoration(
          color: GoldStockColors.inputBg,
          borderRadius: BorderRadius.circular(_invoiceFieldRadius),
          border: Border.all(
            color: hasFocus
                ? GoldStockColors.brandGold
                : GoldStockColors.cardBorder,
            width: hasFocus ? 2.0 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: textInputAction,
                onFieldSubmitted: onSubmitted,
                textAlign: TextAlign.left,
                textAlignVertical: TextAlignVertical.center,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: GoldStockColors.textDark,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  isDense: true,
                  isCollapsed: true,
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: GoldStockColors.textMuted.withValues(alpha: 0.50),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 36,
              height: _invoiceFieldHeight,
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: GoldStockColors.brandGold,
                  size: 20,
                ),
                color: GoldStockColors.cardBg,
                position: PopupMenuPosition.under,
                padding: EdgeInsets.zero,
                splashRadius: 18,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_invoiceFieldRadius),
                  side: const BorderSide(color: GoldStockColors.cardBorder),
                ),
                onSelected: onSelected,
                itemBuilder: (context) => popupItems
                    .map(
                      (choice) => PopupMenuItem<String>(
                        value: choice,
                        height: _invoiceFieldHeight,
                        child: Text(
                          choice,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: GoldStockColors.textDark,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      );
    }

    if (focusNode == null) {
      return buildField(false);
    }

    return ListenableBuilder(
      listenable: focusNode!,
      builder: (context, _) => buildField(focusNode!.hasFocus),
    );
  }
}
