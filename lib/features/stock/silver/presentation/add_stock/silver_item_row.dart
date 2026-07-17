import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_stock_controller.dart';
import 'package:lotus_erp/features/stock/silver/domain/models/silver_item_model.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_colors.dart';

const double _invoiceFieldHeight = 40;
const double _invoiceFieldRadius = 8;

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
                  Expanded(flex: 2, child: _buildSNo()),
                  const SizedBox(width: 4),
                  Expanded(flex: 3, child: _buildCategoryField()),
                  const SizedBox(width: 4),
                  Expanded(flex: 3, child: _buildSegmentField()),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 4,
                    child: _SilverTextField(
                      controller: widget.model.itemNameCtrl,
                      focusNode: widget.model.itemNameFocus,
                      hint: 'Item name',
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) =>
                          widget.model.piecesFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: _SilverTextField(
                      controller: widget.model.piecesCtrl,
                      focusNode: widget.model.piecesFocus,
                      hint: 'PCS',
                      isNumber: true,
                      allowDecimal: false,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      onSubmitted: (_) =>
                          widget.model.huidFocusNodes.first.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(flex: 4, child: _buildHuidFields()),
                  const SizedBox(width: 4),
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
                  const SizedBox(width: 4),
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
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: _buildAutoCell(
                      value: widget.model.netWeight.toStringAsFixed(3),
                      color: SilverStockColors.brandSilver,
                      align: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: _SilverTextField(
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
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: _SilverTextField(
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
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: Tooltip(
                      message: widget.model.hasRoundedFineWeight
                          ? 'Rounded valuation fine uses effective purity ${widget.model.effectiveTotalPurityLabel}%.'
                          : 'Total purity = base purity ${widget.model.basePurityPercent.toStringAsFixed(2)}% + wastage ${widget.model.wastagePercent.toStringAsFixed(2)}%',
                      waitDuration: const Duration(milliseconds: 400),
                      child: _buildAutoCell(
                        value: widget.model.effectiveTotalPurityLabel == '--'
                            ? '--'
                            : '${widget.model.effectiveTotalPurityLabel}%',
                        color: widget.model.hasValidTotalPurity
                            ? SilverStockColors.brandSilver
                            : SilverStockColors.danger,
                        align: TextAlign.center,
                        isBold: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: _buildAutoCell(
                      value: widget.model.actualFineWeight.toStringAsFixed(3),
                      color: SilverStockColors.success,
                      align: TextAlign.center,
                      isBold: true,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: _buildAutoCell(
                      value:
                          widget.model.valuationFineWeight.toStringAsFixed(3),
                      color: SilverStockColors.brandSilver,
                      align: TextAlign.center,
                      isBold: true,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(flex: 3, child: _buildMakingField()),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 3,
                    child: Tooltip(
                      message:
                          'Valuation fine ${widget.model.valuationFineWeight.toStringAsFixed(3)} g at Rs ${widget.model.purchaseRate.toStringAsFixed(2)}/g plus making.',
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
                  const SizedBox(width: 4),
                  Expanded(flex: 1, child: _buildRowActions()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHuidFields() {
    final controllers = widget.model.huidControllers;
    final focusNodes = widget.model.huidFocusNodes;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < controllers.length; index++) ...[
          _SilverTextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            hint: controllers.length == 1 ? 'HUID' : 'HUID ${index + 1}',
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(6),
            ],
            onSubmitted: (_) => index == controllers.length - 1
                ? widget.model.grossFocus.requestFocus()
                : focusNodes[index + 1].requestFocus(),
          ),
          if (index != controllers.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildCategoryField() {
    return _SilverPopupField(
      controller: widget.model.categoryCtrl,
      focusNode: widget.model.categoryFocus,
      hint: 'Item type',
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
        widget.model.segmentFocus.requestFocus();
      },
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => widget.model.segmentFocus.requestFocus(),
    );
  }

  Widget _buildSegmentField() {
    return _SilverPopupField(
      controller: widget.model.segmentCtrl,
      focusNode: widget.model.segmentFocus,
      hint: 'Segment',
      popupItems: SilverItemModel.segmentPresets,
      onSelected: (value) {
        if (value == 'Custom') {
          if (SilverItemModel.segmentPresets.contains(
            widget.model.segmentCtrl.text.trim(),
          )) {
            widget.model.segmentCtrl.clear();
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.model.segmentFocus.requestFocus();
            }
          });
          return;
        }

        _setText(widget.model.segmentCtrl, value);
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

  Widget _buildSNo() {
    return Center(
      child: Container(
        width: 54,
        height: _invoiceFieldHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SilverStockColors.brandSilver.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(_invoiceFieldRadius),
          border: Border.all(
            color: SilverStockColors.brandSilver.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          (widget.index + 1).toString().padLeft(2, '0'),
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
              width: _invoiceFieldHeight,
              height: _invoiceFieldHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SilverStockColors.brandSilver.withValues(alpha: 0.12),
                border: Border.all(
                  color: SilverStockColors.brandSilver.withValues(alpha: 0.40),
                ),
                borderRadius: BorderRadius.circular(_invoiceFieldRadius),
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
              color: SilverStockColors.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(_invoiceFieldRadius),
              border: Border.all(
                color: SilverStockColors.danger.withValues(alpha: 0.32),
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
  final bool allowDecimal;
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
    this.allowDecimal = true,
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
          color: SilverStockColors.inputBg,
          borderRadius: BorderRadius.circular(_invoiceFieldRadius),
          border: Border.all(
            color: hasFocus
                ? SilverStockColors.brandSilver
                : SilverStockColors.cardBorder,
            width: hasFocus ? 2.0 : 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: isNumber
              ? TextInputType.numberWithOptions(decimal: allowDecimal)
              : TextInputType.text,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters ??
              (isNumber
                  ? (allowDecimal
                      ? [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ]
                      : [FilteringTextInputFormatter.digitsOnly])
                  : null),
          textInputAction: textInputAction,
          textAlign: textAlign,
          textAlignVertical: TextAlignVertical.center,
          maxLines: 1,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: SilverStockColors.textDark,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            isDense: true,
            isCollapsed: true,
            hintText: hint,
            hintStyle: const TextStyle(
              color: SilverStockColors.textHint,
              fontSize: 13,
              fontWeight: FontWeight.w700,
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

class _SilverPopupField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final List<String> popupItems;
  final ValueChanged<String> onSelected;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _SilverPopupField({
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
          color: SilverStockColors.inputBg,
          borderRadius: BorderRadius.circular(_invoiceFieldRadius),
          border: Border.all(
            color: hasFocus
                ? SilverStockColors.brandSilver
                : SilverStockColors.cardBorder,
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
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: SilverStockColors.textDark,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  isDense: true,
                  isCollapsed: true,
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: SilverStockColors.textHint,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
                  color: SilverStockColors.brandSilver,
                  size: 20,
                ),
                color: SilverStockColors.cardBg,
                position: PopupMenuPosition.under,
                padding: EdgeInsets.zero,
                splashRadius: 18,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_invoiceFieldRadius),
                  side: const BorderSide(color: SilverStockColors.cardBorder),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: SilverStockColors.textDark,
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
