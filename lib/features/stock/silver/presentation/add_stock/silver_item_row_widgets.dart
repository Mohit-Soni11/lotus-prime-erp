part of 'silver_item_row.dart';

class _QuantityModeButton extends StatelessWidget {
  final SilverItemModel model;

  const _QuantityModeButton({required this.model});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Choose Pieces, Packet, Pair or Set quantity mode.',
      waitDuration: const Duration(milliseconds: 400),
      child: PopupMenuButton<SilverQuantityMode>(
        tooltip: '',
        color: SilverStockColors.cardBg,
        position: PopupMenuPosition.under,
        padding: EdgeInsets.zero,
        splashRadius: 18,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_invoiceFieldRadius),
          side: const BorderSide(color: SilverStockColors.cardBorder),
        ),
        onSelected: model.setQuantityMode,
        itemBuilder: (context) => SilverQuantityMode.values
            .map(
              (mode) => PopupMenuItem<SilverQuantityMode>(
                value: mode,
                height: _invoiceFieldHeight,
                child: Text(
                  mode.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: SilverStockColors.textDark,
                  ),
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
            color: SilverStockColors.brandSilver.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(_invoiceFieldRadius),
            border: Border.all(
              color: SilverStockColors.brandSilver.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                model.quantityUnitCode,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: SilverStockColors.brandSilver,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: SilverStockColors.brandSilver,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HuidTrackingSwitch extends StatelessWidget {
  final SilverItemModel model;

  const _HuidTrackingSwitch({required this.model});

  @override
  Widget build(BuildContext context) {
    final enabled = model.huidTrackingEnabled;
    return Tooltip(
      message: enabled
          ? 'HUID tracking is on. ${model.quantityMode.label} quantity creates ${model.pieces} HUID slot(s).'
          : 'Bulk silver stock. Turn on only for HUID hallmark items.',
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
                ? SilverStockColors.brandSilver.withValues(alpha: 0.14)
                : SilverStockColors.inputBg,
            borderRadius: BorderRadius.circular(_invoiceFieldRadius),
            border: Border.all(
              color: enabled
                  ? SilverStockColors.brandSilver.withValues(alpha: 0.42)
                  : SilverStockColors.cardBorder,
              width: 1.5,
            ),
          ),
          child: Icon(
            enabled ? Icons.verified_user_rounded : Icons.inventory_2_outlined,
            size: 18,
            color: enabled
                ? SilverStockColors.brandSilver
                : SilverStockColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _QuantityTotalBadge extends StatelessWidget {
  final String value;

  const _QuantityTotalBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: _invoiceFieldHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SilverStockColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(_invoiceFieldRadius),
        border: Border.all(
          color: SilverStockColors.success.withValues(alpha: 0.28),
          width: 1.5,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$value pcs',
          maxLines: 1,
          softWrap: false,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: SilverStockColors.success,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _SilverTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final bool isNumber;
  final bool allowDecimal;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;

  const _SilverTextField({
    required this.controller,
    required this.hint,
    this.focusNode,
    this.isNumber = false,
    this.allowDecimal = true,
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
          color: SilverStockColors.inputBg,
          borderRadius: BorderRadius.circular(_invoiceFieldRadius),
          border: Border.all(
            color: hasFocus
                ? SilverStockColors.brandSilver
                : SilverStockColors.cardBorder,
            width: hasFocus ? 2.0 : 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: isNumber
              ? TextInputType.numberWithOptions(decimal: allowDecimal)
              : TextInputType.text,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters ??
              (isNumber
                  ? (allowDecimal
                      ? [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ]
                      : [FilteringTextInputFormatter.digitsOnly])
                  : null),
          textInputAction: textInputAction,
          textAlign: textAlign,
          textAlignVertical: TextAlignVertical.center,
          maxLines: 1,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: SilverStockColors.textDark,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            isDense: true,
            isCollapsed: true,
            hintText: hint,
            hintStyle: const TextStyle(
              color: SilverStockColors.textHint,
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

class _SilverPopupField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final List<String> popupItems;
  final ValueChanged<String> onSelected;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _SilverPopupField({
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
          color: SilverStockColors.inputBg,
          borderRadius: BorderRadius.circular(_invoiceFieldRadius),
          border: Border.all(
            color: hasFocus
                ? SilverStockColors.brandSilver
                : SilverStockColors.cardBorder,
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
                  color: SilverStockColors.textDark,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  isDense: true,
                  isCollapsed: true,
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: SilverStockColors.textHint,
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
                  color: SilverStockColors.brandSilver,
                  size: 20,
                ),
                color: SilverStockColors.cardBg,
                position: PopupMenuPosition.under,
                padding: EdgeInsets.zero,
                splashRadius: 18,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_invoiceFieldRadius),
                  side: const BorderSide(color: SilverStockColors.cardBorder),
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
                            color: SilverStockColors.textDark,
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
