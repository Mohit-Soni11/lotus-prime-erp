// =============================================================================
// FILE        : booking_scrap_table.dart
// MODULE      : Sales â†’ Booking & Advance
// DESCRIPTION : Exchange & Scrap Metal table â€” same as PosOldGoldTable.
//               Customer gives old/scrap metal as part of advance.
//               Columns: S.NO | METAL | DESCRIPTION | GR.WT | LESS |
//                        NET WT | PURITY | FINE WT | RATE | VALUE | ACT
// =============================================================================

import 'package:flutter/material.dart';
import '../../../theme/booking_advance/booking_advance_theme.dart';
import '../../../logic/booking_advance/booking_advance_controller.dart';
import '../../models/booking_advance/booking_advance/booking_advance_model.dart';
import '../../../models/sales_orders/sales_pos_enums/sales_pos_enums.dart';

class BookingScrapTable extends StatelessWidget {
  final BookingAdvanceController ctrl;
  const BookingScrapTable({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: BookingAdvanceColors.bodyPanelBg,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: BookingAdvanceColors.bodyBorder, width: 1.5),
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
            ctrl.scrapItems.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ctrl.scrapItems.length,
                    itemBuilder: (_, i) => BookingScrapRow(
                        index: i, item: ctrl.scrapItems[i], ctrl: ctrl),
                  ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: BookingAdvanceColors.danger.withValues(alpha: 0.04),
        border: const Border(
            bottom:
                BorderSide(color: BookingAdvanceColors.bodyBorder, width: 1.5)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: BookingAdvanceColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color:
                        BookingAdvanceColors.danger.withValues(alpha: 0.40))),
            child: const Icon(Icons.recycling_rounded,
                color: BookingAdvanceColors.danger, size: 22)),
        const SizedBox(width: 14),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('EXCHANGE & SCRAP METAL',
                  style: BookingAdvanceStyles.highVisHeader
                      .copyWith(color: BookingAdvanceColors.danger, height: 1)),
              const SizedBox(height: 4),
              Text('Customer giving old/scrap metal as advance',
                  style: BookingAdvanceStyles.subTitleMuted),
            ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: BookingAdvanceColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: BookingAdvanceColors.danger.withValues(alpha: 0.3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: BookingAdvanceColors.danger,
                    shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('SCRAP : ${ctrl.scrapItems.length}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: BookingAdvanceColors.danger,
                    letterSpacing: 0.8)),
          ]),
        ),
      ]),
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
      child: Row(children: [
        _h('S.NO', 1, center: true),
        const SizedBox(width: 6),
        _h('METAL', 3),
        const SizedBox(width: 6),
        _h('DESCRIPTION', 4),
        const SizedBox(width: 6),
        _h('GR. WT', 2),
        const SizedBox(width: 6),
        _h('LESS', 2),
        const SizedBox(width: 6),
        _h('NET WT', 2, center: true),
        const SizedBox(width: 6),
        _h('PURITY %', 2, center: true),
        const SizedBox(width: 6),
        _h('FINE WT', 2, center: true),
        const SizedBox(width: 6),
        _h('RATE', 3),
        const SizedBox(width: 6),
        _h('VALUE', 3, right: true),
        const SizedBox(width: 6),
        _h('ACT', 1, center: true),
      ]),
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
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: BookingAdvanceColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        BookingAdvanceColors.danger.withValues(alpha: 0.25))),
            child: const Icon(Icons.recycling_rounded,
                color: BookingAdvanceColors.danger, size: 30)),
        const SizedBox(height: 12),
        const Text('NO SCRAP/EXCHANGE METAL',
            style: TextStyle(
                color: BookingAdvanceColors.bodyTextMain,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0)),
        const SizedBox(height: 4),
        Text('Add old gold / scrap metal given by customer',
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
        InkWell(
          onTap: ctrl.addScrapItem,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: BookingAdvanceColors.danger.withValues(alpha: 0.08),
              border: Border.all(
                  color: BookingAdvanceColors.danger.withValues(alpha: 0.35),
                  width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_circle_outline_rounded,
                  color: BookingAdvanceColors.danger, size: 20),
              SizedBox(width: 8),
              Text('ADD SCRAP / OLD METAL',
                  style: TextStyle(
                      color: BookingAdvanceColors.danger,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8)),
            ]),
          ),
        ),
        if (ctrl.scrapItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                color: BookingAdvanceColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: BookingAdvanceColors.danger.withValues(alpha: 0.3),
                    width: 1.5)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('SCRAP METAL VALUE',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color: BookingAdvanceColors.danger,
                      letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text('â‚¹ ${ctrl.totalScrapVal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: BookingAdvanceColors.danger)),
            ]),
          ),
      ]),
    );
  }
}

