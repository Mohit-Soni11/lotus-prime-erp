part of '../metal_rate_detail_screen.dart';

class _HeaderCard extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onReset;

  const _HeaderCard({
    required this.profile,
    required this.accent,
    required this.isEditing,
    required this.isSaving,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final firstPurity = profile.purityPlans.isEmpty
        ? ''
        : _purityLabel(profile.purityPlans.first.label);
    final summary = Wrap(spacing: 10, runSpacing: 10, children: [
      _HeaderMetric(
          label: 'Local Base',
          value: _money(profile.marketBaseRatePer10g),
          color: accent),
      _HeaderMetric(
        label: '$firstPurity Sell',
        value: _money(profile.primaryShopRatePer10g),
        color: MetalRateDetailStyles.greenInk,
      ),
      _HeaderMetric(
        label: '$firstPurity Buy',
        value: _money(profile.primaryBuyRatePer10g),
        color: MetalRateDetailStyles.orangeInk,
      ),
      _HeaderMetric(
        label: '${profile.purityPlans.length} Purities',
        value: '',
        color: MetalRateDetailStyles.violetInk,
      ),
    ]);
    final actions = isEditing
        ? Wrap(spacing: 8, runSpacing: 8, children: [
            _HeaderButton(
                label: isSaving ? 'Saving…' : 'Save Rates',
                icon: Icons.save_rounded,
                color: MetalRateDetailStyles.greenInk,
                onPressed: isSaving ? null : onSave),
            _HeaderButton(
                label: 'Cancel',
                icon: Icons.close_rounded,
                color: MetalRateColors.textBody,
                onPressed: isSaving ? null : onCancel),
            _HeaderButton(
                label: 'Reset',
                icon: Icons.restart_alt_rounded,
                color: MetalRateDetailStyles.orangeInk,
                onPressed: isSaving ? null : onReset),
          ])
        : Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: MetalRateDetailStyles.tint(
                      MetalRateDetailStyles.greenInk),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.trending_up_rounded,
                        size: 18, color: MetalRateDetailStyles.greenInk),
                    const SizedBox(width: 8),
                    Text('LIVE RATES',
                        style: MetalRateDetailStyles.body.copyWith(
                            color: MetalRateDetailStyles.greenInk,
                            fontWeight: FontWeight.w900)),
                  ]),
                ),
                _HeaderButton(
                    label: 'Edit Rates',
                    icon: Icons.edit_rounded,
                    color: accent,
                    onPressed: onEdit,
                    filled: true),
              ]);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: MetalRateDetailStyles.panel(),
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 1320;
        final identity = Row(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(profile.metal.assetPath,
                width: 88,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    width: 88,
                    height: 80,
                    color: accent,
                    child: const Icon(Icons.monetization_on_rounded,
                        color: Colors.white))),
          ),
          const SizedBox(width: 17),
          Flexible(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('${profile.metal.label} Rate Master',
                    style: MetalRateDetailStyles.title),
                const SizedBox(height: 3),
                Text(
                    'Manage local reference, counter selling and old-metal purchase rates.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: MetalRateDetailStyles.body),
                const SizedBox(height: 7),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.schedule_rounded,
                      size: 15, color: MetalRateColors.textBody),
                  const SizedBox(width: 6),
                  Flexible(
                      child: Text(
                    'Last updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(profile.updatedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MetalRateDetailStyles.body,
                  )),
                ]),
              ])),
        ]);
        if (compact) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 16),
                summary,
                const SizedBox(height: 14),
                actions,
              ]);
        }
        return Row(children: [
          Expanded(flex: 4, child: identity),
          const SizedBox(width: 16),
          Container(width: 1, height: 66, color: MetalRateColors.cardBorder),
          const SizedBox(width: 20),
          Expanded(flex: 4, child: summary),
          const SizedBox(width: 16),
          Container(width: 1, height: 56, color: MetalRateColors.cardBorder),
          const SizedBox(width: 20),
          actions,
        ]);
      }),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _HeaderMetric(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 108, minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: MetalRateDetailStyles.tint(color),
        child: Column(
            mainAxisAlignment: value.isEmpty
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: MetalRateDetailStyles.body.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: value.isEmpty ? 15 : 13)),
              if (value.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(value,
                    style: MetalRateDetailStyles.value.copyWith(fontSize: 15)),
              ],
            ]),
      );
}

class _HeaderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool filled;
  const _HeaderButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onPressed,
      this.filled = false});

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        style: FilledButton.styleFrom(
          backgroundColor: filled ? color : color.withValues(alpha: 0.1),
          foregroundColor: filled ? Colors.white : color,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
}

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
  Widget build(BuildContext context) => _DetailSection(
        icon: Icons.show_chart_rounded,
        title: 'Market Reference',
        subtitle:
            'MCX is reference only. Billing uses counter selling rates. Local physical market is the primary reference.',
        accent: accent,
        child: LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 960
              ? 3
              : constraints.maxWidth >= 650
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
          final unit = _rateUnit(profile.metal);
          return Wrap(spacing: 12, runSpacing: 12, children: [
            _ReferenceTile(
              width: width,
              icon: Icons.layers_rounded,
              label: _spotReferenceLabel(profile.metal),
              badge: 'Reference Only',
              value: profile.mcxRatePer10g,
              color: MetalRateDetailStyles.violetInk,
              unit: unit,
              enabled: enabled,
              onChanged: (value) =>
                  controller.updateReferenceRate(profile.metal, value),
            ),
            _ReferenceTile(
              width: width,
              icon: Icons.storefront_rounded,
              label: 'Local Physical Market',
              badge: 'Primary Reference',
              value: profile.physicalMarketRatePer10g,
              color: accent,
              unit: unit,
              enabled: enabled,
              onChanged: (value) =>
                  controller.updatePhysicalRate(profile.metal, value),
            ),
            _ReferenceTile(
              width: width,
              icon: Icons.track_changes_rounded,
              label: 'Local Rate Base',
              badge: 'Parity Calculation Base',
              value: profile.marketBaseRatePer10g,
              color: MetalRateDetailStyles.greenInk,
              unit: unit,
              enabled: false,
              onChanged: (_) {},
            ),
          ]);
        }),
      );
}

class _ReferenceTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String badge;
  final double value;
  final Color color;
  final String unit;
  final bool enabled;
  final ValueChanged<double> onChanged;
  const _ReferenceTile(
      {required this.width,
      required this.icon,
      required this.label,
      required this.badge,
      required this.value,
      required this.color,
      required this.unit,
      required this.enabled,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: MetalRateDetailStyles.tint(color),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MetalRateDetailStyles.body
                        .copyWith(color: color, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: _RateField(
                    key: ValueKey(label),
                    value: value,
                    accent: color,
                    enabled: enabled,
                    onChanged: onChanged,
                    unit: unit)),
            if (!enabled) ...[
              const SizedBox(width: 8),
              Flexible(
                  child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(7)),
                child: Text(badge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MetalRateDetailStyles.body
                        .copyWith(color: color, fontSize: 11)),
              )),
            ],
          ]),
        ]),
      );
}
