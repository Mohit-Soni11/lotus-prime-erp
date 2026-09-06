import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../logic/booking_advance/booking_advance_controller.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import '../widgets/booking_money_text.dart';
import '../../../models/booking_advance/booking_advance/booking_advance_model.dart';

class BookingItemRow extends StatefulWidget {
  const BookingItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.controller,
  });

  final int index;
  final BookingItemModel item;
  final BookingAdvanceController controller;

  @override
  State<BookingItemRow> createState() => _BookingItemRowState();
}

class _BookingItemRowState extends State<BookingItemRow> {
  bool _hovered = false;
  late MetalType _currentMetal;
  late String _selectedPurity;

  static List<String> _puritiesFor(MetalType metal) {
    switch (metal) {
      case MetalType.gold:
        return ['24KT', '22KT', '18KT', '14KT', '9KT'];
      case MetalType.silver:
        return ['999', '925', '800'];
      case MetalType.platinum:
        return ['950PT', '900PT', '850PT'];
      case MetalType.diamond:
        return ['VVS1', 'VVS2', 'VS1', 'VS2'];
    }
  }

  @override
  void initState() {
    super.initState();
    _currentMetal = widget.item.metal;
    final existing = widget.item.purityCtrl.text.trim();
    final options = _puritiesFor(_currentMetal);
    _selectedPurity = options.contains(existing) ? existing : options.first;
    if (widget.item.purityCtrl.text.isEmpty) {
      widget.item.purityCtrl.text = _selectedPurity;
    }
  }

  void _onMetalChanged(MetalType metal) {
    widget.item.updateMetal(metal);
    setState(() {
      _currentMetal = metal;
      _selectedPurity = _puritiesFor(metal).first;
      widget.item.purityCtrl.text = _selectedPurity;
    });
  }

  Color _metalColor(MetalType metal) {
    switch (metal) {
      case MetalType.gold:
        return BookingAdvanceColors.metalGold;
      case MetalType.silver:
        return BookingAdvanceColors.metalSilver;
      case MetalType.platinum:
        return BookingAdvanceColors.metalPlatinum;
      case MetalType.diamond:
        return BookingAdvanceColors.metalDiamond;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        if (focused) widget.controller.activeItemIndex = widget.index;
      },
      child: ListenableBuilder(
        listenable: widget.item,
        builder: (_, __) {
          if (widget.item.metal != _currentMetal) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _onMetalChanged(widget.item.metal);
            });
          }

          final metalColor = _metalColor(widget.item.metal);
          final isEven = widget.index.isEven;
          final makingSuffix =
              widget.item.makingChargeType == MakingChargeType.perGram
                  ? '/g'
                  : widget.item.makingChargeType == MakingChargeType.perPiece
                      ? '/pc'
                      : '%';

