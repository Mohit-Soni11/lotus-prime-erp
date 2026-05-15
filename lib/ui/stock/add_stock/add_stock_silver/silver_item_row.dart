import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_colors.dart';

import '../../../../models/stock/stock_item_model/add_stock_silver/silver_item_model.dart';

class SilverItemRow extends StatefulWidget {
  final int index;
  final SilverItemModel model;
  final SilverStockController ctrl;

  const SilverItemRow({
    super.key,
    required this.index,
    required this.model,
    required this.ctrl,
  });

  @override
  State<SilverItemRow> createState() => _SilverItemRowState();
}

class _SilverItemRowState extends State<SilverItemRow> {
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _handlePendingFocus();
  }

  @override
  void didUpdateWidget(covariant SilverItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handlePendingFocus();
  }

  void _handlePendingFocus() {
    if (!widget.ctrl.shouldRequestSilverFocus(widget.model.id)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.model.categoryFocus.requestFocus();
      widget.ctrl.clearSilverFocusRequest(widget.model.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEven = widget.index.isEven;

    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          widget.ctrl.setSilverActiveRow(widget.model.id);
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
                    ? SilverStockColors.cardHoverBg
                    : (isEven
                        ? SilverStockColors.bodyBg
                        : SilverStockColors.cardBg),
                border: const Border(
                  bottom: BorderSide(
                    color: SilverStockColors.cardBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 1, child: _buildSNo()),
                  const SizedBox(width: 6),
                  Expanded(flex: 3, child: _buildCategoryField()),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 4,
                    child: _SilverTextField(
                      controller: widget.model.itemNameCtrl,
                      focusNode: widget.model.itemNameFocus,
                      hint: 'Item name',
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => widget.model.huidFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: _SilverTextField(
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
                    child: _SilverTextField(
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
                    child: _SilverTextField(
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
                      color: SilverStockColors.brandSilver,
                      align: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(flex: 2, child: _buildPurityField()),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: _SilverTextField(
                      controller: widget.model.wastageCtrl,
                      focusNode: widget.model.wastageFocus,
                      hint: '%',
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
                      value: widget.model.fineWeight.toStringAsFixed(3),
                      color: SilverStockColors.success,
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
                          'Fine ${widget.model.fineWeight.toStringAsFixed(3)} g x Rs ${widget.model.purchaseRate.toStringAsFixed(2)}/g',
                      waitDuration: const Duration(milliseconds: 400),
                      child: _buildAutoCell(
                        value:
                            'Rs ${widget.model.totalAmount.toStringAsFixed(2)}',
                        color: SilverStockColors.textDark,
                        align: TextAlign.right,
                        isBold: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(flex: 1, child: _buildDeleteBtn()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryField() {
    return _SilverPopupField(
      controller: widget.model.categoryCtrl,
      focusNode: widget.model.categoryFocus,
      hint: 'Category',
      popupItems: SilverItemModel.categoryPresets,
      onSelected: (value) {
        if (value == 'Other') {
          if (SilverItemModel.categoryPresets.contains(
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

  Widget _buildPurityField() {
    return _SilverPopupField(
      controller: widget.model.purityCtrl,
      focusNode: widget.model.purityFocus,
      hint: 'Purity',
      popupItems: SilverItemModel.purityPresets,
      textAlign: TextAlign.center,
      onSelected: (value) {
        if (value == 'Other') {
          widget.model.purityCtrl.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.model.purityFocus.requestFocus();
            }
          });
          return;
        }

        _setText(widget.model.purityCtrl, value);
        widget.model.wastageFocus.requestFocus();
      },
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => widget.model.wastageFocus.requestFocus(),
    );
  }

  void _setText(TextEditingController controller, String value) {
    controller.text = value;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: value.length),
    );
  }

  Widget _buildSNo() {
    return Center(
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SilverStockColors.brandSilver.withOpacity(0.12),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: SilverStockColors.brandSilver.withOpacity(0.35),
          ),
        ),
        child: Text(
          '${widget.index + 1}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: SilverStockColors.brandSilver,
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
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment:
          align == TextAlign.center ? Alignment.center : Alignment.centerRight,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        value,
        textAlign: align,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: isBold ? 16 : 15,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildMakingField() {
    return Row(
      children: [
        Expanded(
          child: _SilverTextField(
            controller: widget.model.makingCtrl,
            focusNode: widget.model.makingFocus,
            hint: widget.model.makingHint,
            isNumber: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) =>
                widget.ctrl.completeRowAndAdvanceSilver(widget.model.id),
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
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SilverStockColors.brandSilver.withOpacity(0.12),
                border: Border.all(
                  color: SilverStockColors.brandSilver.withOpacity(0.40),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.model.makingTypeSymbol,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: SilverStockColors.brandSilver,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteBtn() {
    return Center(
      child: Tooltip(
        message: 'Remove item',
        waitDuration: const Duration(milliseconds: 400),
        child: InkWell(
          onTap: () => widget.ctrl.removeRow(widget.model.id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: SilverStockColors.danger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: SilverStockColors.danger.withOpacity(0.35),
              ),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: SilverStockColors.danger,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _SilverTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final bool isNumber;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;

  const _SilverTextField({
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
    return SizedBox(
      height: 38,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters ??
            (isNumber
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                : null),
        textInputAction: textInputAction,
        textAlign: textAlign,
        onFieldSubmitted: onSubmitted,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: SilverStockColors.textDark,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: SilverStockColors.textMuted.withOpacity(0.50),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          filled: true,
          fillColor: SilverStockColors.inputBg,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: SilverStockColors.cardBorder,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: SilverStockColors.brandSilver,
              width: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _SilverPopupField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final List<String> popupItems;
  final ValueChanged<String> onSelected;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextAlign textAlign;

  const _SilverPopupField({
    required this.controller,
    required this.hint,
    required this.popupItems,
    required this.onSelected,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: SilverStockColors.inputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SilverStockColors.cardBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: textInputAction,
              onFieldSubmitted: onSubmitted,
              textAlign: textAlign,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: SilverStockColors.textDark,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: SilverStockColors.textMuted.withOpacity(0.50),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: SilverStockColors.brandSilver,
              size: 20,
            ),
            color: SilverStockColors.cardBg,
            position: PopupMenuPosition.under,
            padding: EdgeInsets.zero,
            splashRadius: 18,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: SilverStockColors.cardBorder),
            ),
            onSelected: onSelected,
            itemBuilder: (context) => popupItems
                .map(
                  (choice) => PopupMenuItem<String>(
                    value: choice,
                    height: 38,
                    child: Text(
                      choice,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SilverStockColors.textDark,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
