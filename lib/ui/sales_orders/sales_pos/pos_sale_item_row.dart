// ==========================================
// FILE: pos_sale_item_row.dart
// TYPE: Smart UI Component (UPGRADED)
// AUTHOR: Senior System Architect
// DESCRIPTION: Low-latency row component for the main cart table.
//               Strictly mapped Colors, Icons, and TextStyles.
// ==========================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/sales_orders/sales_pos_models/sales_pos_models.dart';
import '../../../logic/sales_orders/sales_pos/pos_billing_controller.dart';
import 'pos_stock_lookup_field.dart'; //  Stock lookup field is used by this row.
import 'shared_pos_components.dart';
// Note: Make sure PosStockLookupModel is exported in sales_pos_models.dart
// ya usko explicitly import kar lena agar zaroorat ho.

class _PurityData {
  static List<String> forMetal(MetalType metal) {
    switch (metal) {
      case MetalType.gold:
        return ['24KT', '22KT', '18KT', '14KT', '9KT'];
      case MetalType.silver:
        return ['999', '925', '800'];
      case MetalType.platinum:
        return ['950PT', '900PT', '850PT'];
      case MetalType.diamond:
        return ['VVS1', 'VVS2', 'VS1', 'VS2', 'SI1', 'SI2'];
    }
  }

  static String defaultFor(MetalType metal) => forMetal(metal).first;
}

class PosSaleItemRow extends StatefulWidget {
  final int index;
  final SaleItemModel item;
  final PosBillingController ctrl;

  const PosSaleItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.ctrl,
  });

  @override
  State<PosSaleItemRow> createState() => _PosSaleItemRowState();
}

class _PosSaleItemRowState extends State<PosSaleItemRow> {
  late String _selectedPurity;
  late MetalType _lastMetal;
  late BillingMode _lastBillingMode;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _lastMetal = widget.item.metal;
    _lastBillingMode = widget.ctrl.billingMode;
    final existing = widget.item.purityCtrl.text.trim();
    final options = _PurityData.forMetal(_lastMetal);
    _selectedPurity = options.contains(existing)
        ? existing
        : _PurityData.defaultFor(_lastMetal);

