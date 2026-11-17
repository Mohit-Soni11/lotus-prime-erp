part of '../metal_rate_detail_screen.dart';

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;
  final Widget child;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: MetalRateDetailStyles.panel(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: MetalRateDetailStyles.tint(accent),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MetalRateDetailStyles.title.copyWith(fontSize: 18),
                ),
              ),
            ]),
            const SizedBox(height: 15),
            child,
          ],
        ),
      );
}

class _RateField extends StatefulWidget {
  final double value;
  final Color accent;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final String? unit;
  final String? hintText;

  const _RateField({
    super.key,
    required this.value,
    required this.accent,
    required this.enabled,
    required this.onChanged,
    this.unit,
    this.hintText,
  });

  @override
  State<_RateField> createState() => _RateFieldState();
}

class _RateFieldState extends State<_RateField> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _inputValue(widget.value));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _RateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _inputValue(widget.value);
    if (!_focusNode.hasFocus && _textController.text != next) {
      _textController.text = next;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Row(children: [
        Flexible(
          child: Text(
            _money(widget.value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MetalRateDetailStyles.value,
          ),
        ),
        if (widget.unit != null) ...[
          const SizedBox(width: 4),
          Text('/ ${widget.unit}',
              style: MetalRateDetailStyles.body.copyWith(
                  color: MetalRateColors.textDark,
                  fontWeight: FontWeight.w800)),
        ],
      ]);
    }
    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) => widget.onChanged(_parseNumber(value)),
      style: MetalRateDetailStyles.value.copyWith(fontSize: 16),
      decoration: InputDecoration(
        prefixText: '₹ ',
        hintText: widget.hintText,
        suffixText: widget.unit == null ? null : '/ ${widget.unit}',
        prefixStyle: MetalRateDetailStyles.body.copyWith(
            color: MetalRateColors.textDark, fontWeight: FontWeight.w800),
        suffixStyle: MetalRateDetailStyles.body.copyWith(
            color: MetalRateColors.textDark, fontWeight: FontWeight.w800),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.accent, width: 1.5),
        ),
      ),
    );
  }
}

Color _metalAccent(MetalRateMetal metal) => switch (metal) {
      MetalRateMetal.gold => MetalRateDetailStyles.goldInk,
      MetalRateMetal.silver => MetalRateDetailStyles.silverInk,
      MetalRateMetal.diamond => MetalRateColors.diamond,
      MetalRateMetal.platinum => MetalRateColors.platinum,
    };

String _rateUnit(MetalRateMetal metal) =>
    MetalRatePriceUnit.forMetal(metal).label;

double _parseNumber(String value) =>
    double.tryParse(value.replaceAll(',', '').trim()) ?? 0;

String _inputValue(double value) {
  if (value <= 0) return '';
  return NumberFormat.decimalPattern('en_IN').format(value).replaceAll(',', '');
}

String _money(double value) {
  if (value <= 0) return '—';
  final formatter = NumberFormat.decimalPattern('en_IN')
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = 2;
  return '₹ ${formatter.format(value)}';
}

String _purityLabel(String label) {
  final value = label.trim().toUpperCase();
  final match = RegExp(r'^(\d+)K$').firstMatch(value);
  return match == null ? value : '${match.group(1)}K';
}

String _percent(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

String _spotReferenceLabel(MetalRateMetal metal) => switch (metal) {
      MetalRateMetal.gold => 'MCX 24K Reference',
      MetalRateMetal.silver => 'Silver Spot Reference',
      MetalRateMetal.diamond => 'Diamond Benchmark',
      MetalRateMetal.platinum => 'Platinum Spot Reference',
    };
