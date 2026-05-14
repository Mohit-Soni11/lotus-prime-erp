// =============================================================================
// silver_item_row.dart  —  INVOICE ITEMS ROW (SILVER)
// Exact same pattern as PosSaleItemRow — pixel-perfect match.
// Uses SilverItemModel (owns controllers + focus nodes).
// NO local state controllers — zero sync bugs.
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/stock/stock_item_model/add_stock_silver/silver_item_model.dart';
import 'package:lotus_erp/logic/stock/add_stock_silver/silver_stock_controller.dart';
import 'package:lotus_erp/theme/stock/add_stock/add_stock_silver/silver_stock_colors.dart';

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
  void didUpdateWidget(covariant SilverItemRow old) {
    super.didUpdateWidget(old);
    _handlePendingFocus();
  }

  void _handlePendingFocus() {
    if (!widget.ctrl.shouldRequestSilverFocus(widget.model.id)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.model.itemNameFocus.requestFocus();
      widget.ctrl.clearSilverFocusRequest(widget.model.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEven = widget.index % 2 == 0;

    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus) widget.ctrl.setSilverActiveRow(widget.model.id);
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
                  // ── S.NO ──────────────────────────────────────
                  Expanded(flex: 1, child: _buildSNo()),
                  const SizedBox(width: 6),

                  // ── ITEM NAME ──────────────────────────────────
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

                  // ── HUID ───────────────────────────────────────
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
                            RegExp(r'[a-zA-Z0-9]')),
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onSubmitted: (_) =>
                          widget.model.grossFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── GROSS WT ───────────────────────────────────
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

                  // ── LESS ───────────────────────────────────────
                  Expanded(
                    flex: 2,
                    child: _SilverTextField(
                      controller: widget.model.lessCtrl,
                      focusNode: widget.model.lessFocus,
                      hint: '0.000',
                      isNumber: true,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => widget.model.rateFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── NET WT — auto-calculated, silver-tinted ────
                  Expanded(
                    flex: 2,
                    child: _buildAutoCell(
                      value: widget.model.netWeight.toStringAsFixed(3),
                      color: SilverStockColors.brandSilver,
                      align: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── RATE / g ───────────────────────────────────
                  Expanded(
                    flex: 3,
                    child: _SilverTextField(
                      controller: widget.model.rateCtrl,
                      focusNode: widget.model.rateFocus,
                      hint: 'Rate',
                      isNumber: true,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) =>
                          widget.model.makingFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── MAKING — input + toggle ────────────────────
                  Expanded(flex: 3, child: _buildMakingField()),
                  const SizedBox(width: 6),

                  // ── TOTAL — auto-calculated, bold dark ────────
                  Expanded(
                    flex: 3,
                    child: _buildAutoCell(
                      value: '₹${widget.model.totalAmount.toStringAsFixed(2)}',
                      color: SilverStockColors.textDark,
                      align: TextAlign.right,
                      isBold: true,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── DELETE ─────────────────────────────────────
                  Expanded(flex: 1, child: _buildDeleteBtn()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // S.NO  — silver-tinted badge (exact same as PosSaleItemRow)
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
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // AUTO CELL — read-only computed value (NET WT / TOTAL)
  // 1:1 copy of POS _buildAutoCell styling
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
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MAKING FIELD — input + type toggle button
  // 1:1 copy of POS _buildMakingField layout
  // ─────────────────────────────────────────────────────────────
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
          message: 'Toggle: /g → Flat → %',
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
                style: TextStyle(
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

  // ─────────────────────────────────────────────────────────────
  // DELETE BUTTON — POS jaisa: ALWAYS active, koi bhi row delete ho
  // sakti hai (including last row). Empty state table handle karta hai.
  // ─────────────────────────────────────────────────────────────
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

// =============================================================================
// _SilverTextField
// Same as PosAtomicTextField — silver focused border, same look & feel.
// =============================================================================
class _SilverTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final bool isNumber;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  const _SilverTextField({
    required this.controller,
    required this.hint,
    this.focusNode,
    this.isNumber = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
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
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                : null),
        textInputAction: textInputAction,
        textAlign: isNumber ? TextAlign.right : TextAlign.left,
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
