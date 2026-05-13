// ==========================================
// FILE: silver_item_row.dart
// TYPE: Smart UI Component (SILVER — POS-STYLE)
// DESCRIPTION: Zero-lag row for Silver Invoice Items Table.
//              ✅ Exact same design language as PosSaleItemRow.
//              ✅ Silver branding — SilverStockColors throughout.
//              ✅ Columns: S.NO | ITEM NAME | HUID | GROSS | LESS | NET WT | RATE | MAKING | TOTAL | ACT
//              ✅ Hover animation, even/odd rows, focus tracking.
//              ✅ Making charge toggle: /g ➔ Flat ➔ % (same pattern as POS).
//              ✅ NET WT + TOTAL auto-calculated from model.
// ==========================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import 'package:lotus_erp/logic/stock/add_stock_controller.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/models/stock/stock_item_model/stock_enums.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_theme.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_colors.dart';

class SilverItemRow extends StatefulWidget {
  final int index;
  final StockRowEntry row;
  final SilverStockController ctrl;

  const SilverItemRow({
    super.key,
    required this.index,
    required this.row,
    required this.ctrl,
  });

  @override
  State<SilverItemRow> createState() => _SilverItemRowState();
}

class _SilverItemRowState extends State<SilverItemRow> {
  // ── TEXT CONTROLLERS ─────────────────────────────────────────
  late final TextEditingController _itemCtrl;
  late final TextEditingController _huidCtrl;
  late final TextEditingController _grossCtrl;
  late final TextEditingController _lessCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _makingCtrl;

  // ── FOCUS NODES ──────────────────────────────────────────────
  late final FocusNode _itemFocus;
  late final FocusNode _huidFocus;
  late final FocusNode _grossFocus;
  late final FocusNode _lessFocus;
  late final FocusNode _rateFocus;
  late final FocusNode _makingFocus;

  bool _isHovered = false;

  // ─────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _itemCtrl = TextEditingController();
    _huidCtrl = TextEditingController();
    _grossCtrl = TextEditingController();
    _lessCtrl = TextEditingController();
    _rateCtrl = TextEditingController();
    _makingCtrl = TextEditingController();

    _itemFocus = FocusNode();
    _huidFocus = FocusNode();
    _grossFocus = FocusNode();
    _lessFocus = FocusNode();
    _rateFocus = FocusNode();
    _makingFocus = FocusNode();

