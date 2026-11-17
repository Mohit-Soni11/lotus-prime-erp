import 'package:flutter/material.dart';

import '../../../models/live_rates/live_rates_model.dart';
import '../../../theme/dashboard/live_rates/live_rates_theme.dart';

class PurchaseRatesPanel extends StatelessWidget {
  const PurchaseRatesPanel({super.key, required this.rates});

  final LiveRatesModel rates;

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('Gold 24K', rates.oldGold24kBuy, '10g'),
      ('Gold 22K', rates.oldGold22kBuy, '10g'),
      ('Gold 18K', rates.oldGold18kBuy, '10g'),
      ('Silver', rates.oldSilverBuy, 'kg'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: LiveRatesColors.divider),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in entries)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${entry.$1}  ',
                      style: const TextStyle(
                        color: LiveRatesColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text:
                          entry.$2 == '--' ? '--' : '₹${entry.$2}/${entry.$3}',
                      style: const TextStyle(
                        color: LiveRatesColors.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
