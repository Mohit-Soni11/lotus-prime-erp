// =============================================================================
// FILE        : silver_item_row.dart
// MODULE      : Stock & Inventory — Silver
// LAYER       : UI / Table Row
// DESCRIPTION : Single row widget for the Silver Fast-Entry Table.
//               ✅ Silver-specific columns: RATE/g, QTY, STONE VAL — no touch%, no fine gold.
//               ✅ F2 to add row, Delete to remove active row (keyboard shortcuts).
//               ✅ Focus tracking for keyboard navigation (Enter → next row).
//               ✅ Hover highlight + error highlight + even/odd alternating rows.
//               ✅ Duplicate + Delete action buttons with tooltips.
//               ✅ Uses SilverStockColors for consistent silver branding.
//               ✅ ObjectKey on parent side prevents state mix-up on delete.
//
// COLUMNS (in order):
//   S.NO | SUB CAT | ITEM NAME | HUID | GROSS | LESS | NET WT | RATE/g |
//   MAKING TYPE | MAKING | QTY | STONE VAL | ROW TOTAL | ACT
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lotus_erp/logic/stock/add_stock_controller.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/models/purchase/purchase_enums/purchase_enums.dart';
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
  bool _isHovered = false;

  // ── TEXT CONTROLLERS ─────────────────────────────────────────
  late final TextEditingController _itemCtrl;
  late final TextEditingController _huidCtrl;
  late final TextEditingController _grossCtrl;
  late final TextEditingController _lessCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _makingCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _stoneValCtrl;

  // ── FOCUS NODE ───────────────────────────────────────────────
  late final FocusNode _itemFocus;

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
    _qtyCtrl = TextEditingController();
    _stoneValCtrl = TextEditingController();
    _itemFocus = FocusNode();

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
    _qtyCtrl.dispose();
    _stoneValCtrl.dispose();
    _itemFocus.dispose();
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
    final ctrl = widget.ctrl;

    _setIfNeeded(_itemCtrl, row.itemName);
    _setIfNeeded(_huidCtrl, row.huid);
    _setIfNeeded(_grossCtrl, _dec(row.grossWeight));
    _setIfNeeded(_lessCtrl, _dec(row.stoneWeight));
    _setIfNeeded(_rateCtrl, _dec(row.purchaseRate));
    _setIfNeeded(_makingCtrl, _dec(row.makingCharges));
    _setIfNeeded(_qtyCtrl, row.quantity == 1 ? '' : '${row.quantity}');
    _setIfNeeded(_stoneValCtrl, _dec(row.stoneValue));
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
    final isEven = widget.index.isEven;
    final error = ctrl.validateRow(row);

    final background = error != null
        ? AddStockColors.danger.withOpacity(0.04)
        : _isHovered
            ? AddStockColors.cardHoverBg
            : (isEven ? AddStockColors.cardBg : AddStockColors.bodyBg);

    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus) ctrl.setActiveRow(row.id);
      },
      child: MouseRegion(
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
                color: error != null
                    ? AddStockColors.danger.withOpacity(0.18)
                    : AddStockColors.cardBorder,
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── S.NO ──────────────────────────────────────────
              _sNoCell(),
              const SizedBox(width: 8),

              // ── SUB CATEGORY ──────────────────────────────────
              _subCategoryCell(row, ctrl),
              const SizedBox(width: 8),

              // ── ITEM NAME ─────────────────────────────────────
              _textField(
                width: 200,
                controller: _itemCtrl,
                hint: 'e.g. Payal',
                focusNode: _itemFocus,
                onChanged: (v) => ctrl.updateItemName(row.id, v),
              ),
              const SizedBox(width: 8),

              // ── HUID ──────────────────────────────────────────
              _textField(
                width: 110,
                controller: _huidCtrl,
                hint: 'AB1234',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                textCapitalization: TextCapitalization.characters,
                onChanged: (v) => ctrl.updateHuid(row.id, v),
              ),
              const SizedBox(width: 8),

              // ── GROSS WEIGHT ──────────────────────────────────
              _numField(
                width: 88,
                controller: _grossCtrl,
                hint: '0.000',
                onChanged: (v) => ctrl.updateGrossWeight(row.id, v),
              ),
              const SizedBox(width: 8),

              // ── LESS (stone weight) ───────────────────────────
              _numField(
                width: 88,
                controller: _lessCtrl,
                hint: '0.000',
                onChanged: (v) => ctrl.updateStoneWeight(row.id, v),
              ),
              const SizedBox(width: 8),

              // ── NET WT (auto) ─────────────────────────────────
              _autoCell(
                width: 88,
                value: '${_wt(row.netWeight)} g',
                color: AddStockColors.success,
              ),
              const SizedBox(width: 8),

              // ── RATE/g ────────────────────────────────────────
              _numField(
                width: 110,
                controller: _rateCtrl,
                hint: '0.00',
                onChanged: (v) => ctrl.updatePurchaseRate(row.id, v),
              ),
              const SizedBox(width: 8),

              // ── MAKING TYPE ───────────────────────────────────
              _makingTypeCell(row, ctrl),
              const SizedBox(width: 8),

              // ── MAKING CHARGES ────────────────────────────────
              _numField(
                width: 100,
                controller: _makingCtrl,
                hint: '0.00',
                onChanged: (v) => ctrl.updateMakingCharges(row.id, v),
              ),
              const SizedBox(width: 8),

              // ── QTY ───────────────────────────────────────────
              _numField(
                width: 72,
                controller: _qtyCtrl,
                hint: '1',
                allowDecimal: false,
                onChanged: (v) => ctrl.updateQuantity(row.id, v),
              ),
              const SizedBox(width: 8),

              // ── STONE VALUE ───────────────────────────────────
              _numField(
                width: 110,
                controller: _stoneValCtrl,
                hint: '0.00',
                onChanged: (v) => ctrl.updateStoneValue(row.id, v),
                // Last editable field → Enter = complete row & jump next
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => ctrl.completeRowAndAdvance(row.id),
              ),
              const SizedBox(width: 8),

              // ── ROW TOTAL (auto) ──────────────────────────────
              _autoCell(
                width: 140,
                value: _money(ctrl.rowTotalAmount(row)),
                color: AddStockColors.textDark,
                alignRight: true,
                isBold: true,
              ),
              const SizedBox(width: 8),

              // ── ACT ───────────────────────────────────────────
              _actionCell(ctrl, row),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CELLS
  // ─────────────────────────────────────────────────────────────

  Widget _sNoCell() {
    return SizedBox(
      width: 62,
      child: Center(
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: SilverStockColors.brandSilver.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: SilverStockColors.brandSilver.withOpacity(0.32),
            ),
          ),
          child: Text(
            '${widget.index + 1}',
            style: AddStockStyles.fieldInput.copyWith(
              color: SilverStockColors.brandSilver,
              fontSize: 14,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _subCategoryCell(StockRowEntry row, SilverStockController ctrl) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<StockSubCategory>(
        value: row.subCategory,
        decoration: _inputDecoration(),
        dropdownColor: Colors.white,
        style: AddStockStyles.fieldInput.copyWith(
          fontSize: 13,
          color: AddStockColors.textDark,
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AddStockColors.textMuted,
          size: 18,
        ),
        items: StockSubCategory.values
            .map(
              (v) => DropdownMenuItem<StockSubCategory>(
                value: v,
                child: Text(
                  v.label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AddStockColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) ctrl.updateSubCategory(row.id, v);
        },
      ),
    );
  }

  Widget _makingTypeCell(StockRowEntry row, SilverStockController ctrl) {
    return SizedBox(
      width: 148,
      child: DropdownButtonFormField<MakingChargesType>(
        value: row.makingChargesType,
        decoration: _inputDecoration(),
        dropdownColor: Colors.white,
        style: AddStockStyles.fieldInput.copyWith(
          fontSize: 13,
          color: AddStockColors.textDark,
        ),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AddStockColors.textMuted,
          size: 18,
        ),
        items: MakingChargesType.values
            .map(
              (v) => DropdownMenuItem<MakingChargesType>(
                value: v,
                child: Text(
                  v.label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AddStockColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) ctrl.updateMakingType(row.id, v);
        },
      ),
    );
  }

  Widget _textField({
    required double width,
    required TextEditingController controller,
    required String hint,
    FocusNode? focusNode,
    TextCapitalization textCapitalization = TextCapitalization.words,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return SizedBox(
      width: width,
      height: 40,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        textInputAction: TextInputAction.next,
        style: AddStockStyles.fieldInput.copyWith(fontSize: 14),
        onChanged: onChanged,
        decoration: _inputDecoration(hint: hint),
      ),
    );
  }

  Widget _numField({
    required double width,
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    bool allowDecimal = true,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
  }) {
    return SizedBox(
      width: width,
      height: 40,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
        textAlign: TextAlign.right,
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            allowDecimal ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
          ),
        ],
        textInputAction: textInputAction,
        style: AddStockStyles.fieldInput.copyWith(
          fontSize: 14,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: _inputDecoration(hint: hint),
      ),
    );
  }

  Widget _autoCell({
    required double width,
    required String value,
    required Color color,
    bool alignRight = false,
    bool isBold = false,
  }) {
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Text(
        value,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: AddStockStyles.fieldInput.copyWith(
          color: color,
          fontSize: isBold ? 15 : 14,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _actionCell(SilverStockController ctrl, StockRowEntry row) {
    final canDelete = ctrl.rows.length > 1;

    return SizedBox(
      width: 96,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Duplicate
          Tooltip(
            message: 'Duplicate row',
            waitDuration: const Duration(milliseconds: 400),
            child: InkWell(
              onTap: () => ctrl.addRow(requestFocus: false),
              borderRadius: BorderRadius.circular(7),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: SilverStockColors.brandSilver.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: SilverStockColors.brandSilver.withOpacity(0.32),
                  ),
                ),
                child: Icon(
                  Icons.content_copy_rounded,
                  color: SilverStockColors.brandSilver,
                  size: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Delete
          Tooltip(
            message: canDelete ? 'Remove row' : 'Cannot remove last row',
            waitDuration: const Duration(milliseconds: 400),
            child: InkWell(
              onTap: canDelete ? () => ctrl.removeRow(row.id) : null,
              borderRadius: BorderRadius.circular(7),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: canDelete
                      ? AddStockColors.danger.withOpacity(0.10)
                      : AddStockColors.cardBorder.withOpacity(0.40),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: canDelete
                        ? AddStockColors.danger.withOpacity(0.32)
                        : AddStockColors.cardBorder,
                  ),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: canDelete
                      ? AddStockColors.danger
                      : AddStockColors.textMuted,
                  size: 17,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: AddStockColors.inputBg,
      hintStyle: TextStyle(
        color: AddStockColors.textMuted.withOpacity(0.52),
        fontSize: 12,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AddStockColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: SilverStockColors.brandSilver,
          width: 1.6,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AddStockColors.cardBorder),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

double _wt(double v) => double.parse(v.toStringAsFixed(3));

String _money(double amount) => NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs ',
      decimalDigits: 2,
    ).format(amount);
