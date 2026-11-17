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
  Widget build(BuildContext context) => _DetailSection(
        icon: Icons.lock_rounded,
        title: 'Counter Rate Control',
        subtitle:
            'Manage the final selling and old-metal purchase rate for each purity.',
        accent: accent,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: MetalRateDetailStyles.tint(
              enabled ? MetalRateDetailStyles.greenInk : accent),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(enabled ? Icons.edit_rounded : Icons.lock_outline_rounded,
                size: 16,
                color: enabled ? MetalRateDetailStyles.greenInk : accent),
            const SizedBox(width: 7),
            Flexible(
                child: Text(
                    enabled
                        ? 'Editing rates'
                        : 'Read only · Click Edit Rates to update',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MetalRateDetailStyles.body.copyWith(
                        color:
                            enabled ? MetalRateDetailStyles.greenInk : accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 11))),
          ]),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          if (profile.purityPlans.isEmpty) {
            return Text('No purity rates configured.',
                style: MetalRateDetailStyles.body);
          }
          if (constraints.maxWidth < 1000) {
            return Column(children: [
              for (final entry in profile.purityPlans.asMap().entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _CompactPurityCard(
                      profile: profile,
                      plan: entry.value,
                      index: entry.key,
                      controller: controller,
                      enabled: enabled,
                      accent: accent),
                ),
            ]);
          }
          final unit = _rateUnit(profile.metal);
          return Column(children: [
            Row(children: [
              const _TableHeader('Purity',
                  flex: 18, color: MetalRateColors.textDark),
              _TableHeader('Market Parity (₹ / $unit)',
                  flex: 20, color: accent),
              _TableHeader('Counter Selling Rate (₹ / $unit)',
                  flex: 20, color: MetalRateDetailStyles.greenInk),
              _TableHeader('Old Metal Purchase Rate (₹ / $unit)',
                  flex: 20, color: MetalRateDetailStyles.orangeInk),
              _TableHeader('Trading Spread (₹ / $unit)',
                  flex: 20, color: MetalRateDetailStyles.violetInk),
            ]),
            for (final entry in profile.purityPlans.asMap().entries)
              _PurityTableRow(
                profile: profile,
                plan: entry.value,
                index: entry.key,
                controller: controller,
                enabled: enabled,
                accent: accent,
              ),
          ]);
        }),
      );
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
  const _PurityTableRow(
      {required this.profile,
      required this.plan,
      required this.index,
      required this.controller,
      required this.enabled,
      required this.accent});

  @override
  Widget build(BuildContext context) {
    final parity = profile.marketBaseRatePer10g * plan.purityFactor;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: MetalRateColors.cardBorder))),
      child: Row(children: [
        Expanded(flex: 18, child: _PurityName(plan: plan, accent: accent)),
        Expanded(flex: 20, child: _ReadRateCell(value: parity, color: accent)),
        Expanded(
            flex: 20,
            child: _EditableRateCell(
              key: ValueKey('${profile.metal.name}-sell-$index'),
              value: plan.manualDisplayRatePer10g,
              color: MetalRateDetailStyles.greenInk,
              enabled: enabled,
              onChanged: (value) => controller.updateShopRate(
                  metal: profile.metal, index: index, value: value),
            )),
        Expanded(
            flex: 20,
            child: _EditableRateCell(
              key: ValueKey('${profile.metal.name}-buy-$index'),
              value: plan.buyRatePer10g,
              color: MetalRateDetailStyles.orangeInk,
              enabled: enabled,
              onChanged: (value) => controller.updateBuyRate(
                  metal: profile.metal, index: index, value: value),
            )),
        Expanded(
            flex: 20,
            child: _ReadRateCell(
                value:
                    plan.manualDisplayRatePer10g > 0 && plan.buyRatePer10g > 0
                        ? plan.manualDisplayRatePer10g - plan.buyRatePer10g
                        : 0,
                color: MetalRateDetailStyles.violetInk,
                signed: true)),
      ]),
    );
  }
}

