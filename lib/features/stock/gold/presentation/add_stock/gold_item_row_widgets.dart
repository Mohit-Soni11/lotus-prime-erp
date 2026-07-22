part of 'gold_item_row.dart';

class _GoldTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final bool isNumber;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;

  const _GoldTextField({
    required this.controller,
    required this.hint,
    this.focusNode,
    this.isNumber = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildField(bool hasFocus) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        height: _invoiceFieldHeight,
        decoration: BoxDecoration(
          color: GoldStockColors.inputBg,
          borderRadius: BorderRadius.circular(_invoiceFieldRadius),
          border: Border.all(
            color: hasFocus
                ? GoldStockColors.brandGold
                : GoldStockColors.cardBorder,
            width: hasFocus ? 2.0 : 1.5,
          ),
        ),
        alignment: Alignment.center,
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
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'),
                      ),
                    ]
                  : null),
          textInputAction: textInputAction,
          textAlign: textAlign,
          textAlignVertical: TextAlignVertical.center,
          maxLines: 1,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: GoldStockColors.textDark,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            isDense: true,
            isCollapsed: true,
            hintText: hint,
            hintStyle: const TextStyle(
              color: GoldStockColors.textHint,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
          ),
        ),
      );
    }

    if (focusNode == null) {
      return buildField(false);
    }

    return ListenableBuilder(
      listenable: focusNode!,
      builder: (context, _) => buildField(focusNode!.hasFocus),
    );
  }
}

class _QuantityUnitButton extends StatelessWidget {
  final GoldItemModel model;

  const _QuantityUnitButton({required this.model});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'Auto detects unit from item type/name. ${model.quantityUnitLabel} quantity maps to ${model.stockPieces} physical stock piece${model.stockPieces == 1 ? '' : 's'}.',
      waitDuration: const Duration(milliseconds: 400),
      child: PopupMenuButton<GoldQuantityUnit>(
        tooltip: 'Select quantity unit',
        onSelected: (unit) => model.setQuantityUnit(unit),
        itemBuilder: (context) => GoldQuantityUnit.values
            .map(
              (unit) => PopupMenuItem<GoldQuantityUnit>(
                value: unit,
                height: _invoiceFieldHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        unit.shortCode,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: GoldStockColors.brandGold,
                        ),
                      ),
                    ),
                    Text(
                      unit.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: GoldStockColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: 62,
          height: _invoiceFieldHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: GoldStockColors.brandGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(_invoiceFieldRadius),
            border: Border.all(
              color: GoldStockColors.brandGold.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    model.quantityUnitCode,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: GoldStockColors.brandGold,
                    ),
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: GoldStockColors.brandGold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldPopupField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final List<String> popupItems;
  final ValueChanged<String> onSelected;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _GoldPopupField({
    required this.controller,
    required this.hint,
    required this.popupItems,
    required this.onSelected,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildField(bool hasFocus) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        height: _invoiceFieldHeight,
        decoration: BoxDecoration(
          color: GoldStockColors.inputBg,
          borderRadius: BorderRadius.circular(_invoiceFieldRadius),
          border: Border.all(
            color: hasFocus
                ? GoldStockColors.brandGold
                : GoldStockColors.cardBorder,
            width: hasFocus ? 2.0 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: textInputAction,
                onFieldSubmitted: onSubmitted,
                textAlign: TextAlign.left,
                textAlignVertical: TextAlignVertical.center,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: GoldStockColors.textDark,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  isDense: true,
                  isCollapsed: true,
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: GoldStockColors.textHint,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 36,
              height: _invoiceFieldHeight,
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: GoldStockColors.brandGold,
                  size: 20,
                ),
                color: GoldStockColors.cardBg,
                position: PopupMenuPosition.under,
                padding: EdgeInsets.zero,
                splashRadius: 18,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_invoiceFieldRadius),
                  side: const BorderSide(color: GoldStockColors.cardBorder),
                ),
                onSelected: onSelected,
                itemBuilder: (context) => popupItems
                    .map(
                      (choice) => PopupMenuItem<String>(
                        value: choice,
                        height: _invoiceFieldHeight,
                        child: Text(
                          choice,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: GoldStockColors.textDark,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      );
    }

    if (focusNode == null) {
      return buildField(false);
    }

    return ListenableBuilder(
      listenable: focusNode!,
      builder: (context, _) => buildField(focusNode!.hasFocus),
    );
  }
}

class _HuidTrackingSwitch extends StatelessWidget {
  final GoldItemModel model;

  const _HuidTrackingSwitch({required this.model});

  @override
  Widget build(BuildContext context) {
    final enabled = model.huidTrackingEnabled;
    return Tooltip(
      message: enabled
          ? 'HUID tracking is on. ${model.quantityUnitLabel} quantity creates ${model.stockPieces} physical HUID slot${model.stockPieces == 1 ? '' : 's'}.'
          : 'Bulk gold stock. Turn on only for HUID hallmark items.',
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: () => model.setHuidTrackingEnabled(!enabled),
        borderRadius: BorderRadius.circular(_invoiceFieldRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: _invoiceFieldHeight,
          height: _invoiceFieldHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? GoldStockColors.brandGold.withValues(alpha: 0.14)
                : GoldStockColors.inputBg,
            borderRadius: BorderRadius.circular(_invoiceFieldRadius),
            border: Border.all(
              color: enabled
                  ? GoldStockColors.brandGold.withValues(alpha: 0.42)
                  : GoldStockColors.cardBorder,
              width: 1.5,
            ),
          ),
          child: Icon(
            enabled ? Icons.verified_user_rounded : Icons.inventory_2_outlined,
            size: 18,
            color:
                enabled ? GoldStockColors.brandGold : GoldStockColors.textMuted,
          ),
        ),
      ),
    );
  }
}
