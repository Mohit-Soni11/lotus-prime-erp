part of '../metal_rate_detail_screen.dart';

class _MarketReferenceSection extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;
  final MetalRateController controller;
  final bool enabled;

  const _MarketReferenceSection({
    required this.profile,
    required this.accent,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final leadingPlan =
        profile.purityPlans.isEmpty ? null : profile.purityPlans.first;
    final basePurity = leadingPlan == null
        ? profile.metal.label
        : '${_purityLabel(leadingPlan.label)} ${profile.metal.label}';
    final unit = _rateUnit(profile.metal);
    final priceUnit = MetalRatePriceUnit.forMetal(profile.metal);

    return _DetailSection(
      icon: Icons.show_chart_rounded,
      title: 'Market Reference',
      accent: accent,
      child: LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 3
            : constraints.maxWidth >= 680
                ? 2
                : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        final cardHeight = enabled ? 124.0 : 116.0;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          _MarketInputCard(
            width: width,
            height: cardHeight,
            icon: Icons.layers_rounded,
            title: _spotReferenceLabel(profile.metal),
            purity: basePurity,
            value: priceUnit.toMarket(profile.mcxRatePer10g),
            unit: unit,
            color: MetalRateDetailStyles.violetInk,
            enabled: enabled,
            onChanged: (value) => controller.updateReferenceRate(
                profile.metal, priceUnit.toStored(value)),
          ),
          _MarketInputCard(
            width: width,
            height: cardHeight,
            icon: Icons.storefront_rounded,
            title: 'Local Physical Market',
            purity: basePurity,
            value: priceUnit.toMarket(profile.physicalMarketRatePer10g),
            unit: unit,
            color: accent,
            primary: true,
            enabled: enabled,
            onChanged: (value) => controller.updatePhysicalRate(
                profile.metal, priceUnit.toStored(value)),
          ),
          _ParityPreviewCard(
            width: width,
            height: cardHeight,
            profile: profile,
            basePurity: basePurity,
            unit: unit,
          ),
        ]);
      }),
    );
  }
}

class _MarketInputCard extends StatelessWidget {
  final double width;
  final double height;
  final IconData icon;
  final String title;
  final String purity;
  final double value;
  final String unit;
  final Color color;
  final bool primary;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _MarketInputCard({
    required this.width,
    required this.height,
    required this.icon,
    required this.title,
    required this.purity,
    required this.value,
    required this.unit,
    required this.color,
    required this.enabled,
    required this.onChanged,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        key: ValueKey('market-reference-$title'),
        width: width,
        height: height,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: primary ? 0.10 : 0.055),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: color.withValues(alpha: primary ? 0.55 : 0.20),
            width: primary ? 1.5 : 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 9),
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MetalRateDetailStyles.body.copyWith(
                      color: MetalRateColors.textDark,
                      fontWeight: FontWeight.w900)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(purity.toUpperCase(),
              style: MetalRateDetailStyles.body.copyWith(
                  color: MetalRateColors.textDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _RateField(
            key: ValueKey(title),
            value: value,
            accent: color,
            enabled: enabled,
            onChanged: onChanged,
            unit: unit,
          ),
        ]),
      );
}

class _ParityPreviewCard extends StatelessWidget {
  final double width;
  final double height;
  final MetalRateProfile profile;
  final String basePurity;
  final String unit;

  const _ParityPreviewCard({
    required this.width,
    required this.height,
    required this.profile,
    required this.basePurity,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final base = MetalRatePriceUnit.forMetal(profile.metal)
        .toMarket(profile.marketBaseRatePer10g);
    const green = MetalRateDetailStyles.greenInk;
    return Container(
      key: const ValueKey('market-reference-purity'),
      width: width,
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: MetalRateDetailStyles.tint(green),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.calculate_rounded,
              size: 19, color: MetalRateDetailStyles.greenInk),
          const SizedBox(width: 9),
          Expanded(
            child: Text('Purity Calculation',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MetalRateDetailStyles.body.copyWith(
                    color: MetalRateColors.textDark,
                    fontWeight: FontWeight.w900)),
          ),
        ]),
        const SizedBox(height: 6),
        Text('FROM $basePurity LOCAL RATE'.toUpperCase(),
            style: MetalRateDetailStyles.body.copyWith(
                color: MetalRateColors.textDark,
                fontSize: 11,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('${_money(base)} / $unit',
            style: MetalRateDetailStyles.value.copyWith(fontSize: 19)),
      ]),
    );
  }
}