class _PurityName extends StatelessWidget {
  final MetalRatePurityPlan plan;
  final Color accent;
  const _PurityName({required this.plan, required this.accent});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Row(children: [
          Container(
            constraints: const BoxConstraints(minWidth: 58),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: MetalRateDetailStyles.tint(accent),
            child: Text(_purityLabel(plan.label),
                maxLines: 1,
                style: MetalRateDetailStyles.value
                    .copyWith(fontSize: 15, color: accent)),
          ),
          const SizedBox(width: 10),
          Flexible(
              child: Text('${_percent(plan.purityPercent)}% purity',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MetalRateDetailStyles.body
                      .copyWith(fontWeight: FontWeight.w800))),
        ]),
      );
}

class _ReadRateCell extends StatelessWidget {
  final double value;
  final Color color;
  final bool signed;
  const _ReadRateCell(
      {required this.value, required this.color, this.signed = false});

  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: MetalRateDetailStyles.tint(color),
        child: Text(
          value == 0
              ? '—'
              : '${signed && value > 0 ? '+ ' : ''}${_money(value)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: MetalRateDetailStyles.value.copyWith(fontSize: 15),
        ),
      );
}

class _EditableRateCell extends StatelessWidget {
  final double value;
  final Color color;
  final bool enabled;
  final ValueChanged<double> onChanged;
  const _EditableRateCell(
      {super.key,
      required this.value,
      required this.color,
      required this.enabled,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 34),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: enabled ? 3 : 12),
        decoration: MetalRateDetailStyles.tint(color),
        child: _RateField(
            value: value,
            accent: color,
            enabled: enabled,
            onChanged: onChanged),
      );
}

class _CompactPurityCard extends StatelessWidget {
  final MetalRateProfile profile;
  final MetalRatePurityPlan plan;
  final int index;
  final MetalRateController controller;
  final bool enabled;
  final Color accent;
  const _CompactPurityCard(
      {required this.profile,
      required this.plan,
      required this.index,
      required this.controller,
      required this.enabled,
      required this.accent});

  @override
  Widget build(BuildContext context) {
    final parity = profile.marketBaseRatePer10g * plan.purityFactor;
    final spread = plan.manualDisplayRatePer10g > 0 && plan.buyRatePer10g > 0
        ? plan.manualDisplayRatePer10g - plan.buyRatePer10g
        : 0.0;
    final unit = _rateUnit(profile.metal);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: MetalRateDetailStyles.tint(accent),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _PurityName(plan: plan, accent: accent),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _CompactRate(
              label: 'Market Parity', value: parity, color: accent, unit: unit),
          _CompactRate(
              label: 'Counter Selling',
              value: plan.manualDisplayRatePer10g,
              color: MetalRateDetailStyles.greenInk,
              unit: unit,
              enabled: enabled,
              onChanged: (value) => controller.updateShopRate(
                  metal: profile.metal, index: index, value: value)),
          _CompactRate(
              label: 'Old Metal Purchase',
              value: plan.buyRatePer10g,
              color: MetalRateDetailStyles.orangeInk,
              unit: unit,
              enabled: enabled,
              onChanged: (value) => controller.updateBuyRate(
                  metal: profile.metal, index: index, value: value)),
          _CompactRate(
              label: 'Trading Spread',
              value: spread,
              color: MetalRateDetailStyles.violetInk,
              unit: unit),
        ]),
      ]),
    );
  }
}

class _CompactRate extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String unit;
  final bool enabled;
  final ValueChanged<double>? onChanged;
  const _CompactRate(
      {required this.label,
      required this.value,
      required this.color,
      required this.unit,
      this.enabled = false,
      this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 180),
        padding: const EdgeInsets.all(9),
        decoration: MetalRateDetailStyles.tint(color),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$label (₹ / $unit)',
              style: MetalRateDetailStyles.body.copyWith(
                  color: color, fontWeight: FontWeight.w800, fontSize: 11)),
          const SizedBox(height: 5),
          _RateField(
              value: value,
              accent: color,
              enabled: enabled && onChanged != null,
              onChanged: onChanged ?? (_) {}),
        ]),
      );
}
