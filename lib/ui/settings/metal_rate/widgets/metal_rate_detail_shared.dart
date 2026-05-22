part of '../metal_rate_detail_screen.dart';

class _AmountInputTile extends StatefulWidget {
  final double width;
  final String label;
  final double value;
  final Color color;
  final String helper;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _AmountInputTile({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
    required this.helper,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  State<_AmountInputTile> createState() => _AmountInputTileState();
}

class _AmountInputTileState extends State<_AmountInputTile> {
  late final TextEditingController _textCtrl;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: _inputValue(widget.value));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _AmountInputTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _inputValue(widget.value);
    if (!_focusNode.hasFocus && _textCtrl.text != next) {
      _textCtrl.text = next;
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: MetalRateStyles.softPanel(widget.color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: MetalRateStyles.smallLabel.copyWith(color: widget.color),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _textCtrl,
              focusNode: _focusNode,
              readOnly: !widget.enabled,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: widget.enabled
                  ? (raw) => widget.onChanged(_parseNumber(raw))
                  : null,
              style: GoogleFonts.manrope(
                color: widget.enabled
                    ? MetalRateColors.textDark
                    : MetalRateColors.textMuted,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
              decoration: _inputDecoration(
                color: widget.color,
                prefix: 'Rs ',
                suffix: 'per 10g',
              ),
            ),
            const SizedBox(height: 6),
            _HelperText(widget.helper),
          ],
        ),
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final Color color;
  final String helper;

  const _ValueTile({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: MetalRateStyles.softPanel(color),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: MetalRateStyles.smallLabel.copyWith(color: color)),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: MetalRateColors.textDark,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            _HelperText(helper),
          ],
        ),
      ),
    );
  }
}

class _HelperText extends StatelessWidget {
  final String text;

  const _HelperText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        color: MetalRateColors.textBody,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: MetalRateStyles.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: MetalRateStyles.softPanel(color),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: MetalRateStyles.cardTitle),
                    const SizedBox(height: 3),
                    Text(subtitle, style: MetalRateStyles.cardSubtitle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String text;
  final Color color;

  const _InfoLine({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: MetalRateStyles.softPanel(color),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(MetalRateIcons.shield, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: MetalRateColors.textBody,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: MetalRateStyles.softPanel(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: MetalRateStyles.smallLabel.copyWith(color: color)),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.manrope(
              color: MetalRateColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required Color color,
  String? prefix,
  String? suffix,
}) {
  return InputDecoration(
    prefixText: prefix,
    suffixText: suffix,
    filled: true,
    fillColor: MetalRateColors.cardBg,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: MetalRateColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: MetalRateColors.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: color, width: 1.4),
    ),
  );
}

Color _metalAccent(MetalRateMetal metal) {
  switch (metal) {
    case MetalRateMetal.gold:
      return MetalRateColors.gold;
    case MetalRateMetal.silver:
      return MetalRateColors.silver;
    case MetalRateMetal.diamond:
      return MetalRateColors.diamond;
    case MetalRateMetal.platinum:
      return MetalRateColors.platinum;
  }
}

double _parseNumber(String value) =>
    double.tryParse(value.replaceAll(',', '').trim()) ?? 0.0;

String _inputValue(double value) {
  if (value <= 0) {
    return '';
  }
  return value.round().toString();
}

String _purityLabel(String label) {
  final value = label.trim().toUpperCase();
  final match = RegExp(r'^(\d+)K$').firstMatch(value);
  if (match != null) {
    return '${match.group(1)}KT';
  }
  return value;
}

String _percent(double value) {
  final whole = value.roundToDouble() == value;
  return whole ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

String _money(double value) {
  if (value <= 0) {
    return '--';
  }
  final rounded = value.round().toString();
  return 'Rs ${rounded.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{2})+\d$)'),
    (match) => '${match[1]},',
  )}';
}

String _spotReferenceLabel(MetalRateMetal metal) {
  switch (metal) {
    case MetalRateMetal.gold:
      return 'MCX 24KT Reference';
    case MetalRateMetal.silver:
      return 'Silver Spot Reference';
    case MetalRateMetal.diamond:
      return 'Diamond Benchmark';
    case MetalRateMetal.platinum:
      return 'Platinum Spot Reference';
  }
}