    _syncControllers();
    _handlePendingFocus();
  }

  @override
  void didUpdateWidget(covariant SilverItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
    _handlePendingFocus();
  }

  @override
  void dispose() {
    _itemCtrl.dispose();
    _huidCtrl.dispose();
    _grossCtrl.dispose();
    _lessCtrl.dispose();
    _rateCtrl.dispose();
    _makingCtrl.dispose();

    _itemFocus.dispose();
    _huidFocus.dispose();
    _grossFocus.dispose();
    _lessFocus.dispose();
    _rateFocus.dispose();
    _makingFocus.dispose();

    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // SYNC & FOCUS
  // ─────────────────────────────────────────────────────────────

  void _handlePendingFocus() {
    if (!widget.ctrl.shouldRequestFocus(widget.row.id)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _itemFocus.requestFocus();
      widget.ctrl.clearFocusRequest(widget.row.id);
    });
  }

  void _syncControllers() {
    final row = widget.row;
    _setIfNeeded(_itemCtrl, row.itemName);
    _setIfNeeded(_huidCtrl, row.huid);
    _setIfNeeded(_grossCtrl, _dec(row.grossWeight));
    _setIfNeeded(_lessCtrl, _dec(row.stoneWeight));
    _setIfNeeded(_rateCtrl, _dec(row.purchaseRate));
    _setIfNeeded(_makingCtrl, _dec(row.makingCharges));
  }

  void _setIfNeeded(TextEditingController c, String val) {
    if (c.text != val) c.text = val;
  }

  String _dec(double v) {
    if (v == 0) return '';
    return v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v
            .toStringAsFixed(3)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final ctrl = widget.ctrl;
    final isEven = widget.index % 2 == 0;

    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus) ctrl.setActiveRow(row.id);
      },
      child: ListenableBuilder(
        listenable: ctrl,
        builder: (context, _) {
          return MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                // Same even/odd + hover pattern as POS
                color: _isHovered
                    ? SilverStockColors.cardHoverBg
                    : (isEven
                        ? SilverStockColors.bodyBg
                        : SilverStockColors.cardBg),
                border: const Border(
                    bottom: BorderSide(
                        color: SilverStockColors.cardBorder, width: 1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── S.NO ────────────────────────────────────────
                  Expanded(flex: 1, child: _buildSNo()),
                  const SizedBox(width: 6),

                  // ── ITEM NAME ──────────────────────────────────
                  Expanded(
                    flex: 4,
                    child: _SilverAtomicTextField(
                      controller: _itemCtrl,
                      hint: 'Item name',
                      focusNode: _itemFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _huidFocus.requestFocus(),
                      onChanged: (v) => ctrl.updateItemName(row.id, v),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── HUID ──────────────────────────────────────
                  Expanded(
                    flex: 2,
                    child: _SilverAtomicTextField(
                      controller: _huidCtrl,
                      hint: 'HUID',
                      focusNode: _huidFocus,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]')),
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onSubmitted: (_) => _grossFocus.requestFocus(),
                      onChanged: (v) => ctrl.updateHuid(row.id, v),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── GROSS WEIGHT ──────────────────────────────
                  Expanded(
                    flex: 2,
                    child: _SilverAtomicTextField(
                      controller: _grossCtrl,
                      hint: '0.000',
                      isNumber: true,
                      focusNode: _grossFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _lessFocus.requestFocus(),
                      onChanged: (v) => ctrl.updateGrossWeight(row.id, v),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── LESS (stone/deduction) ───────────────────
                  Expanded(
                    flex: 2,
                    child: _SilverAtomicTextField(
                      controller: _lessCtrl,
                      hint: '0.000',
                      isNumber: true,
                      focusNode: _lessFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _rateFocus.requestFocus(),
                      onChanged: (v) => ctrl.updateStoneWeight(row.id, v),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── NET WT (auto) ─────────────────────────────
                  Expanded(
                    flex: 2,
                    child: _buildAutoCell(
                      value: '${row.netWeight.toStringAsFixed(3)} g',
                      color: SilverStockColors.brandSilver,
                      align: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── RATE / g ──────────────────────────────────
                  Expanded(
                    flex: 3,
                    child: _SilverAtomicTextField(
                      controller: _rateCtrl,
                      hint: 'Rate',
                      isNumber: true,
                      focusNode: _rateFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _makingFocus.requestFocus(),
                      onChanged: (v) => ctrl.updatePurchaseRate(row.id, v),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── MAKING CHARGE ─────────────────────────────
                  Expanded(flex: 3, child: _buildMakingField(row, ctrl)),
                  const SizedBox(width: 6),

                  // ── ROW TOTAL (auto) ──────────────────────────
                  Expanded(
                    flex: 3,
                    child: _buildAutoCell(
                      value: '₹${ctrl.rowTotalAmount(row).toStringAsFixed(2)}',
                      color: SilverStockColors.textDark,
                      align: TextAlign.right,
                      isBold: true,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── ACT ───────────────────────────────────────
                  Expanded(flex: 1, child: _buildDeleteBtn(ctrl, row)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // S.NO CELL — same design as POS _buildSNo
  // ─────────────────────────────────────────────────────────────

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
              color: SilverStockColors.brandSilver.withOpacity(0.35)),
        ),
        child: Text(
          '${widget.index + 1}',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: SilverStockColors.brandSilver,
              fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // AUTO CELL — same design as POS _buildAutoCell
  // ─────────────────────────────────────────────────────────────

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
            fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MAKING FIELD — same toggle pattern as POS _buildMakingField
  // Silver: /g ➔ Flat ➔ % toggle
  // ─────────────────────────────────────────────────────────────

  Widget _buildMakingField(StockRowEntry row, SilverStockController ctrl) {
    String symbol;
    String hint;

    switch (row.makingChargesType) {
      case MakingChargesType.perGram:
        symbol = '/g';
        hint = 'Rate/g';
        break;
      case MakingChargesType.flat:
        symbol = 'Flat';
        hint = 'Flat Amt';
        break;
      case MakingChargesType.percent:
        symbol = '%';
        hint = 'Rate %';
        break;
    }

    return Row(
      children: [
        Expanded(
          child: _SilverAtomicTextField(
            controller: _makingCtrl,
            hint: hint,
            isNumber: true,
            focusNode: _makingFocus,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => ctrl.completeRowAndAdvance(row.id),
            onChanged: (v) => ctrl.updateMakingCharges(row.id, v),
          ),
        ),
        const SizedBox(width: 4),

        // Toggle button — same AnimatedContainer style as POS
        Tooltip(
          message: 'Toggle: /g ➔ Flat ➔ %',
          waitDuration: const Duration(milliseconds: 400),
          child: InkWell(
            onTap: () => _toggleMakingType(row, ctrl),
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
                    color: SilverStockColors.brandSilver.withOpacity(0.40)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                symbol,
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: SilverStockColors.brandSilver),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleMakingType(StockRowEntry row, SilverStockController ctrl) {
    final next = switch (row.makingChargesType) {
      MakingChargesType.perGram => MakingChargesType.flat,
      MakingChargesType.flat => MakingChargesType.percent,
      MakingChargesType.percent => MakingChargesType.perGram,
    };
    ctrl.updateMakingType(row.id, next);
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE BUTTON — same design as POS _buildDeleteBtn
  // ─────────────────────────────────────────────────────────────

  Widget _buildDeleteBtn(SilverStockController ctrl, StockRowEntry row) {
    final canDelete = ctrl.rows.length > 1;

    return Center(
      child: Tooltip(
        message: canDelete ? 'Remove item' : 'Cannot remove last item',
        waitDuration: const Duration(milliseconds: 400),
        child: InkWell(
          onTap: canDelete ? () => ctrl.removeRow(row.id) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: canDelete
                  ? SilverStockColors.danger.withOpacity(0.12)
                  : SilverStockColors.cardBorder.withOpacity(0.40),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: canDelete
                      ? SilverStockColors.danger.withOpacity(0.35)
                      : SilverStockColors.cardBorder),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: canDelete
                  ? SilverStockColors.danger
                  : SilverStockColors.textMuted,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _SilverAtomicTextField
// Exact same look as PosAtomicTextField — but silver-branded focus border.
// Self-contained, zero cross-module import needed.
// =============================================================================

class _SilverAtomicTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isNumber;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  const _SilverAtomicTextField({
    required this.controller,
    required this.hint,
    this.isNumber = false,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
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
                ? [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ]
                : null),
        textInputAction: textInputAction,
        textAlign: isNumber ? TextAlign.right : TextAlign.left,
        onFieldSubmitted: onSubmitted,
        onChanged: onChanged,
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
                color: SilverStockColors.cardBorder, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: SilverStockColors.brandSilver, width: 2.0),
          ),
        ),
      ),
    );
  }
}