    if (widget.ctrl.billingMode == BillingMode.retail && existing.isEmpty) {
      widget.item.purityCtrl.text = _selectedPurity;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(widget.ctrl.applySaleItemMasterRate(widget.item));
    });
    widget.ctrl.addListener(_onCtrlChanged);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onCtrlChanged);
    super.dispose();
  }

  void _onCtrlChanged() {
    if (!mounted) return;
    final newMode = widget.ctrl.billingMode;
    if (_lastBillingMode != newMode) {
      _lastBillingMode = newMode;
      _syncModeState(newMode);
    }
  }

  void _syncModeState(BillingMode mode) {
    final isWholesale = mode == BillingMode.wholesale;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (isWholesale &&
          widget.item.makingChargeType == MakingChargeType.percentage) {
        widget.item.toggleMakingChargeType(isWholesale: true);
      }
      if (!isWholesale &&
          widget.item.makingChargeType == MakingChargeType.perKg) {
        widget.item.toggleMakingChargeType(isWholesale: false);
      }
      if (!isWholesale && widget.item.isLessPerPiece) {
        widget.item.toggleLessWeightType();
      }
    });
  }

  void _onMetalChanged(MetalType newMetal) {
    widget.item.updateMetal(newMetal);
    if (widget.ctrl.billingMode == BillingMode.retail) {
      setState(() {
        _lastMetal = newMetal;
        _selectedPurity = _PurityData.defaultFor(newMetal);
        widget.item.purityCtrl.text = _selectedPurity;
      });
    } else {
      setState(() => _lastMetal = newMetal);
    }
    unawaited(widget.ctrl.applySaleItemMasterRate(widget.item, force: true));
  }

  void _onPurityChanged(String value) {
    if (_selectedPurity != value) {
      setState(() => _selectedPurity = value);
    }
    unawaited(widget.ctrl.applySaleItemMasterRate(widget.item));
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
    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus) widget.ctrl.activeRowIndex = widget.index;
      },
      child: ListenableBuilder(
        listenable: widget.item,
        builder: (context, _) {
          if (widget.item.metal != _lastMetal) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _onMetalChanged(widget.item.metal);
            });
          }

          final metalColor = _metalColor(widget.item.metal);
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

                  //  Description with autocomplete suggestions
                  Expanded(
                    flex: 4,
                    child: _DescriptionWithSuggestions(
                      item: widget.item,
                      ctrl: widget.ctrl,
                      rowIndex: widget.index,
                      onSubmitted: (_) => widget.item.pcsFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(flex: 1, child: _buildPcsField(isWholesale)),
                  const SizedBox(width: 6),

                  if (!isWholesale) ...[
                    // HUID suggestions are handled by a dedicated widget.
                    Expanded(
                      flex: 2,
                      child: _HuidWithSuggestions(
                        item: widget.item,
                        ctrl: widget.ctrl,
                        rowIndex: widget.index,
                        onSubmitted: (_) async {
                          await widget.ctrl.tryAutofillByHuid(widget.index);
                          widget.item.purityFocus.requestFocus();
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(flex: 2, child: _buildPurityDropdown(metalColor)),
                    const SizedBox(width: 6),
                  ],

                  Expanded(
                    flex: 2,
                    child: PosAtomicTextField(
                      controller: widget.item.grossCtrl,
                      hint: "0.000",
                      isNumber: true,
                      focusNode: widget.item.grossFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => widget.item.lessFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 6),

                  Expanded(
                    flex: 2,
                    child: isWholesale
                        ? _buildLessField()
                        : PosAtomicTextField(
                            controller: widget.item.lessCtrl,
                            hint: "0.000",
                            isNumber: true,
                            focusNode: widget.item.lessFocus,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) =>
                                widget.item.rateFocus.requestFocus(),
                          ),
                  ),
                  const SizedBox(width: 6),

                  Expanded(
                    flex: 2,
                    child: _buildAutoCell(
                      value: widget.item.netWt.toStringAsFixed(3),
                      color: metalColor,
                      align: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 6),

                  if (isWholesale) ...[
                    Expanded(
                      flex: 2,
                      child: _buildTunchField(metalColor),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: _buildAutoCell(
                        value: widget.item.fineWt.toStringAsFixed(3),
                        color: metalColor,
                        align: TextAlign.center,
                        isBold: true,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: _buildMakingField(isWholesale),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: _buildAutoCell(
                        value:
                            "Rs ${widget.item.wholesaleLabourAmt.toStringAsFixed(2)}",
                        color: SalesPosColors.bodyTextMain,
                        align: TextAlign.right,
                        isBold: true,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ] else ...[
                    Expanded(
                      flex: 3,
                      child: PosAtomicTextField(
                        controller: widget.item.rateCtrl,
                        hint: "Rate",
                        isNumber: true,
                        focusNode: widget.item.rateFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) =>
                            widget.item.makingFocus.requestFocus(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(flex: 3, child: _buildMakingField(isWholesale)),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: _buildAutoCell(
                        value:
                            "Rs ${widget.item.totalValue.toStringAsFixed(2)}",
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
      ),
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
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: metalColor,
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
          value: widget.item.metal,
          isExpanded: true,
          icon: Icon(SalesPosIcons.dropdownArrow, color: metalColor, size: 22),
          style: SalesPosStyles.inputText
              .copyWith(color: metalColor, fontSize: 14),
          dropdownColor: SalesPosColors.bodyPanelBg,
          items: MetalType.values
              .map((type) => DropdownMenuItem<MetalType>(
                  value: type, child: Text(type.displayName)))
              .toList(),
          onChanged: (val) {
            if (val != null) _onMetalChanged(val);
          },
        ),
      ),
    );
  }

  Widget _buildPcsField(bool isWholesale) {
    return SizedBox(
      height: 38,
      child: TextFormField(
        controller: widget.item.pcsCtrl,
        focusNode: widget.item.pcsFocus,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => isWholesale
            ? widget.item.grossFocus.requestFocus()
            : widget.item.huidFocus.requestFocus(),
        textAlign: TextAlign.center,
        style: SalesPosStyles.inputText.copyWith(
          color: SalesPosColors.bodyTextMain,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          hintText: '1',
          hintStyle: SalesPosStyles.subTitleMuted.copyWith(
              color: SalesPosColors.bodyTextMain.withValues(alpha: 0.40)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          filled: true,
          fillColor: SalesPosColors.bodyBg,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: SalesPosColors.bodyBorder, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: SalesPosColors.brandGold, width: 2.0),
          ),
        ),
      ),
    );
  }

  Widget _buildLessField() {
    return Row(
      children: [
        Expanded(
          child: PosAtomicTextField(
            controller: widget.item.lessCtrl,
            hint: "0.000",
            isNumber: true,
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: "Toggle: Total Less (Tot) / Less Per Piece (/pc)",
          waitDuration: const Duration(milliseconds: 400),
          child: InkWell(
            onTap: widget.item.toggleLessWeightType,
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 36,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SalesPosColors.brandGold.withValues(alpha: 0.12),
                border: Border.all(
                    color: SalesPosColors.brandGold.withValues(alpha: 0.40)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.item.isLessPerPiece ? "/pc" : "Tot",
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: SalesPosColors.brandGold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTunchField(Color metalColor) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: metalColor.withValues(alpha: 0.35)),
      ),
      child: TextFormField(
        controller: widget.item.purityCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: SalesPosStyles.inputText.copyWith(
          color: metalColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          hintText: "Tunch",
          hintStyle: TextStyle(
              color: metalColor.withValues(alpha: 0.50),
              fontSize: 13,
              fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildPurityDropdown(Color metalColor) {
    final purities = _PurityData.forMetal(widget.item.metal);

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: metalColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: widget.item.purityCtrl,
              focusNode: widget.item.purityFocus,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => widget.item.grossFocus.requestFocus(),
              textAlign: TextAlign.center,
              style: SalesPosStyles.inputText.copyWith(
                color: metalColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.only(left: 8, bottom: 2),
              ),
              onChanged: _onPurityChanged,
            ),
          ),
          PopupMenuButton<String>(
            icon:
                Icon(SalesPosIcons.dropdownArrow, color: metalColor, size: 20),
            color: SalesPosColors.bodyPanelBg,
            position: PopupMenuPosition.under,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: SalesPosColors.bodyBorder),
            ),
            onSelected: (String val) {
              setState(() {
                _selectedPurity = val;
                widget.item.purityCtrl.text = val;
                widget.item.purityCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: val.length));
              });
              unawaited(
                widget.ctrl.applySaleItemMasterRate(
                  widget.item,
                  force: true,
                ),
              );
            },
            itemBuilder: (context) => purities
                .map((choice) => PopupMenuItem<String>(
                      value: choice,
                      height: 38,
                      child: Center(
                        child: Text(choice,
                            style: TextStyle(
                                color: metalColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 14)),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoCell(
      {required String value,
      required Color color,
      required TextAlign align,
      bool isBold = false}) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment:
          align == TextAlign.center ? Alignment.center : Alignment.centerRight,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment:
            align == TextAlign.center ? Alignment.center : Alignment.centerRight,
        child: Text(
          value,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          textAlign: align,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: isBold ? 16 : 15,
              fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ),
    );
  }

  Widget _buildMakingField(bool isWholesale) {
    String weightSymbol = widget.item.metal == MetalType.diamond ? "/ct" : "/g";
    String symbol = "";
    String hintText = "";

    if (widget.item.makingChargeType == MakingChargeType.percentage) {
      symbol = "%";
      hintText = "Rate %";
    } else if (widget.item.makingChargeType == MakingChargeType.perPiece) {
      symbol = "/pc";
      hintText = "Rate/pc";
    } else if (widget.item.makingChargeType == MakingChargeType.perKg) {
      symbol = "/kg";
      hintText = "Rate/kg";
    } else {
      symbol = weightSymbol;
      hintText = "Rate$weightSymbol";
    }

    return Row(
      children: [
        Expanded(
          child: PosAtomicTextField(
            controller: widget.item.makingCtrl,
            hint: hintText,
            isNumber: true,
            focusNode: widget.item.makingFocus,
            onSubmitted: (_) => widget.ctrl.addNewSaleItem(),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: isWholesale
              ? "Toggle: per gram > per kg > per piece"
              : "Toggle: rate > per piece > percentage",
          waitDuration: const Duration(milliseconds: 400),
          child: InkWell(
            onTap: () =>
                widget.item.toggleMakingChargeType(isWholesale: isWholesale),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SalesPosColors.brandGold.withValues(alpha: 0.12),
                border: Border.all(
                    color: SalesPosColors.brandGold.withValues(alpha: 0.40)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                symbol,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: SalesPosColors.brandGold),
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
        message: "Remove item",
        waitDuration: const Duration(milliseconds: 400),
        child: InkWell(
          onTap: () => widget.ctrl.removeSaleItem(widget.index),
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

// ==========================================
//  CLEAN WIDGETS USING PosStockLookupField
// ==========================================

class _DescriptionWithSuggestions extends StatelessWidget {
  final SaleItemModel item;
  final PosBillingController ctrl;
  final int rowIndex;
  final Function(String)? onSubmitted;

  const _DescriptionWithSuggestions({
    required this.item,
    required this.ctrl,
    required this.rowIndex,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return PosStockLookupField(
      listenable: ctrl,
      controller: item.descCtrl,
      hint: "Description",
      focusNode: item.firstFieldFocus,
      textInputAction: TextInputAction.next,
      onSubmitted: onSubmitted,
      onSearch: (query) async {
        // Passed item.metal as the missing 3rd argument.
        // Update this argument if the controller signature changes.
        await ctrl.searchDescriptions(query, rowIndex, item.metal);
      },
      // Automatically handles the PosStockLookupModel type!
      getSuggestions: () => ctrl.getDescSuggestionsForRow(rowIndex),
      onSelected: (selection) {
        ctrl.applyStockSuggestionToRow(
          rowIndex: rowIndex,
          suggestion: selection,
        );
      },
      onClearSuggestions: () {
        ctrl.clearDescriptionSuggestions();
      },
    );
  }
}

class _HuidWithSuggestions extends StatelessWidget {
  final SaleItemModel item;
  final PosBillingController ctrl;
  final int rowIndex;
  final Function(String)? onSubmitted;

  const _HuidWithSuggestions({
    required this.item,
    required this.ctrl,
    required this.rowIndex,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return PosStockLookupField(
      listenable: ctrl,
      controller: item.huidCtrl, // Ensure item.huidCtrl exists in your model
      hint: "HUID",
      focusNode: item.huidFocus,
      textInputAction: TextInputAction.next,
      onSubmitted: onSubmitted,
      onSearch: (query) async {
        await ctrl.searchHuids(query, rowIndex, item.metal);
      },
      getSuggestions: () => ctrl.getHuidSuggestionsForRow(rowIndex),
      onSelected: (selection) async {
        ctrl.applyStockSuggestionToRow(
          rowIndex: rowIndex,
          suggestion: selection,
        );
      },
      onClearSuggestions: () {
        ctrl.clearHuidSuggestions();
      },
      overlayWidth: 260,
    );
  }
}