          return MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _hovered
                    ? BookingAdvanceColors.cardHoverBg
                    : isEven
                        ? BookingAdvanceColors.bodyPanelBg
                        : BookingAdvanceColors.bodyBg,
                border: const Border(
                  bottom: BorderSide(
                    color: BookingAdvanceColors.bodyBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _serialNumber(metalColor),
                  const SizedBox(width: 6),
                  _metalSelector(metalColor),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 4,
                    child: _textField(
                      widget.item.descCtrl,
                      'Description',
                      focusNode: widget.item.firstFieldFocus,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 1,
                    child: _textField(
                      widget.item.pcsCtrl,
                      '1',
                      isNumber: true,
                      center: true,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(flex: 2, child: _purityField(metalColor)),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: _textField(widget.item.grossCtrl, '0.000',
                        isNumber: true),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: _textField(widget.item.lessCtrl, '0.000',
                        isNumber: true),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: _autoCell(
                      widget.item.netWt.toStringAsFixed(3),
                      metalColor,
                      center: true,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: _textField(widget.item.rateCtrl, 'Rate',
                        isNumber: true),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: _makingField(metalColor, makingSuffix),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: _autoCell(
                      BookingMoneyText.decimal(widget.item.totalValue),
                      BookingAdvanceColors.bodyTextMain,
                      right: true,
                      bold: true,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(flex: 3, child: _dateCell(context)),
                  const SizedBox(width: 6),
                  _deleteButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _serialNumber(Color color) {
    return Expanded(
      flex: 1,
      child: Center(
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metalSelector(Color color) {
    return Expanded(
      flex: 3,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.40)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<MetalType>(
            value: widget.item.metal,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: color),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
            dropdownColor: BookingAdvanceColors.bodyPanelBg,
            items: MetalType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) _onMetalChanged(value);
            },
          ),
        ),
      ),
    );
  }

  Widget _dateCell(BuildContext context) {
    final date = widget.controller.deliveryDate;
    return GestureDetector(
      onTap: () => _pickDate(context),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: date != null
              ? BookingAdvanceColors.brandGold.withValues(alpha: 0.06)
              : BookingAdvanceColors.bodyPanelBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: date != null
                ? BookingAdvanceColors.brandGold.withValues(alpha: 0.4)
                : BookingAdvanceColors.bodyBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              BookingAdvanceIcons.deliveryDate,
              size: 13,
              color: date != null
                  ? BookingAdvanceColors.brandGold
                  : BookingAdvanceColors.bodyTextMuted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('dd/MM/yy').format(date)
                    : 'Pick date',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: date != null
                      ? BookingAdvanceColors.brandGold
                      : BookingAdvanceColors.bodyTextMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.controller.deliveryDate ??
          DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: BookingAdvanceColors.brandGold,
            onPrimary: Colors.white,
            surface: BookingAdvanceColors.bodyPanelBg,
            onSurface: BookingAdvanceColors.bodyTextMain,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: BookingAdvanceColors.bodyPanelBg,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) widget.controller.setDeliveryDate(picked);
  }

  Widget _purityField(Color color) {
    final purities = _puritiesFor(widget.item.metal);
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: BookingAdvanceColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: widget.item.purityCtrl,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.only(left: 8, bottom: 2),
              ),
              onChanged: (value) => setState(() => _selectedPurity = value),
            ),
          ),
          PopupMenuButton<String>(
            icon:
                Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 20),
            color: BookingAdvanceColors.bodyPanelBg,
            position: PopupMenuPosition.under,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: BookingAdvanceColors.bodyBorder),
            ),
            onSelected: (value) {
              setState(() {
                _selectedPurity = value;
                widget.item.purityCtrl.text = value;
              });
            },
            itemBuilder: (_) => purities
                .map(
                  (purity) => PopupMenuItem(
                    value: purity,
                    height: 38,
                    child: Center(
                      child: Text(
                        purity,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
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

  Widget _makingField(Color color, String suffix) {
    return Row(
      children: [
        Expanded(
          child:
              _textField(widget.item.makingCtrl, 'Rate$suffix', isNumber: true),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Toggle making charge mode',
          child: InkWell(
            onTap: widget.item.toggleMakingChargeType,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BookingAdvanceColors.brandGold.withValues(alpha: 0.12),
                border: Border.all(
                  color: BookingAdvanceColors.brandGold.withValues(alpha: 0.40),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                suffix,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: BookingAdvanceColors.brandGold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _deleteButton() {
    return Expanded(
      flex: 1,
      child: Center(
        child: Tooltip(
          message: 'Remove item',
          child: InkWell(
            onTap: () => widget.controller.removeBookingItem(widget.index),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: BookingAdvanceColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: BookingAdvanceColors.danger.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: BookingAdvanceColors.danger,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    FocusNode? focusNode,
    bool center = false,
  }) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: isNumber
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
            : null,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: BookingAdvanceColors.textDark,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: BookingAdvanceColors.bodyTextMuted.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          filled: true,
          fillColor: BookingAdvanceColors.bodyPanelBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: BookingAdvanceColors.bodyBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide:
                const BorderSide(color: BookingAdvanceColors.bodyBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: BookingAdvanceColors.brandGold,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _autoCell(
    String value,
    Color color, {
    bool center = false,
    bool right = false,
    bool bold = false,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: center
          ? Alignment.center
          : right
              ? Alignment.centerRight
              : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        value,
        textAlign: right
            ? TextAlign.right
            : center
                ? TextAlign.center
                : TextAlign.left,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: bold ? 16 : 15,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
