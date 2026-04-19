// ==========================================
// FILE: pos_sale_item_row.dart
// TYPE: Smart UI Component (UPGRADED)
// AUTHOR: Senior System Architect
// DESCRIPTION: Zero-lag row component for the main cart table.
//              ✅ Strictly mapped Colors, Icons, and TextStyles.
// ==========================================

import 'package:flutter/material.dart';
import 'dart:ui';

import '../../../theme/sales/sales_pos_theme/sales_pos_theme.dart';
import '../../../models/sales & orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../models/sales & orders/sales_pos_models/sales_pos_models.dart';
import '../../../logic/sales & orders/sales pos/pos_billing_controller.dart';
import 'shared_pos_components.dart';

class _PurityData {
  static List<String> forMetal(MetalType metal) {
    switch (metal) {
      case MetalType.gold: return ['24KT', '22KT', '18KT', '14KT', '9KT'];
      case MetalType.silver: return ['999', '925', '800'];
      case MetalType.platinum: return ['950PT', '900PT', '850PT'];
      case MetalType.diamond: return ['VVS1', 'VVS2', 'VS1', 'VS2', 'SI1', 'SI2'];
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
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _lastMetal = widget.item.metal;
    final existing = widget.item.purityCtrl.text.trim();
    final options = _PurityData.forMetal(_lastMetal);
    _selectedPurity = options.contains(existing) ? existing : _PurityData.defaultFor(_lastMetal);
    
    if (widget.ctrl.billingMode == BillingMode.retail && existing.isEmpty) {
      widget.item.purityCtrl.text = _selectedPurity;
    }
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
  }

  void _onPurityChanged(String? newPurity) {
    if (newPurity == null) return;
    setState(() {
      _selectedPurity = newPurity;
      widget.item.purityCtrl.text = newPurity;
    });
  }

  Color _metalColor(MetalType metal) {
    switch (metal) {
      case MetalType.gold: return SalesPosColors.brandGold;
      case MetalType.silver: return SalesPosColors.brandSilver;
      case MetalType.platinum: return SalesPosColors.brandPlatinum;
      case MetalType.diamond: return SalesPosColors.brandDiamond;
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

          if (isWholesale && widget.item.makingChargeType == MakingChargeType.percentage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.item.toggleMakingChargeType(isWholesale: true);
            });
          }
          if (!isWholesale && widget.item.makingChargeType == MakingChargeType.perKg) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.item.toggleMakingChargeType(isWholesale: false);
            });
          }
          if (!isWholesale && widget.item.isLessPerPiece) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.item.toggleLessWeightType();
            });
          }

          return MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isHovered ? SalesPosColors.cardHoverBg : (isEven ? SalesPosColors.bodyPanelBg : SalesPosColors.bodyBg),
                border: const Border(bottom: BorderSide(color: SalesPosColors.bodyBorder, width: 1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 1, child: _buildSNo(widget.index + 1, metalColor)), const SizedBox(width: 6),
                  Expanded(flex: 3, child: _buildMetalDropdown(metalColor)), const SizedBox(width: 6),
                  
                  // 🚀 Description size strictly 4
                  Expanded(
                    flex: 4, 
                    child: PosAtomicTextField(
                      controller: widget.item.descCtrl,
                      hint: "Description",
                      focusNode: widget.item.firstFieldFocus,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(flex: 1, child: _buildPcsField()),
                  const SizedBox(width: 6),
                  
                  if (!isWholesale) ...[
                    Expanded(
                      flex: 2,
                      child: PosAtomicTextField(
                        controller: widget.item.huidCtrl,
                        hint: "HUID",
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
                        value: "₹${widget.item.wholesaleLabourAmt.toStringAsFixed(2)}", 
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
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(flex: 3, child: _buildMakingField(isWholesale)),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: _buildAutoCell(
                        value: "₹${widget.item.totalValue.toStringAsFixed(2)}",
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
        width: 32, height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: metalColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: metalColor.withOpacity(0.35)),
        ),
        child: Text(
          '$number',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: metalColor, fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ),
    );
  }

  Widget _buildMetalDropdown(Color metalColor) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: metalColor.withOpacity(0.10),
        border: Border.all(color: metalColor.withOpacity(0.40)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MetalType>(
          value: widget.item.metal,
          isExpanded: true,
          icon: Icon(SalesPosIcons.dropdownArrow, color: metalColor, size: 22),
          style: SalesPosStyles.inputText.copyWith(color: metalColor, fontSize: 14),
          dropdownColor: SalesPosColors.bodyPanelBg,
          items: MetalType.values.map((type) => DropdownMenuItem<MetalType>(value: type, child: Text(type.displayName))).toList(),
          onChanged: (val) { if (val != null) _onMetalChanged(val); },
        ),
      ),
    );
  }

  Widget _buildPcsField() {
    return SizedBox(
      height: 38,
      child: TextFormField(
        controller: widget.item.pcsCtrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: SalesPosStyles.inputText.copyWith(
          color: SalesPosColors.bodyTextMain,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          hintText: '1',
          hintStyle: SalesPosStyles.subTitleMuted.copyWith(color: SalesPosColors.bodyTextMain.withOpacity(0.40)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          filled: true,
          fillColor: SalesPosColors.bodyBg,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: SalesPosColors.bodyBorder, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: SalesPosColors.brandGold, width: 2.0),
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
              width: 36, height: 38, 
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SalesPosColors.brandGold.withOpacity(0.12),
                border: Border.all(color: SalesPosColors.brandGold.withOpacity(0.40)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.item.isLessPerPiece ? "/pc" : "Tot",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: SalesPosColors.brandGold),
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
        border: Border.all(color: metalColor.withOpacity(0.35)),
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
          hintStyle: TextStyle(color: metalColor.withOpacity(0.50), fontSize: 13, fontWeight: FontWeight.w800),
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
        border: Border.all(color: metalColor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: widget.item.purityCtrl,
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
            icon: Icon(SalesPosIcons.dropdownArrow, color: metalColor, size: 20),
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
                widget.item.purityCtrl.selection = TextSelection.fromPosition(TextPosition(offset: val.length));
              });
            },
            itemBuilder: (context) => purities.map((choice) => PopupMenuItem<String>(
              value: choice,
              height: 38,
              child: Center(
                child: Text(choice, style: TextStyle(color: metalColor, fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoCell({required String value, required Color color, required TextAlign align, bool isBold = false}) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: align == TextAlign.center ? Alignment.center : Alignment.centerRight,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        value,
        textAlign: align,
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: isBold ? 16 : 15, fontFeatures: const [FontFeature.tabularFigures()]),
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
            onSubmitted: (_) => widget.ctrl.addNewSaleItem(),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: isWholesale ? "Toggle: /g ➔ /kg ➔ /pc" : "Toggle: Rate ➔ /pc ➔ %",
          waitDuration: const Duration(milliseconds: 400),
          child: InkWell(
            onTap: () => widget.item.toggleMakingChargeType(isWholesale: isWholesale),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 38, height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SalesPosColors.brandGold.withOpacity(0.12),
                border: Border.all(color: SalesPosColors.brandGold.withOpacity(0.40)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                symbol,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: SalesPosColors.brandGold),
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
          onTap: () => widget.ctrl.removeActiveItem(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: SalesPosColors.danger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SalesPosColors.danger.withOpacity(0.35)),
            ),
            child: const Icon(SalesPosIcons.deleteItem, color: SalesPosColors.danger, size: 20),
          ),
        ),
      ),
    );
  }
}