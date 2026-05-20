// =============================================================================
// FILE        : booking_items_table.dart
// MODULE      : Sales â†’ Booking & Advance
// DESCRIPTION : Booking items table â€” same structure as PosSaleItemsTable.
//               Multiple items, no HUID, has delivery date.
//               Columns: S.NO | METAL | DESCRIPTION | PCS | PURITY |
//                        GR.WT | LESS | NET WT | RATE | MAKING | TOTAL | DEL.DATE | ACT
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import '../../../logic/booking_advance/booking_advance_controller.dart';
import '../../models/booking_advance_/booking_advance/booking_advance_model.dart';
import '../../../models/sales%20&%20orders/sales_pos_enums/sales_pos_enums.dart';

class BookingItemsTable extends StatelessWidget {
  final BookingAdvanceController ctrl;
  const BookingItemsTable({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f2): ctrl.addBookingItem,
        const SingleActivator(LogicalKeyboardKey.delete): ctrl.removeActiveItem,
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: ctrl,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              color: BookingAdvanceColors.bodyPanelBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: BookingAdvanceColors.bodyBorder, width: 1.5),
              boxShadow: const [
                BoxShadow(
                    color: BookingAdvanceColors.shadowLight,
                    blurRadius: 10,
                    offset: Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildColumnRow(),
                ctrl.bookingItems.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ctrl.bookingItems.length,
                        itemBuilder: (_, i) => BookingItemRow(
                            index: i, item: ctrl.bookingItems[i], ctrl: ctrl),
                      ),
                _buildBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: BookingAdvanceColors.brandGold.withValues(alpha: 0.06),
        border: const Border(
            bottom:
                BorderSide(color: BookingAdvanceColors.bodyBorder, width: 1.5)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BookingAdvanceColors.brandGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color:
                        BookingAdvanceColors.brandGold.withValues(alpha: 0.40)),
              ),
              child: const Center(
                  child: Icon(BookingAdvanceIcons.itemIcon,
                      color: BookingAdvanceColors.brandGold, size: 22)),
            ),
            const SizedBox(width: 14),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('BOOKING ITEMS',
                      style: BookingAdvanceStyles.highVisHeader),
                  const SizedBox(height: 4),
                  Text('Press F2 to add item',
                      style: BookingAdvanceStyles.subTitleMuted),
                ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: BookingAdvanceColors.bodyBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: BookingAdvanceColors.bodyBorder, width: 1.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: BookingAdvanceColors.brandGold,
                        shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('ITEMS : ${ctrl.bookingItems.length}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: BookingAdvanceColors.bodyTextMain)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
          color: BookingAdvanceColors.bodyBg,
          border: Border(
              bottom: BorderSide(
                  color: BookingAdvanceColors.bodyBorder, width: 1.5))),
      child: Row(
        children: [
          _h('S.NO', 1, center: true),
          const SizedBox(width: 6),
          _h('METAL', 3),
          const SizedBox(width: 6),
          _h('DESCRIPTION', 4),
          const SizedBox(width: 6),
          _h('PCS', 1, center: true),
          const SizedBox(width: 6),
          _h('PURITY', 2, center: true),
          const SizedBox(width: 6),
          _h('GR. WT', 2),
          const SizedBox(width: 6),
          _h('LESS', 2),
          const SizedBox(width: 6),
          _h('NET WT', 2, center: true),
          const SizedBox(width: 6),
          _h('RATE', 3),
          const SizedBox(width: 6),
          _h('MAKING', 3),
          const SizedBox(width: 6),
          _h('TOTAL', 3, right: true),
          const SizedBox(width: 6),
          _h('DEL. DATE', 3),
          const SizedBox(width: 6),
          _h('ACT', 1, center: true),
        ],
      ),
    );
  }

  Widget _h(String t, int flex, {bool right = false, bool center = false}) =>
      Expanded(
          flex: flex,
          child: Text(t,
              textAlign: right
                  ? TextAlign.right
                  : (center ? TextAlign.center : TextAlign.left),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: BookingAdvanceColors.textDark,
                  letterSpacing: 0.8)));

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: BookingAdvanceColors.bodyBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: BookingAdvanceColors.bodyBorder, width: 2.0)),
            child: const Icon(BookingAdvanceIcons.itemIcon,
                color: BookingAdvanceColors.brandGold, size: 36)),
        const SizedBox(height: 18),
        const Text('BOOKING LIST IS EMPTY',
            style: TextStyle(
                color: BookingAdvanceColors.bodyTextMain,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        const SizedBox(height: 6),
        Text('Press F2 or click ADD ITEM to add booking items',
            style: BookingAdvanceStyles.subTitleMuted),
      ])),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: BookingAdvanceColors.bodyPanelBg,
        border: Border(
            top:
                BorderSide(color: BookingAdvanceColors.bodyBorder, width: 1.5)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        // ADD ITEM BUTTON
        InkWell(
          onTap: ctrl.addBookingItem,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: BookingAdvanceColors.success.withValues(alpha: 0.08),
              border: Border.all(
                  color: BookingAdvanceColors.success.withValues(alpha: 0.35),
                  width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.add_circle_outline_rounded,
                  color: BookingAdvanceColors.success, size: 20),
              const SizedBox(width: 8),
              const Text('ADD ITEM',
                  style: TextStyle(
                      color: BookingAdvanceColors.success,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8)),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: BookingAdvanceColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('[F2]',
                    style: TextStyle(
                        color: BookingAdvanceColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0)),
              ),
            ]),
          ),
        ),
        // METAL TOTALS
        if (ctrl.bookingItems.isNotEmpty) _buildTotals(),
      ]),
    );
  }

  Widget _buildTotals() {
    final goldWt = ctrl.totalBookingGoldWt;
    final silverWt = ctrl.totalBookingSilverWt;
    final total = ctrl.totalBookingVal;

    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (goldWt > 0)
        _box('GOLD', '${goldWt.toStringAsFixed(3)} g',
            BookingAdvanceColors.metalGold),
      if (goldWt > 0 && silverWt > 0) const SizedBox(width: 10),
      if (silverWt > 0)
        _box('SILVER', '${silverWt.toStringAsFixed(3)} g',
            BookingAdvanceColors.metalSilver),
      if (total > 0) ...[
        const SizedBox(width: 10),
        _box(
            'TOTAL VALUE',
            'â‚¹ ${NumberFormat('#,##,###').format(total.toInt())}',
            BookingAdvanceColors.brandGold),
      ],
    ]);
  }

  Widget _box(String label, String val, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  color: color,
                  letterSpacing: 1.0)),
          const SizedBox(height: 4),
          Text(val,
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 14, color: color)),
        ]),
      );
}

