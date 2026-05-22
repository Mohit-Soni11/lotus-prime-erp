part of '../metal_rate_detail_screen.dart';

class _RateMakingEngineSection extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;
  final MetalRateController controller;

  const _RateMakingEngineSection({
    required this.profile,
    required this.accent,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: MetalRateIcons.engine,
      title: 'Rate & Making Master',
      subtitle:
          'Use local market, supplier billing basis and business making to convert one pricing style into another.',
      color: MetalRateColors.violet,
      child: Column(
        children: [
          const _InfoLine(
            text:
                'Example: if 18KT pure value is shown as 75%, supplier basis is 79%, and business making is 12%, this view shifts the hidden premium into making while keeping your total price visible.',
            color: MetalRateColors.violet,
          ),
          const SizedBox(height: 12),
          ...profile.purityPlans.asMap().entries.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        entry.key == profile.purityPlans.length - 1 ? 0 : 10,
                  ),
                  child: _MakingRuleCard(
                    profile: profile,
                    plan: entry.value,
                    index: entry.key,
                    accent: accent,
                    controller: controller,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _MakingRuleCard extends StatelessWidget {
  final MetalRateProfile profile;
  final MetalRatePurityPlan plan;
  final int index;
  final Color accent;
  final MetalRateController controller;

  const _MakingRuleCard({
    required this.profile,
    required this.plan,
    required this.index,
    required this.accent,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final baseRate = profile.marketBaseRatePer10g;
    final displayRate = baseRate * plan.purityFactor;
    final tradeBasisPercent = plan.supplierBillingPercent > 0
        ? plan.supplierBillingPercent
        : plan.purityPercent;
    final tradeMakingPercent = plan.makingChargePercent;
    final tradeBase = baseRate * (tradeBasisPercent / 100);
    final tradeTotal = tradeBase * (1 + tradeMakingPercent / 100);
    final adjustedMakingAmount = tradeTotal - displayRate;
    final adjustedMakingPercent =
        displayRate <= 0 ? 0.0 : (adjustedMakingAmount / displayRate) * 100;
    final adjustedMakingPerGram = adjustedMakingAmount / 10;

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
                      '${_percent(plan.purityPercent)}% pure display',
                      style: MetalRateStyles.cardTitle,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Convert supplier basis and making into clean customer-facing making.',
                      style: MetalRateStyles.cardSubtitle,
                    ),
                  ],
                ),
              ),
              _MetricChip(
                label: 'Target Total',
                value: _money(tradeTotal),
                color: MetalRateColors.violet,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 980;
              final width = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 30) / 4;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ValueTile(
                    width: width,
                    label: 'Applied Sell Rate',
                    value: _money(displayRate),
                    color: accent,
                    helper: 'Local base x purity',
                  ),
                  _PercentInputTile(
                    width: width,
                    label: 'Trade Basis',
                    value: tradeBasisPercent,
                    color: MetalRateColors.warning,
                    helper: 'Supplier bills this percent',
                    onChanged: (value) => controller.updateSupplierBasis(
                      metal: profile.metal,
                      index: index,
                      supplierBillingPercent: value,
                    ),
                  ),
                  _PercentInputTile(
                    width: width,
                    label: 'Business Making',
                    value: tradeMakingPercent,
                    color: MetalRateColors.success,
                    helper: 'Your real making margin',
                    onChanged: (value) => controller.updatePurityPlan(
                      metal: profile.metal,
                      index: index,
                      makingPercent: value,
                    ),
                  ),
                  _ValueTile(
                    width: width,
                    label: 'Target Total',
                    value: _money(tradeTotal),
                    color: MetalRateColors.violet,
                    helper: 'Basis plus making',
                  ),
                  _ValueTile(
                    width: width,
                    label: 'Adjusted Making',
                    value: '${_percent(adjustedMakingPercent)}%',
                    color: MetalRateColors.teal,
                    helper: 'Shown on pure sell rate',
                  ),
                  _ValueTile(
                    width: width,
                    label: 'Making / g',
                    value: _money(adjustedMakingPerGram),
                    color: MetalRateColors.diamond,
                    helper: 'Amount per gram',
                  ),
                  _ValueTile(
                    width: width,
                    label: 'Hidden Premium',
                    value: _money(adjustedMakingAmount),
                    color: MetalRateColors.warning,
                    helper: 'Moved from rate to making',
                  ),
                  _ActionTile(
                    width: width,
                    label: 'Use Purity Rate',
                    value: _money(displayRate),
                    color: MetalRateColors.success,
                    helper: 'Apply to Rate Master',
                    onTap: () => controller.updateShopRate(
                      metal: profile.metal,
                      index: index,
                      value: displayRate,
                    ),
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
