import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/setting/metal_rate/metal_rate_model.dart';
import '../../../../theme/settings/metal_rate/metal_rate_theme.dart';

class MetalRateHubCard extends StatefulWidget {
  const MetalRateHubCard({
    super.key,
    required this.profile,
    required this.onTap,
  });

  final MetalRateProfile profile;
  final VoidCallback onTap;

  @override
  State<MetalRateHubCard> createState() => _MetalRateHubCardState();
}

class _MetalRateHubCardState extends State<MetalRateHubCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final accent = _accentFor(profile.metal);
    final source = profile.marketSource.trim();
    final unit = profile.metal == MetalRateMetal.diamond ? '/ct' : '/10g';

    return Semantics(
      button: true,
      label: 'Open ${profile.metal.label} rate settings',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          onHover: (hovered) => setState(() => _hovered = hovered),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(18),
            decoration: MetalRateHubStyles.card(accent, hovered: _hovered),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _MetalLogo(metal: profile.metal, accent: accent),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.metal.label,
                              style: MetalRateHubStyles.metalTitle),
                          const SizedBox(height: 4),
                          Text(
                            source.isEmpty ? 'Manual rate' : source,
                            style: MetalRateHubStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: accent, size: 22),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: accent.withValues(alpha: 0.22),
                ),
                const SizedBox(height: 15),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final metrics = [
                      _RateMetric(
                        label: 'Market base',
                        amount: profile.marketBaseRatePer10g,
                        unit: unit,
                        accent: accent,
                      ),
                      _RateMetric(
                        label: 'Selling rate',
                        amount: profile.primaryShopRatePer10g,
                        unit: unit,
                        accent: accent,
                      ),
                      _RateMetric(
                        label: 'Old-metal buy',
                        amount: profile.primaryBuyRatePer10g,
                        unit: unit,
                        accent: accent,
                      ),
                    ];
                    final width = constraints.maxWidth >= 470
                        ? (constraints.maxWidth - 16) / metrics.length
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final metric in metrics)
                          SizedBox(width: width, child: metric),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetalLogo extends StatelessWidget {
  const _MetalLogo({required this.metal, required this.accent});

  final MetalRateMetal metal;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.asset(
            metal.assetPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: accent.withValues(alpha: 0.1),
              child: Icon(MetalRateIcons.moduleIcon, color: accent),
            ),
          ),
        ),
      );
}

class _RateMetric extends StatelessWidget {
  const _RateMetric({
    required this.label,
    required this.amount,
    required this.unit,
    required this.accent,
  });

  final String label;
  final double amount;
  final String unit;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern('en_IN')
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = 2;
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: MetalRateStyles.softPanel(accent),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: MetalRateHubStyles.metricLabel),
          const SizedBox(height: 4),
          Text(
            amount > 0 ? '₹${formatter.format(amount)}' : 'Not set',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MetalRateHubStyles.metricValue,
          ),
          Text(
            unit,
            style: MetalRateHubStyles.metricLabel.copyWith(
              color: MetalRateColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

Color _accentFor(MetalRateMetal metal) => switch (metal) {
      MetalRateMetal.gold => MetalRateColors.gold,
      MetalRateMetal.silver => MetalRateColors.silver,
      MetalRateMetal.diamond => MetalRateColors.diamond,
      MetalRateMetal.platinum => MetalRateColors.platinum,
    };
