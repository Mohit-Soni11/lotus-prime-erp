part of 'booking_item_row.dart';

extension _BookingItemRowInputs on _BookingItemRowState {
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
