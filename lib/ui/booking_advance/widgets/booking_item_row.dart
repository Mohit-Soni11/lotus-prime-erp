import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../logic/booking_advance/booking_advance_controller.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import 'booking_item_grid_metrics.dart';
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
  DateTime? _lastPurityPointerDown;

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
      _selectedPurity = widget.item.purityCtrl.text.trim();
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
              padding: const EdgeInsets.symmetric(
                horizontal: BookingItemGridMetrics.horizontalPadding,
                vertical: 9,
              ),
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
                  SizedBox(
                    width: BookingItemGridMetrics.description,
                    child: _textField(
                      widget.item.descCtrl,
                      'Description',
                      focusNode: widget.item.firstFieldFocus,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: BookingItemGridMetrics.pieces,
                    child: _textField(
                      widget.item.pcsCtrl,
                      '1',
                      isNumber: true,
                      center: true,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: BookingItemGridMetrics.purity,
                    child: _purityField(metalColor),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: BookingItemGridMetrics.grossWeight,
                    child: _textField(widget.item.grossCtrl, '0.000',
                        isNumber: true),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: BookingItemGridMetrics.lessWeight,
                    child: _textField(widget.item.lessCtrl, '0.000',
                        isNumber: true),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: BookingItemGridMetrics.netWeight,
                    child: _autoCell(
                      widget.item.netWt.toStringAsFixed(3),
                      metalColor,
                      center: true,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: BookingItemGridMetrics.rate,
                    child: _textField(
                      widget.item.rateCtrl,
                      'Rate',
                      isNumber: true,
                      right: true,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: BookingItemGridMetrics.making,
                    child: _makingField(metalColor, makingSuffix),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: BookingItemGridMetrics.total,
                    child: _autoCell(
                      BookingMoneyText.compact(widget.item.totalValue),
                      BookingAdvanceColors.bodyTextMain,
                      right: true,
                      bold: true,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: BookingItemGridMetrics.deliveryDate,
                    child: _dateCell(context),
                  ),
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
    return SizedBox(
      width: BookingItemGridMetrics.serial,
      child: Center(
        child: Container(
          width: BookingItemGridMetrics.controlHeight,
          height: BookingItemGridMetrics.controlHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(
              BookingItemGridMetrics.cellRadius,
            ),
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
    return Builder(
      builder: (fieldContext) => SizedBox(
        width: BookingItemGridMetrics.metal,
        child: Tooltip(
          message: 'Select metal',
          child: InkWell(
            onTap: () => _showMetalMenu(fieldContext),
            borderRadius:
                BorderRadius.circular(BookingItemGridMetrics.cellRadius),
            child: Container(
              height: BookingItemGridMetrics.controlHeight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                border: Border.all(color: color.withValues(alpha: 0.40)),
                borderRadius:
                    BorderRadius.circular(BookingItemGridMetrics.cellRadius),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.metal.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    color: color,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMetalMenu(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final box = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final selected = await showMenu<MetalType>(
      context: context,
      color: BookingAdvanceColors.bodyPanelBg,
      constraints: const BoxConstraints.tightFor(
        width: BookingItemGridMetrics.metal + 36,
      ),
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          offset.dx,
          offset.dy + BookingItemGridMetrics.controlHeight + 4,
          box.size.width,
          BookingItemGridMetrics.controlHeight,
        ),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BookingItemGridMetrics.cellRadius),
        side: const BorderSide(color: BookingAdvanceColors.bodyBorder),
      ),
      items: MetalType.values
          .map(
            (metal) => PopupMenuItem<MetalType>(
              value: metal,
              height: 42,
              padding: EdgeInsets.zero,
              child: _MetalMenuItem(
                metal: metal,
                color: _metalColor(metal),
                selected: metal == widget.item.metal,
              ),
            ),
          )
          .toList(),
    );
    if (!mounted || selected == null || selected == widget.item.metal) return;
    _onMetalChanged(selected);
  }

  Widget _dateCell(BuildContext context) {
    final date = widget.controller.deliveryDate;
    return GestureDetector(
      onTap: () => _pickDate(context),
      child: Container(
        height: BookingItemGridMetrics.controlHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: date != null
              ? BookingAdvanceColors.brandGold.withValues(alpha: 0.06)
              : BookingAdvanceColors.bodyPanelBg,
          borderRadius:
              BorderRadius.circular(BookingItemGridMetrics.cellRadius),
          border: Border.all(
            color: date != null
                ? BookingAdvanceColors.brandGold.withValues(alpha: 0.4)
                : BookingAdvanceColors.bodyBorder,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('dd MMM').format(date).toUpperCase()
                    : 'Delivery',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: date != null
                      ? BookingAdvanceColors.brandGold
                      : BookingAdvanceColors.bodyTextMuted,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
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
    return Builder(
      builder: (fieldContext) => Listener(
        onPointerDown: (_) {
          final now = DateTime.now();
          final previous = _lastPurityPointerDown;
          _lastPurityPointerDown = now;
          if (previous != null &&
              now.difference(previous) <= const Duration(milliseconds: 350)) {
            _showPurityMenu(fieldContext, color, purities);
          }
        },
        child: Container(
          height: BookingItemGridMetrics.controlHeight,
          decoration: BoxDecoration(
            color: BookingAdvanceColors.bodyBg,
            borderRadius:
                BorderRadius.circular(BookingItemGridMetrics.cellRadius),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: TextFormField(
            controller: widget.item.purityCtrl,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
            ),
            onChanged: (value) => setState(() => _selectedPurity = value),
          ),
        ),
      ),
    );
  }

  Future<void> _showPurityMenu(
    BuildContext context,
    Color color,
    List<String> purities,
  ) async {
    FocusScope.of(context).unfocus();
    final box = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final selected = await showMenu<String>(
      context: context,
      color: BookingAdvanceColors.bodyPanelBg,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          offset.dx,
          offset.dy + BookingItemGridMetrics.controlHeight + 4,
          box.size.width,
          BookingItemGridMetrics.controlHeight,
        ),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BookingItemGridMetrics.cellRadius),
        side: const BorderSide(color: BookingAdvanceColors.bodyBorder),
      ),
      items: [
        ...purities.map(
          (purity) => PopupMenuItem<String>(
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
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: '__custom__',
          height: 38,
          child: Center(
            child: Text(
              'CUSTOM',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );

    if (!mounted || selected == null) return;
    setState(() {
      if (selected == '__custom__') {
        widget.item.purityCtrl.clear();
        _selectedPurity = '';
      } else {
        widget.item.purityCtrl.text = selected;
        _selectedPurity = selected;
      }
    });
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
              width: 42,
              height: BookingItemGridMetrics.controlHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BookingAdvanceColors.brandGold.withValues(alpha: 0.12),
                border: Border.all(
                  color: BookingAdvanceColors.brandGold.withValues(alpha: 0.40),
                ),
                borderRadius:
                    BorderRadius.circular(BookingItemGridMetrics.cellRadius),
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
    return SizedBox(
      width: BookingItemGridMetrics.action,
      child: Center(
        child: Tooltip(
          message: 'Remove item',
          child: InkWell(
            onTap: () => widget.controller.removeBookingItem(widget.index),
            borderRadius:
                BorderRadius.circular(BookingItemGridMetrics.cellRadius),
            child: Container(
              width: BookingItemGridMetrics.controlHeight,
              height: BookingItemGridMetrics.controlHeight,
              decoration: BoxDecoration(
                color: BookingAdvanceColors.danger.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(BookingItemGridMetrics.cellRadius),
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
    bool right = false,
  }) {
    return SizedBox(
      height: BookingItemGridMetrics.controlHeight,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: isNumber
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
            : null,
        textAlign: center
            ? TextAlign.center
            : right
                ? TextAlign.right
                : TextAlign.start,
        textAlignVertical: TextAlignVertical.center,
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
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          filled: true,
          fillColor: BookingAdvanceColors.bodyPanelBg,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(BookingItemGridMetrics.cellRadius),
            borderSide:
                const BorderSide(color: BookingAdvanceColors.bodyBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(BookingItemGridMetrics.cellRadius),
            borderSide:
                const BorderSide(color: BookingAdvanceColors.bodyBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(BookingItemGridMetrics.cellRadius),
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
      height: BookingItemGridMetrics.controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: center
          ? Alignment.center
          : right
              ? Alignment.centerRight
              : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(BookingItemGridMetrics.cellRadius),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: right
            ? Alignment.centerRight
            : center
                ? Alignment.center
                : Alignment.centerLeft,
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
            fontSize: bold ? 16 : 14.5,
            height: 1.0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          maxLines: 1,
        ),
      ),
    );
  }
}

class _MetalMenuItem extends StatelessWidget {
  const _MetalMenuItem({
    required this.metal,
    required this.color,
    required this.selected,
  });

  final MetalType metal;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.10) : Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              metal.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? color : BookingAdvanceColors.textDark,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (selected)
            Icon(
              Icons.check_rounded,
              color: color,
              size: 16,
            ),
        ],
      ),
    );
  }
}
