import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../logic/booking_advance/booking_advance_controller.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import 'booking_item_grid_metrics.dart';
import '../widgets/booking_money_text.dart';
import '../../../models/booking_advance/booking_advance/booking_advance_model.dart';

part 'booking_item_row_controls.dart';
part 'booking_item_row_inputs.dart';

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

  void _refresh(VoidCallback callback) {
    setState(callback);
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
}
