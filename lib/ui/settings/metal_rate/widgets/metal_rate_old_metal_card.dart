part of '../metal_rate_detail_screen.dart';

class _OldMetalPurchaseCard extends StatelessWidget {
  final MetalRateProfile profile;
  final MetalRateController controller;
  final bool enabled;

  const _OldMetalPurchaseCard({
    required this.profile,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    const accent = MetalRateDetailStyles.orangeInk;
    final unit = _rateUnit(profile.metal);
    final priceUnit = MetalRatePriceUnit.forMetal(profile.metal);
    final rateField = _RateField(
      key: const ValueKey('old-metal-purchase-rate'),
      value: priceUnit.toMarket(profile.primaryBuyRatePer10g),
      accent: accent,
      enabled: enabled,
      unit: unit,
      onChanged: (value) => controller.updateOldMetalPurchaseRate(
          profile.metal, priceUnit.toStored(value)),
    );
    return _DetailSection(
      icon: Icons.recycling_rounded,
      title: 'Old Metal Purchase Rate',
      accent: accent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: MetalRateDetailStyles.tint(accent),
        child: LayoutBuilder(builder: (context, constraints) {
          final label = Text(
            'Customer purchase rate (₹ / $unit)',
            style: MetalRateDetailStyles.body.copyWith(
              color: MetalRateColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          );
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [label, const SizedBox(height: 9), rateField],
            );
          }
          return Row(children: [
            Expanded(child: label),
            SizedBox(width: 260, child: rateField),
          ]);
        }),
      ),
    );
  }
}
