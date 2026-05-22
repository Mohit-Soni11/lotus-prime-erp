part of '../metal_rate_detail_screen.dart';

class _HeaderCard extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;

  const _HeaderCard({
    required this.profile,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          MetalRateStyles.panel(borderColor: accent.withValues(alpha: 0.32)),
      child: Row(
        children: [
          Container(
            width: 78,
            height: 78,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: MetalRateColors.shellBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.32)),
            ),
            child: Image.asset(
              profile.metal.assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                MetalRateIcons.moduleIcon,
                color: accent,
                size: 34,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.metal.label} Rate Master',
                  style: GoogleFonts.manrope(
                    color: MetalRateColors.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Set the exact counter rates used in billing, old-gold purchase and daily rate history.',
                  style: MetalRateStyles.cardSubtitle,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricChip(
                      label: 'Local Base',
                      value: _money(profile.marketBaseRatePer10g),
                      color: accent,
                    ),
                    _MetricChip(
                      label: 'Primary Sell',
                      value: _money(profile.primaryShopRatePer10g),
                      color: MetalRateColors.success,
                    ),
                    _MetricChip(
                      label: 'Primary Buy',
                      value: _money(profile.primaryBuyRatePer10g),
                      color: MetalRateColors.warning,
                    ),
                    _MetricChip(
                      label: 'Rate Rows',
                      value: '${profile.purityPlans.length}',
                      color: MetalRateColors.violet,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketReferenceSection extends StatelessWidget {
  final MetalRateProfile profile;
  final Color accent;
  final MetalRateController controller;

  const _MarketReferenceSection({
    required this.profile,
    required this.accent,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: MetalRateIcons.market,
      title: 'Market Reference',
      subtitle:
          'Local physical market is the calculation base. MCX is only an optional reference.',
      color: accent,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 780;
              final width = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 20) / 3;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _AmountInputTile(
                    width: width,
                    label: _spotReferenceLabel(profile.metal),
                    value: profile.mcxRatePer10g,
                    color: MetalRateColors.violet,
                    helper: 'View only, no calculation',
                    onChanged: (value) => controller.updateReferenceRate(
                      profile.metal,
                      value,
                    ),
                  ),
                  _AmountInputTile(
                    width: width,
                    label: 'Local Physical Market',
                    value: profile.physicalMarketRatePer10g,
                    color: accent,
                    helper: 'Offline bullion or area rate',
                    onChanged: (value) => controller.updatePhysicalRate(
                      profile.metal,
                      value,
                    ),
                  ),
                  _ValueTile(
                    width: width,
                    label: 'Local Rate Base',
                    value: _money(profile.marketBaseRatePer10g),
                    color: MetalRateColors.success,
                    helper: 'Used for market parity',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          const _InfoLine(
            text:
                'Market parity follows Local Physical Market only. Billing still uses only Shop Selling Rate.',
            color: MetalRateColors.warning,
          ),
        ],
      ),
    );
  }
}

class _RateMasterTabs extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const _RateMasterTabs({
    required this.activeIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: MetalRateStyles.fieldBox,
      child: Row(
        children: [
          _TabButton(
            label: 'Rate Master',
            icon: MetalRateIcons.save,
            color: MetalRateColors.success,
            selected: activeIndex == 0,
            onTap: () => onChanged(0),
          ),
          const SizedBox(width: 5),
          _TabButton(
            label: 'Rate & Making Engine',
            icon: MetalRateIcons.engine,
            color: MetalRateColors.violet,
            selected: activeIndex == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : MetalRateColors.textMuted,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: selected ? Colors.white : MetalRateColors.textBody,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
