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
    return _SectionCard(
      icon: MetalRateIcons.save,
      title: 'Counter Rate Control',
      subtitle:
          'Manage the final selling and old-metal purchase rate for each purity.',
      color: accent,
      child: Column(
        children: [
          const _InfoLine(
            text:
                'These are the authoritative counter rates used by billing and purchase workflows. Enable Edit Mode from the Live Rate panel before changing values.',
            color: MetalRateColors.success,
          ),
          const SizedBox(height: 12),
          ...profile.purityPlans.asMap().entries.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        entry.key == profile.purityPlans.length - 1 ? 0 : 10,
                  ),
                  child: _PurityRateCard(
                    profile: profile,
                    plan: entry.value,
                    index: entry.key,
                    accent: accent,
                    controller: controller,
                    enabled: enabled,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _PurityRateCard extends StatelessWidget {
  final MetalRateProfile profile;
  final MetalRatePurityPlan plan;
  final int index;
  final Color accent;
  final MetalRateController controller;
  final bool enabled;

  const _PurityRateCard({
    required this.profile,
    required this.plan,
    required this.index,
    required this.accent,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final parityRate = profile.marketBaseRatePer10g * plan.purityFactor;
    final sellRate = plan.manualDisplayRatePer10g;
    final buyRate = plan.buyRatePer10g;
    final retailGap = sellRate > 0 && buyRate > 0 ? sellRate - buyRate : 0.0;
    final gapPercent = buyRate <= 0 ? 0.0 : (retailGap / buyRate) * 100;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: MetalRateColors.inputBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: MetalRateColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 42,
                alignment: Alignment.center,
                decoration: MetalRateStyles.softPanel(accent),
                child: Text(
                  _purityLabel(plan.label),
                  style: GoogleFonts.manrope(
                    color: accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_percent(plan.purityPercent)}% purity',
                      style: MetalRateStyles.cardTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Final counter rate pair used across sales and purchase entries.',
                      style: MetalRateStyles.cardSubtitle,
                    ),
                  ],
                ),
              ),
              _MetricChip(
                label: 'Parity',
                value: _money(parityRate),
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 920;
              final width = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 30) / 4;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ValueTile(
                    width: width,
                    label: 'Market Parity',
                    value: _money(parityRate),
                    color: accent,
                    helper: 'Local rate x purity',
                  ),
                  _AmountInputTile(
                    width: width,
                    label: 'Counter Selling Rate',
                    value: sellRate,
                    color: MetalRateColors.success,
                    helper: 'Used for sales billing',
                    enabled: enabled,
                    onChanged: (value) => controller.updateShopRate(
                      metal: profile.metal,
                      index: index,
                      value: value,
                    ),
                  ),
                  _AmountInputTile(
                    width: width,
                    label: 'Old Metal Purchase Rate',
                    value: buyRate,
                    color: MetalRateColors.warning,
                    helper: 'Used for exchange or buyback',
                    enabled: enabled,
                    onChanged: (value) => controller.updateBuyRate(
                      metal: profile.metal,
                      index: index,
                      value: value,
                    ),
                  ),
                  _ValueTile(
                    width: width,
                    label: 'Trading Spread',
                    value: _money(retailGap),
                    color: MetalRateColors.violet,
                    helper: gapPercent <= 0
                        ? 'Spread per 10g'
                        : '${_percent(gapPercent)}% above purchase',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
