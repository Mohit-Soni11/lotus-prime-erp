part of '../booking_scrap_table.dart';

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
    } else if (widget.item.purityCtrl.text.isEmpty) {
      widget.item.purityCtrl.text = '100';
    }
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
                      BookingMoneyText.decimal(widget.item.totalValue),
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