// =============================================================================
// SCRAP ROW
// =============================================================================
class BookingScrapRow extends StatefulWidget {
  final int index;
  final BookingScrapModel item;
  final BookingAdvanceController ctrl;
  const BookingScrapRow(
      {super.key, required this.index, required this.item, required this.ctrl});
  @override
  State<BookingScrapRow> createState() => _BookingScrapRowState();
}

class _BookingScrapRowState extends State<BookingScrapRow> {
  bool _hovered = false;
  late MetalType _currentMetal;

  @override
  void initState() {
    super.initState();
    _currentMetal = widget.item.metal;
    if (widget.item.purityCtrl.text.isEmpty) {
      widget.item.purityCtrl.text = '100';
    }
  }

  void _onMetal(MetalType m) {
    setState(() {
      _currentMetal = m;
      widget.item.updateMetal(m);
    });
    if (m == MetalType.silver) {
      widget.item.purityCtrl.clear();
    } else if (widget.item.purityCtrl.text.isEmpty)
      widget.item.purityCtrl.text = '100';
  }

  Color _mc(MetalType m) {
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
    return ListenableBuilder(
      listenable: widget.item,
      builder: (_, __) {
        final mc = _mc(_currentMetal);
        final even = widget.index % 2 == 0;
        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _hovered
                  ? BookingAdvanceColors.danger.withValues(alpha: 0.04)
                  : (even
                      ? BookingAdvanceColors.bodyPanelBg
                      : BookingAdvanceColors.bodyBg),
              border: const Border(
                  bottom: BorderSide(color: BookingAdvanceColors.bodyBorder)),
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
                              color: BookingAdvanceColors.danger
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                  color: BookingAdvanceColors.danger
                                      .withValues(alpha: 0.35))),
                          child: Text('${widget.index + 1}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: BookingAdvanceColors.danger,
                                  fontFeatures: [
                                    FontFeature.tabularFigures()
                                  ]))))),
              const SizedBox(width: 6),
              // METAL
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
                        value: _currentMetal,
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
                      )))),
              const SizedBox(width: 6),
              Expanded(
                  flex: 4, child: _tf(widget.item.descCtrl, 'Description')),
              const SizedBox(width: 6),
              Expanded(
                  flex: 2,
                  child: _tf(widget.item.grossCtrl, '0.000', isNum: true)),
              const SizedBox(width: 6),
              Expanded(
                  flex: 2,
                  child: _tf(widget.item.lessCtrl, '0.000', isNum: true)),
              const SizedBox(width: 6),
              Expanded(
                  flex: 2,
                  child: _autoCell(widget.item.netWt.toStringAsFixed(3), mc,
                      center: true)),
              const SizedBox(width: 6),
              Expanded(
                  flex: 2,
                  child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                          color: BookingAdvanceColors.bodyBg,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: mc.withValues(alpha: 0.35))),
                      child: TextField(
                          controller: widget.item.purityCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: mc,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ]),
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 11),
                              hintText: '100',
                              hintStyle: TextStyle(
                                  color: mc.withValues(alpha: 0.5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800))))),
              const SizedBox(width: 6),
              Expanded(
                  flex: 2,
                  child: _autoCell(widget.item.fineWt.toStringAsFixed(3), mc,
                      center: true, bold: true)),
              const SizedBox(width: 6),
              Expanded(
                  flex: 3,
                  child: _tf(widget.item.rateCtrl, 'Rate', isNum: true)),
              const SizedBox(width: 6),
              Expanded(
                  flex: 3,
                  child: _autoCell(
                      'â‚¹${widget.item.totalValue.toStringAsFixed(2)}',
                      BookingAdvanceColors.danger,
                      right: true,
                      bold: true)),
              const SizedBox(width: 6),
              Expanded(
                  flex: 1,
                  child: Center(
                      child: InkWell(
                          onTap: () =>
                              widget.ctrl.removeScrapItem(widget.index),
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
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: BookingAdvanceColors.danger,
                                  size: 20))))),
            ]),
          ),
        );
      },
    );
  }

  Widget _tf(TextEditingController ctrl, String hint, {bool isNum = false}) {
    return SizedBox(
        height: 36,
        child: TextField(
          controller: ctrl,
          keyboardType: isNum
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
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
                fontSize: 13),
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
                fontFeatures: const [FontFeature.tabularFigures()])));
  }
}
