part of '../metal_rate_detail_screen.dart';

class _CounterRateSection extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;
  final MetalRateController controller;
  final bool enabled;

  const _CounterRateSection({
    required this.profile,
    required this.accent,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final plans = profile.purityPlans.asMap().entries;
    return _DetailSection(
      icon: Icons.price_change_rounded,
      title: 'Counter Rate Control',
      accent: accent,
      child: LayoutBuilder(builder: (context, constraints) {
        if (profile.purityPlans.isEmpty) {
          return Text('No purity rates configured.',
              style: MetalRateDetailStyles.body);
        }
        final unit = _rateUnit(profile.metal);
        final table = constraints.maxWidth < 760
            ? Column(children: [
                for (final entry in plans)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CompactPurityCard(
                      profile: profile,
                      plan: entry.value,
                      index: entry.key,
                      controller: controller,
                      enabled: enabled,
                      accent: accent,
                    ),
                  ),
              ])
            : Column(children: [
                Row(children: [
                  const _TableHeader('Purity',
                      flex: 24, color: MetalRateColors.textDark),
                  _TableHeader('Market Parity (₹ / $unit)',
                      flex: 38, color: accent),
                  _TableHeader('Counter Selling Rate (₹ / $unit)',
                      flex: 38, color: MetalRateDetailStyles.greenInk),
                ]),
                for (final entry in plans)
                  _PurityTableRow(
                    profile: profile,
                    plan: entry.value,
                    index: entry.key,
                    controller: controller,
                    enabled: enabled,
                    accent: accent,
                  ),
              ]);
        return table;
      }),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  final int flex;
  final Color color;
  const _TableHeader(this.text, {required this.flex, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Container(
          height: 38,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MetalRateDetailStyles.body.copyWith(
                  color: color, fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      );
}

class _PurityTableRow extends StatelessWidget {
  final MetalRateProfile profile;
  final MetalRatePurityPlan plan;
  final int index;
  final MetalRateController controller;
  final bool enabled;
  final Color accent;

  const _PurityTableRow({
    required this.profile,
    required this.plan,
    required this.index,
    required this.controller,
    required this.enabled,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: MetalRateColors.cardBorder)),
        ),
        child: Row(children: [
          Expanded(
            flex: 24,
            child: _PurityName(
              plan: plan,
              accent: accent,
              isBase: profile.isMarketBasePlan(plan),
              isSilverJewellery:
                  profile.metal == MetalRateMetal.silver && plan.label == '700',
            ),
          ),
          Expanded(
            flex: 38,
            child: _ReadRateCell(
              value: profile.marketParityRateFor(plan),
              color: accent,
            ),
          ),
          Expanded(
            flex: 38,
            child: _EditableRateCell(
              key: ValueKey(
                  profile.metal == MetalRateMetal.silver && plan.label == '700'
                      ? 'silver-jewellery-rate'
                      : '${profile.metal.name}-sell-$index'),
              value: plan.manualDisplayRatePer10g,
              effectiveValue: profile.effectiveSellingRateFor(plan),
              color: MetalRateDetailStyles.greenInk,
              enabled: enabled,
              onChanged: (value) => controller.updateShopRate(
                metal: profile.metal,
                index: index,
                value: value,
              ),
            ),
          ),
        ]),
      );
}
