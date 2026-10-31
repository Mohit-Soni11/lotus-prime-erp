part of 'return_reversal_workflow_tabs.dart';

class _VerificationToggle extends StatelessWidget {
  final String label;
  final bool value;
  final bool readOnly;
  final ValueChanged<bool> onChanged;

  const _VerificationToggle({
    required this.label,
    required this.value,
    required this.readOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = value ? SalesPosColors.success : SalesPosColors.danger;
    return InkWell(
      onTap: readOnly ? null : () => onChanged(!value),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SalesPosStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightCheckGrid extends StatelessWidget {
  final ReturnReversalSourceLineItem lineItem;
  final ReturnReversalLineInspectionDraft draft;
  final double shortageWeight;
  final double shortageValue;
  final double metalValue;
  final bool readOnly;
  final ValueChanged<double> onReceivedWeightChanged;

  const _WeightCheckGrid({
    required this.lineItem,
    required this.draft,
    required this.shortageWeight,
    required this.shortageValue,
    required this.metalValue,
    required this.readOnly,
    required this.onReceivedWeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final fieldWidth = compact
            ? constraints.maxWidth
            : math.max(180.0, (constraints.maxWidth - 24) / 4);
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: fieldWidth,
              child: _MetricBox(
                label: 'Sold Net Weight',
                value: '${_formatWeight(lineItem.netWeight)} g',
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _ReceivedWeightInput(
                key: ValueKey('received-weight-${lineItem.lineNo}'),
                value: draft.receivedNetWeight,
                readOnly: readOnly,
                onChanged: onReceivedWeightChanged,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _MetricBox(
                label: 'Short Weight',
                value: '${_formatWeight(shortageWeight)} g',
                danger: shortageWeight > 0,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _MetricBox(
                label: 'Metal Value',
                value: _formatCurrency(metalValue),
                highlight: true,
              ),
            ),
            if (shortageValue > 0)
              SizedBox(
                width: fieldWidth,
                child: _MetricBox(
                  label: 'Value Deduction',
                  value: _formatCurrency(shortageValue),
                  danger: true,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MakingReturnDecision extends StatelessWidget {
  final bool includeMaking;
  final double metalValue;
  final double makingValue;
  final double returnAmount;
  final bool readOnly;
  final ValueChanged<bool> onChanged;

  const _MakingReturnDecision({
    required this.includeMaking,
    required this.metalValue,
    required this.makingValue,
    required this.returnAmount,
    required this.readOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final optionWidth = compact ? constraints.maxWidth : 210.0;
        final metricWidth = compact
            ? constraints.maxWidth
            : math.max(190.0, constraints.maxWidth - (optionWidth * 2) - 16);

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: optionWidth,
              child: _ValuationChoiceTile(
                title: 'Metal Value Only',
                subtitle: _formatCurrency(metalValue),
                icon: Icons.workspace_premium_rounded,
                selected: !includeMaking,
                onTap: readOnly ? null : () => onChanged(false),
              ),
            ),
            SizedBox(
              width: optionWidth,
              child: _ValuationChoiceTile(
                title: 'Metal + Making',
                subtitle: '+ ${_formatCurrency(makingValue)}',
                icon: Icons.add_circle_rounded,
                selected: includeMaking,
                onTap: readOnly ? null : () => onChanged(true),
              ),
            ),
            SizedBox(
              width: metricWidth,
              child: _MetricBox(
                label: 'This Item Return',
                value: _formatCurrency(returnAmount),
                highlight: true,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ValuationChoiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _ValuationChoiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? SalesPosColors.success : SalesPosColors.textDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? SalesPosColors.success.withValues(alpha: 0.08)
              : SalesPosColors.bodyBg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected
                ? SalesPosColors.success.withValues(alpha: 0.38)
                : SalesPosColors.bodyBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SalesPosStyles.bodyStrong.copyWith(
                      color: color,
                      fontSize: SalesPosStyles.fontLabel,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SalesPosStyles.caption.copyWith(
                      color: selected
                          ? SalesPosColors.success
                          : SalesPosColors.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceivedWeightInput extends StatefulWidget {
  final double value;
  final bool readOnly;
  final ValueChanged<double> onChanged;

  const _ReceivedWeightInput({
    super.key,
    required this.value,
    required this.readOnly,
    required this.onChanged,
  });

  @override
  State<_ReceivedWeightInput> createState() => _ReceivedWeightInputState();
}

class _ReceivedWeightInputState extends State<_ReceivedWeightInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatWeight(widget.value));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _ReceivedWeightInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_focusNode.hasFocus || oldWidget.value == widget.value) {
      return;
    }
    final nextText = _formatWeight(widget.value);
    if (_controller.text != nextText) {
      _controller.text = nextText;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SalesPosColors.bodyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Received Net Weight',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalesPosStyles.caption.copyWith(
              color: SalesPosColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(
            height: 26,
            child: TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              readOnly: widget.readOnly,
              onChanged: (text) {
                if (widget.readOnly) {
                  return;
                }
                final parsed = double.tryParse(text.trim());
                if (parsed != null) {
                  widget.onChanged(parsed);
                }
              },
              style: SalesPosStyles.bodyStrong.copyWith(
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                suffixText: 'g',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool danger;

  const _MetricBox({
    required this.label,
    required this.value,
    this.highlight = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? SalesPosColors.danger
        : highlight
            ? SalesPosColors.brandGold
            : SalesPosColors.textDark;
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: SalesPosColors.bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: danger
              ? SalesPosColors.danger.withValues(alpha: 0.28)
              : SalesPosColors.bodyBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SalesPosStyles.caption.copyWith(
              color: SalesPosColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: SalesPosStyles.bodyStrong.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
