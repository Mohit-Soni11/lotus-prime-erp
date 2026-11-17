import 'package:flutter/material.dart';

import '../../logic/dashboard/live_rates/live_rates_logic.dart';
import '../../models/live_rates/live_rates_model.dart';
import '../../models/setting/metal_rate/metal_rate_model.dart';
import '../../theme/dashboard/live_rates/live_rates_theme.dart';
import 'live_rates/metal_rate_panel.dart';
import 'live_rates/purchase_rates_panel.dart';
import 'live_rates/rates_header.dart';

class LiveRatesCard extends StatefulWidget {
  const LiveRatesCard({super.key, this.ratesStream});

  final Stream<LiveRatesModel>? ratesStream;

  @override
  State<LiveRatesCard> createState() => _LiveRatesCardState();
}

class _LiveRatesCardState extends State<LiveRatesCard> {
  late final Stream<LiveRatesModel> _ratesStream;
  bool _showPurchaseRates = false;

  @override
  void initState() {
    super.initState();
    _ratesStream = widget.ratesStream ?? LiveRatesLogic().ratesStream;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: LiveRatesStyles.card,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RatesHeader(),
          const SizedBox(height: 10),
          StreamBuilder<LiveRatesModel>(
            stream: _ratesStream,
            initialData: LiveRatesModel.loading(),
            builder: (context, snapshot) {
              final rates = snapshot.data ?? LiveRatesModel.loading();
              if (rates.isLoading) {
                return const SizedBox(
                  height: 135,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: LiveRatesColors.gold,
                    ),
                  ),
                );
              }
              if (!rates.isAvailable) {
                return SizedBox(
                  height: 135,
                  child: Center(
                    child: Text(
                      rates.message ?? 'Metal rates are unavailable.',
                      textAlign: TextAlign.center,
                      style: LiveRatesStyles.date,
                    ),
                  ),
                );
              }
              return _RatesContent(
                rates: rates,
                showPurchaseRates: _showPurchaseRates,
                onTogglePurchaseRates: () => setState(
                  () => _showPurchaseRates = !_showPurchaseRates,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RatesContent extends StatelessWidget {
  const _RatesContent({
    required this.rates,
    required this.showPurchaseRates,
    required this.onTogglePurchaseRates,
  });

  final LiveRatesModel rates;
  final bool showPurchaseRates;
  final VoidCallback onTogglePurchaseRates;

  @override
  Widget build(BuildContext context) {
    final goldRows = [
      MetalRateRow(
        purity: '24K',
        perGram: rates.gold24kPerGram,
        perBaseUnit: rates.gold24k,
      ),
      MetalRateRow(
        purity: '22K',
        perGram: rates.gold22kPerGram,
        perBaseUnit: rates.gold22k,
      ),
      MetalRateRow(
        purity: '18K',
        perGram: rates.gold18kPerGram,
        perBaseUnit: rates.gold18k,
      ),
    ];
    final silverRows = [
      MetalRateRow(
        purity: '999',
        perGram: rates.silver999PerGram,
        perBaseUnit: rates.silverRateKg,
      ),
      MetalRateRow(
        purity: '925',
        perGram: rates.silver925PerGram,
        perBaseUnit: rates.silver925RateKg,
      ),
    ];

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final gold = MetalRatePanel(
              metal: MetalRateMetal.gold,
              rows: goldRows,
            );
            final silver = MetalRatePanel(
              metal: MetalRateMetal.silver,
              rows: silverRows,
            );
            if (constraints.maxWidth < 720) {
              return Column(
                children: [gold, const SizedBox(height: 9), silver],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: gold),
                const SizedBox(width: 9),
                Expanded(child: silver),
              ],
            );
          },
        ),
        const SizedBox(height: 3),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onTogglePurchaseRates,
            style: TextButton.styleFrom(
              foregroundColor: LiveRatesColors.silver,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 7),
            ),
            iconAlignment: IconAlignment.end,
            icon: Icon(
              showPurchaseRates
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 17,
            ),
            label: Text(
              showPurchaseRates
                  ? LiveRatesStrings.hidePurchase
                  : LiveRatesStrings.viewPurchase,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (showPurchaseRates) ...[
          const SizedBox(height: 3),
          PurchaseRatesPanel(rates: rates),
        ],
      ],
    );
  }
}