// =============================================================================
// BOOKING ITEM ROW
// =============================================================================
class BookingItemRow extends StatefulWidget {
  final int index;
  final BookingItemModel item;
  final BookingAdvanceController ctrl;
  const BookingItemRow(
      {super.key, required this.index, required this.item, required this.ctrl});
  @override
  State<BookingItemRow> createState() => _BookingItemRowState();
}

class _BookingItemRowState extends State<BookingItemRow> {
  bool _hovered = false;
  late MetalType _currentMetal;
  late String _selectedPurity;

  static List<String> _puritiesFor(MetalType m) {
    switch (m) {
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

  void _onMetal(MetalType m) {
    widget.item.updateMetal(m);
    setState(() {
      _currentMetal = m;
      _selectedPurity = _puritiesFor(m).first;
      widget.item.purityCtrl.text = _selectedPurity;
    });
  }

  Color _metalColor(MetalType m) {
    switch (m) {
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
      onFocusChange: (f) {
        if (f) widget.ctrl.activeItemIndex = widget.index;
      },
      child: ListenableBuilder(
        listenable: widget.item,
        builder: (_, __) {
          if (widget.item.metal != _currentMetal) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _onMetal(widget.item.metal);
            });
          }
          final mc = _metalColor(widget.item.metal);
          final even = widget.index % 2 == 0;
          final sym = widget.item.makingChargeType == MakingChargeType.perGram
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
                    : (even
                        ? BookingAdvanceColors.bodyPanelBg
                        : BookingAdvanceColors.bodyBg),
                border: const Border(
                    bottom: BorderSide(
                        color: BookingAdvanceColors.bodyBorder, width: 1)),
              ),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                // S.NO
                Expanded(
                    flex: 1,
                    child: Center(
                        child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: mc.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                    color: mc.withValues(alpha: 0.35))),
                            child: Text('${widget.index + 1}',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: mc,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ]))))),
                const SizedBox(width: 6),
                // METAL DROPDOWN
                Expanded(
                    flex: 3,
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                          color: mc.withValues(alpha: 0.10),
                          border: Border.all(color: mc.withValues(alpha: 0.40)),
                          borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                          child: DropdownButton<MetalType>(
                        value: widget.item.metal,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: mc, size: 22),
                        style: TextStyle(
                            color: mc,
                            fontSize: 14,
                            fontWeight: FontWeight.w900),
                        dropdownColor: BookingAdvanceColors.bodyPanelBg,
                        items: MetalType.values
                            .map((t) => DropdownMenuItem(
                                value: t, child: Text(t.displayName)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) _onMetal(v);
                        },
                      )),
                    )),
                const SizedBox(width: 6),
                // DESCRIPTION
                Expanded(
                    flex: 4,
                    child: _tf(widget.item.descCtrl, 'Description',
                        focusNode: widget.item.firstFieldFocus)),
                const SizedBox(width: 6),
                // PCS
                Expanded(
                    flex: 1,
                    child: _tf(widget.item.pcsCtrl, '1',
                        isNum: true, center: true)),
                const SizedBox(width: 6),
                // PURITY
                Expanded(flex: 2, child: _buildPurityField(mc)),
                const SizedBox(width: 6),
                // GR WT
                Expanded(
                    flex: 2,
                    child: _tf(widget.item.grossCtrl, '0.000', isNum: true)),
                const SizedBox(width: 6),
                // LESS
                Expanded(
                    flex: 2,
                    child: _tf(widget.item.lessCtrl, '0.000', isNum: true)),
                const SizedBox(width: 6),
                // NET WT (auto)
                Expanded(
                    flex: 2,
                    child: _autoCell(widget.item.netWt.toStringAsFixed(3), mc,
                        center: true)),
                const SizedBox(width: 6),
                // RATE
                Expanded(
                    flex: 3,
                    child: _tf(widget.item.rateCtrl, 'Rate', isNum: true)),
                const SizedBox(width: 6),
                // MAKING
                Expanded(flex: 3, child: _buildMakingField(mc, sym)),
                const SizedBox(width: 6),
                // TOTAL (auto)
                Expanded(
                    flex: 3,
                    child: _autoCell(
                        'â‚¹${widget.item.totalValue.toStringAsFixed(2)}',
                        BookingAdvanceColors.bodyTextMain,
                        right: true,
                        bold: true)),
                const SizedBox(width: 6),
                // DELIVERY DATE
                Expanded(flex: 3, child: _buildDateCell(context)),
                const SizedBox(width: 6),
                // DELETE
                Expanded(
                    flex: 1,
                    child: Center(
                        child: Tooltip(
                            message: 'Remove item',
                            child: InkWell(
                                onTap: () =>
                                    widget.ctrl.removeBookingItem(widget.index),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                        color: BookingAdvanceColors.danger
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: BookingAdvanceColors.danger
                                                .withValues(alpha: 0.35))),
                                    child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: BookingAdvanceColors.danger,
                                        size: 20)))))),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateCell(BuildContext context) {
    final date = widget.ctrl.deliveryDate;
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
                  : BookingAdvanceColors.bodyBorder),
        ),
        child: Row(children: [
          Icon(BookingAdvanceIcons.deliveryDate,
              size: 13,
              color: date != null
                  ? BookingAdvanceColors.brandGold
                  : BookingAdvanceColors.bodyTextMuted),
          const SizedBox(width: 4),
          Expanded(
              child: Text(
            date != null ? DateFormat('dd/MM/yy').format(date) : 'Pick date',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: date != null
                    ? BookingAdvanceColors.brandGold
                    : BookingAdvanceColors.bodyTextMuted),
            overflow: TextOverflow.ellipsis,
          )),
        ]),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.ctrl.deliveryDate ??
          DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                  primary: BookingAdvanceColors.brandGold,
                  onPrimary: Colors.white,
                  surface: BookingAdvanceColors.bodyPanelBg,
                  onSurface: BookingAdvanceColors.bodyTextMain),
              dialogTheme: const DialogThemeData(
                  backgroundColor: BookingAdvanceColors.bodyPanelBg)),
          child: child!),
    );
    if (picked != null) widget.ctrl.setDeliveryDate(picked);
  }

  Widget _buildPurityField(Color mc) {
    final purities = _puritiesFor(widget.item.metal);
    return Container(
      height: 38,
      decoration: BoxDecoration(
          color: BookingAdvanceColors.bodyBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: mc.withValues(alpha: 0.35))),
      child: Row(children: [
        Expanded(
            child: TextFormField(
          controller: widget.item.purityCtrl,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: mc,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              fontFeatures: const [FontFeature.tabularFigures()]),
          decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.only(left: 8, bottom: 2)),
          onChanged: (v) => setState(() => _selectedPurity = v),
        )),
        PopupMenuButton<String>(
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: mc, size: 20),
          color: BookingAdvanceColors.bodyPanelBg,
          position: PopupMenuPosition.under,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: BookingAdvanceColors.bodyBorder)),
          onSelected: (v) {
            setState(() {
              _selectedPurity = v;
              widget.item.purityCtrl.text = v;
            });
          },
          itemBuilder: (_) => purities
              .map((p) => PopupMenuItem(
                  value: p,
                  height: 38,
                  child: Center(
                      child: Text(p,
                          style: TextStyle(
                              color: mc,
                              fontWeight: FontWeight.w900,
                              fontSize: 14)))))
              .toList(),
        ),
      ]),
    );
  }

  Widget _buildMakingField(Color mc, String sym) {
    return Row(children: [
      Expanded(child: _tf(widget.item.makingCtrl, 'Rate$sym', isNum: true)),
      const SizedBox(width: 4),
      Tooltip(
          message: 'Toggle: /g âž” /pc âž” %',
          child: InkWell(
              onTap: widget.item.toggleMakingChargeType,
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: BookingAdvanceColors.brandGold
                          .withValues(alpha: 0.12),
                      border: Border.all(
                          color: BookingAdvanceColors.brandGold
                              .withValues(alpha: 0.40)),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(sym,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: BookingAdvanceColors.brandGold))))),
    ]);
  }

  Widget _tf(TextEditingController ctrl, String hint,
      {bool isNum = false, FocusNode? focusNode, bool center = false}) {
    return SizedBox(
        height: 36,
        child: TextField(
          controller: ctrl,
          focusNode: focusNode,
          keyboardType: isNum
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: isNum
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : null,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: BookingAdvanceColors.textDark,
              fontFeatures: [FontFeature.tabularFigures()]),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color:
                    BookingAdvanceColors.bodyTextMuted.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: FontWeight.w500),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            filled: true,
            fillColor: BookingAdvanceColors.bodyPanelBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide:
                    const BorderSide(color: BookingAdvanceColors.bodyBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide:
                    const BorderSide(color: BookingAdvanceColors.bodyBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                    color: BookingAdvanceColors.brandGold, width: 1.5)),
          ),
        ));
  }

  Widget _autoCell(String val, Color color,
      {bool center = false, bool right = false, bool bold = false}) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: center
          ? Alignment.center
          : (right ? Alignment.centerRight : Alignment.centerLeft),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Text(val,
          textAlign: right
              ? TextAlign.right
              : (center ? TextAlign.center : TextAlign.left),
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: bold ? 16 : 15,
              fontFeatures: const [FontFeature.tabularFigures()])),
    );
  }
}
