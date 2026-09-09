part of 'booking_item_row.dart';

extension _BookingItemRowControls on _BookingItemRowState {
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
    final purities = _BookingItemRowState._puritiesFor(widget.item.metal);
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
            onChanged: (value) => _refresh(() => _selectedPurity = value),
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
    _refresh(() {
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
}
