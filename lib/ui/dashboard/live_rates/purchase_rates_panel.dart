import 'package:flutter/material.dart';

import '../../../models/live_rates/live_rates_model.dart';
import '../../../models/setting/metal_rate/metal_rate_model.dart';
import '../../../theme/dashboard/live_rates/live_rates_theme.dart';

class PurchaseRatesPanel extends StatelessWidget {
  const PurchaseRatesPanel({super.key, required this.rates});

  final LiveRatesModel rates;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gold = _PurchaseRateTile(
          metal: MetalRateMetal.gold,
          rate: rates.oldGoldBuy,
          unit: LiveRatesStrings.perTenGrams,
        );
        final silver = _PurchaseRateTile(
          metal: MetalRateMetal.silver,
          rate: rates.oldSilverBuy,
          unit: LiveRatesStrings.perKilogram,
        );
        if (constraints.maxWidth < 500) {
          return Column(children: [gold, const SizedBox(height: 8), silver]);
        }
        return Row(children: [
          Expanded(child: gold),
          const SizedBox(width: 8),
          Expanded(child: silver),
        ]);
      },
    );
  }
}

class _PurchaseRateTile extends StatelessWidget {
  const _PurchaseRateTile({
    required this.metal,
    required this.rate,
    required this.unit,
  });

  final MetalRateMetal metal;
  final String rate;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final isGold = metal == MetalRateMetal.gold;
    final accent = isGold ? LiveRatesColors.gold : LiveRatesColors.silver;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.asset(
              metal.assetPath,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => SizedBox(
                width: 32,
                height: 32,
                child: Icon(Icons.diamond_outlined, color: accent, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isGold ? 'Gold' : 'Silver'} Old Metal Purchase',
                  style: LiveRatesStyles.purchaseLabel,
                ),
                const SizedBox(height: 2),
                Text('$unit · Metal Rate Master',
                    style: LiveRatesStyles.purchaseMeta),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            rate == '--' ? rate : '₹$rate',
            style: LiveRatesStyles.rate.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}
