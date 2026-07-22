import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lotus_erp/features/stock/silver/application/silver_stock_controller.dart';
import 'package:lotus_erp/features/stock/silver/domain/models/silver_item_model.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_colors.dart';

part 'silver_item_row_widgets.dart';

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
      widget.model.companyFocus.requestFocus();
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
                  Expanded(flex: 4, child: _buildCompanyField()),
                  const SizedBox(width: 4),
                  Expanded(flex: 4, child: _buildCategoryField()),
                  const SizedBox(width: 4),
                  Expanded(flex: 3, child: _buildSegmentField()),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 5,
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
                  Expanded(flex: 4, child: _buildQuantityFields()),
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
                    flex: 4,
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
                  Expanded(flex: 2, child: _buildRowActions()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuantityFields() {
    final isPacket = widget.model.quantityMode == SilverQuantityMode.packet;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _QuantityModeButton(model: widget.model),
            const SizedBox(width: 4),
            Expanded(
              child: _SilverTextField(
                controller: widget.model.piecesCtrl,
                focusNode: widget.model.piecesFocus,
                hint: widget.model.quantityInputHint,
                isNumber: true,
                allowDecimal: false,
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onSubmitted: (_) => isPacket
                    ? widget.model.piecesPerPacketFocus.requestFocus()
                    : widget.model.huidFocusNodes.first.requestFocus(),
              ),
            ),
          ],
        ),
        if (isPacket) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _SilverTextField(
                  controller: widget.model.piecesPerPacketCtrl,
                  focusNode: widget.model.piecesPerPacketFocus,
                  hint: 'PCS / PACK',
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
              Tooltip(
                message: 'Total pieces = packets x pieces per packet.',
                waitDuration: const Duration(milliseconds: 400),
                child: _QuantityTotalBadge(value: '${widget.model.pieces}'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHuidFields() {
    final controllers = widget.model.huidControllers;
    final focusNodes = widget.model.huidFocusNodes;
    final enabled = widget.model.huidTrackingEnabled;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HuidTrackingSwitch(model: widget.model),
        const SizedBox(width: 4),
        Expanded(
          child: enabled
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < controllers.length; index++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: index == controllers.length - 1 ? 0 : 6,
                        ),
                        child: _SilverTextField(
                          controller: controllers[index],
                          focusNode: focusNodes[index],
                          hint: controllers.length == 1
                              ? 'HUID'
                              : 'HUID ${index + 1}',
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]'),
                            ),
                            LengthLimitingTextInputFormatter(6),
                          ],
                          onSubmitted: (_) => index == controllers.length - 1
                              ? widget.model.grossFocus.requestFocus()
                              : focusNodes[index + 1].requestFocus(),
                        ),
                      ),
                  ],
                )
              : _buildBulkHuidState(),
        ),
      ],
    );
  }

  Widget _buildBulkHuidState() {
    return Container(
      height: _invoiceFieldHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: SilverStockColors.inputBg,
        borderRadius: BorderRadius.circular(_invoiceFieldRadius),
        border: Border.all(
          color: SilverStockColors.cardBorder,
          width: 1.5,
        ),
      ),
      child: const Text(
        'Bulk stock',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: SilverStockColors.textMuted,
        ),
      ),
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

  Widget _buildCompanyField() {
    return _SilverPopupField(
      controller: widget.model.companyCtrl,
      focusNode: widget.model.companyFocus,
      hint: 'Company',
      popupItems: SilverItemModel.companyPresets,
      onSelected: (value) {
        if (value == 'Custom') {
          if (SilverItemModel.companyPresets.contains(
            widget.model.companyCtrl.text.trim(),
          )) {
            widget.model.companyCtrl.clear();
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.model.companyFocus.requestFocus();
            }
          });
          return;
        }

        _setText(widget.model.companyCtrl, value);
        widget.model.categoryFocus.requestFocus();
      },
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => widget.model.categoryFocus.requestFocus(),
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
            fontSize: isBold ? 17 : 16,
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
