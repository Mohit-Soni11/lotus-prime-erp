part of '../metal_rate_detail_screen.dart';

class _PurityName extends StatelessWidget {
  final MetalRatePurityPlan plan;
  final Color accent;
  final bool isBase;
  final bool isSilverJewellery;
  const _PurityName({
    required this.plan,
    required this.accent,
    required this.isBase,
    this.isSilverJewellery = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Row(children: [
          Container(
            constraints: const BoxConstraints(minWidth: 58),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: MetalRateDetailStyles.tint(accent),
            child: Text(
              _purityLabel(plan.label),
              maxLines: 1,
              style: MetalRateDetailStyles.value
                  .copyWith(fontSize: 15, color: accent),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              isSilverJewellery
                  ? '70% purity · Local Jewellery'
                  : isBase
                      ? 'Local base'
                      : '${_percent(plan.purityPercent)}% purity',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MetalRateDetailStyles.body
                  .copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ]),
      );
}

class _ReadRateCell extends StatelessWidget {
  final double value;
  final Color color;
  const _ReadRateCell({required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: MetalRateDetailStyles.tint(color),
        child: Text(
          _money(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: MetalRateDetailStyles.value.copyWith(fontSize: 15),
        ),
      );
}

class _EditableRateCell extends StatelessWidget {
  final double value;
  final double effectiveValue;
  final Color color;
  final bool enabled;
  final ValueChanged<double> onChanged;
  const _EditableRateCell({
    super.key,
    required this.value,
    required this.effectiveValue,
    required this.color,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 34),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: enabled ? 3 : 12),
        decoration: MetalRateDetailStyles.tint(color),
        child: Row(children: [
          Expanded(
            child: _RateField(
              value: value > 0 ? value : effectiveValue,
              accent: color,
              enabled: enabled,
              hintText: effectiveValue > 0
                  ? 'Auto ${_money(effectiveValue)}'
                  : 'Enter rate',
              onChanged: onChanged,
            ),
          ),
          if (!enabled && value <= 0 && effectiveValue > 0) ...[
            const SizedBox(width: 6),
            Text('Auto',
                style: MetalRateDetailStyles.body.copyWith(
                    color: MetalRateColors.textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ],
        ]),
      );
}

class _CompactPurityCard extends StatelessWidget {
  final MetalRateProfile profile;
  final MetalRatePurityPlan plan;
  final int index;
  final MetalRateController controller;
  final bool enabled;
  final Color accent;

  const _CompactPurityCard({
    required this.profile,
    required this.plan,
    required this.index,
    required this.controller,
    required this.enabled,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final unit = _rateUnit(profile.metal);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: MetalRateDetailStyles.tint(accent),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _PurityName(
          plan: plan,
          accent: accent,
          isBase: profile.isMarketBasePlan(plan),
          isSilverJewellery:
              profile.metal == MetalRateMetal.silver && plan.label == '700',
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _CompactRate(
            label: 'Market Parity',
            value: profile.marketParityRateFor(plan),
            color: accent,
            unit: unit,
          ),
          _CompactRate(
            key: ValueKey(
                profile.metal == MetalRateMetal.silver && plan.label == '700'
                    ? 'silver-jewellery-rate'
                    : '${profile.metal.name}-sell-$index'),
            label: 'Counter Selling',
            value: plan.manualDisplayRatePer10g,
            effectiveValue: profile.effectiveSellingRateFor(plan),
            color: MetalRateDetailStyles.greenInk,
            unit: unit,
            enabled: enabled,
            onChanged: (value) => controller.updateShopRate(
              metal: profile.metal,
              index: index,
              value: value,
            ),
          ),
        ]),
      ]),
    );
  }
}

class _CompactRate extends StatelessWidget {
  final String label;
  final double value;
  final double? effectiveValue;
  final Color color;
  final String unit;
  final bool enabled;
  final ValueChanged<double>? onChanged;
  const _CompactRate({
    super.key,
    required this.label,
    required this.value,
    this.effectiveValue,
    required this.color,
    required this.unit,
    this.enabled = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 180),
        padding: const EdgeInsets.all(9),
        decoration: MetalRateDetailStyles.tint(color),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              '$label (₹ / $unit)${!enabled && value <= 0 && (effectiveValue ?? 0) > 0 ? ' · Auto' : ''}',
              style: MetalRateDetailStyles.body.copyWith(
                  color: color, fontWeight: FontWeight.w800, fontSize: 11)),
          const SizedBox(height: 5),
          _RateField(
            value: value > 0 ? value : effectiveValue ?? value,
            accent: color,
            enabled: enabled && onChanged != null,
            hintText: (effectiveValue ?? 0) > 0
                ? 'Auto ${_money(effectiveValue!)}'
                : 'Enter rate',
            onChanged: onChanged ?? (_) {},
          ),
        ]),
      );
}
